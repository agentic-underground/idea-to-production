# frozen_string_literal: true

require "json"
require "fileutils"
require_relative "model"
require_relative "event"
require_relative "annotation"
require_relative "roadmap_view"
require_relative "telemetry"
require_relative "history"
require_relative "errors"

module FlowMcp
  # The ONE serialized writer of flow state (EARS-FLOW-088/089).
  #
  # Ownership model (EARS-FLOW-088): the `.i2p/roadmap/` tree OWNS item identity —
  # existence, title, status (folder), declared deps — and is re-ingested each boot.
  # The append-only event log OWNS runtime state — gate, tokens, model, draft,
  # runtime edge mutations, annotations — and survives restarts by replay.
  #
  # Startup is ingest→replay (EARS-FLOW-077): `Store.open` builds an empty Flow and
  # loads the event log into memory; the caller ingests the tree, then calls
  # `replay!` to layer runtime deltas on top. Ingest is idempotent and NOT journaled
  # (so the log never grows across restarts); replay is non-clobbering.
  class Store
    SPEND_AGENT = "carriage-agent"
    SPEND_ACTIVITY = "spend"
    DEFAULT_MODEL = "claude-sonnet-4-6"

    def self.open(dir)
      new(dir)
    end

    def initialize(dir)
      @dir = dir
      FileUtils.mkdir_p(@dir)
      @jsonl_path = File.join(@dir, "events.jsonl")
      @markdown_path = File.join(@dir, "ROADMAP.flow.md")
      @telemetry_path = File.join(@dir, "telemetry.jsonl")
      @gates_path = File.join(@dir, "gates.json")
      @doc_dir = File.join(File.dirname(File.absolute_path(@dir)), "doc")
      @annotations_dir = File.join(@dir, "annotations")
      @roadmap_tree = nil
      @flow = Flow.new
      @annotations = Hash.new { |h, k| h[k] = [] } # id(string) -> [text]
      # Load + parse the log into memory now; a malformed line aborts the open
      # (EARS-FLOW-091). Not yet applied — replay! does that, after ingest.
      @events = load_events
      @replayed = false
    end

    # A consistent view of the flow for reads (single-threaded stdio loop).
    def snapshot = @flow

    def roadmap_source = @roadmap_tree

    # The in-memory event log (EARS-FLOW-070) — no per-call disk re-read.
    def read_events = @events

    # Annotation texts for an item in log order (EARS-FLOW-019), from the in-memory
    # index — no per-call scan of the whole log.
    def annotations_for(id) = (@annotations[id.to_s] || []).dup

    # Apply the loaded event log onto the (already-ingested) flow, then render the
    # board. Call AFTER ingest (EARS-FLOW-077/078): replay layers runtime deltas on
    # top of the tree-ingested items without clobbering them.
    def replay!
      return if @replayed

      @events.each { |ev| apply_event(ev) }
      @replayed = true
      write_markdown!
      nil
    end

    # ── mutation verbs (the only write path) ────────────────────────────────────

    # Create an item NOT sourced from the tree (test/seed + non-tree callers). A
    # genuine new item is journaled so it survives restart via replay; tree items
    # are NOT journaled (they survive via the tree). Idempotent on an existing id.
    def upsert_item(id, title, model)
      return if @flow.contains?(id)

      @flow.upsert_item(Item.new(id, title, model))
      commit(Event.item_upserted(id, title))
    end

    def set_gate(id, gate)
      @flow.set_gate(id, gate)               # raises FlowError.unknown
      commit(Event.gate_set(id, gate))
      begin
        persist_gates!                       # EARS-FLOW-092 (atomic external view)
      rescue StandardError => e              # warn-and-continue: the log is authoritative
        warn "flow-mcp: warning — could not write gates.json: #{e.message}"
      end
      nil
    end

    def post_status(id, status)
      prior = @flow.get(id)&.status
      @flow.advance_status(id, status)       # raises waiting/unknown
      if @roadmap_tree
        begin
          write_status_to_tree!(id, status)  # EARS-FLOW-033 (the tree owns status)
        rescue StandardError => e
          @flow.advance_status(id, prior) if prior  # rollback (EARS-FLOW-034)
          raise e
        end
      end
      commit(Event.status_posted(id, status))
    end

    def append_spend(id, delta)
      total = @flow.append_spend(id, delta)  # raises waiting/unknown
      ancs = Telemetry.ancestors(@flow, id)
      ancs.each { |a| @flow.accrue_tokens(a, delta) }  # roll-up (EARS-FLOW-038/039)
      commit(Event.spend_appended(id, delta, total, ancs)) # ancestors stored (EARS-FLOW-103)

      rec = Telemetry.record(
        ts: now_millis, item_id: id, agent: SPEND_AGENT, activity: SPEND_ACTIVITY,
        tokens_delta: delta, tokens_total: total, ancestors: ancs
      )
      append_line!(@telemetry_path, Telemetry.to_jsonl(rec))  # EARS-FLOW-044/097 (the sink)
      total
    end

    def set_item_model(id, model)
      @flow.set_model(id, model)
      commit(Event.model_set(id, model))
    end

    def validate_connection(from, to)
      @flow.validate_connection(from, to)    # pure; raises GraphError
    end

    def mutate_connection(op, from, to)
      case op
      when "add"
        @flow.add_connection(from, to)
        commit(Event.connection_added(from, to))
      when "remove"
        @flow.remove_connection(from, to)
        commit(Event.connection_removed(from, to))
      end
    end

    def append_sysmsg(text)
      commit(Event.sys_msg(text))
    end

    def annotate(id, text)
      item = @flow.get(id) or raise FlowError.unknown(id)
      parent, target = annotation_target(id, item.title)
      FileUtils.mkdir_p(parent)
      append_raw!(target, Annotation.format(id, text))
      commit(Event.annotated(id, text))
    end

    def request_rewrite(id, comment)
      draft = @flow.bump_draft(id)
      commit(Event.rewrite_requested(id, comment, draft))
      draft
    end

    # Create a new roadmap item (EARS-FLOW-104). Assigns the next free `item-N` id,
    # writes it back to the tree (WHERE a tree owns identity), and journals
    # `item_created` (+ a `connection_added` per dependency) so it survives a restart
    # in tree mode (via re-ingest) AND in no-tree mode (via replay). WAIT-independent.
    # Returns the new id. An unknown dependency is refused (EARS-FLOW-107).
    def create_item(title, status: "do", depends_on: [])
      deps = depends_on.map { |d| d.is_a?(ItemId) ? d : ItemId.new(d) }
      deps.each { |d| raise GraphError.unknown(d) unless @flow.contains?(d) }

      num = History.next_item_number(@flow.items_in_order.map(&:id))
      id = ItemId.new("item-#{num}")
      @flow.upsert_item(Item.new(id, title, DEFAULT_MODEL))
      @flow.get(id).status = status
      write_item_to_tree!(num, title, status, deps) if @roadmap_tree
      commit(Event.item_created(id, title))
      deps.each do |d|
        @flow.add_connection(id, d)
        commit(Event.connection_added(id, d))
      end
      id.to_s
    end

    # Delete a roadmap item (EARS-FLOW-105): drop the item + every incident edge,
    # remove its tree file and prune it from dependents' deps (WHERE a tree), and
    # journal `item_deleted`. WAIT-independent. Unknown id -> FlowError.unknown.
    def delete_item(id)
      raise FlowError.unknown(id) unless @flow.contains?(id)

      @flow.remove_item(id)
      delete_from_tree!(id) if @roadmap_tree
      commit(Event.item_deleted(id))
      nil
    end

    # ── ingest (idempotent, NOT journaled) ──────────────────────────────────────

    def ingest_roadmap(md)
      apply_roadmap(History.parse_roadmap(md))
    end

    def ingest_roadmap_tree(tree_dir)
      @roadmap_tree = tree_dir
      apply_roadmap(History.load_roadmap_tree(tree_dir))
    end

    private

    # Build in-memory items/edges from the tree. The tree owns identity, so this is
    # NOT journaled (no event growth across restarts, EARS-FLOW-088) and is
    # non-clobbering: an item already present (e.g. from a prior ingest) keeps its
    # runtime fields; only title + status are refreshed from the tree.
    def apply_roadmap(roadmap)
      roadmap.items.each do |item|
        @flow.upsert_item(Item.new(item.id, item.title, item.model)) unless @flow.contains?(item.id)
        existing = @flow.get(item.id)
        existing.title = item.title
        existing.status = item.status # tree owns status; bypasses the WAIT gate
      end
      roadmap.edges.each { |edge| safe { @flow.add_connection(edge.from, edge.to) } } # refused edge -> skip
      roadmap.items.length
    end

    # Append to the log + memory, refresh the annotation index, re-render the board —
    # all through the one writer.
    def commit(event)
      append_line!(@jsonl_path, Event.to_jsonl(event))
      @events << event
      index_annotation(event)
      write_markdown!
      nil
    end

    def index_annotation(event)
      @annotations[event["id"]] << event["text"] if event["kind"] == "annotated"
    end

    # Parse the log file into events (skip blanks; a malformed/unknown-kind line
    # raises, aborting the open — EARS-FLOW-091).
    def load_events
      out = []
      return out unless File.exist?(@jsonl_path)

      File.foreach(@jsonl_path) do |line|
        s = line.strip
        next if s.empty?

        out << Event.from_jsonl(s)
      end
      out
    end

    # Apply one logged event onto the flow during replay (EARS-FLOW-090). Replay is
    # non-clobbering (item_upserted only creates if absent) and deterministic (spend
    # uses the stored ancestor set). A logged verb the domain would now refuse is
    # skipped rather than aborting replay.
    def apply_event(ev)
      case ev["kind"]
      when "item_upserted", "item_created"
        id = ItemId.new(ev["id"])
        @flow.upsert_item(Item.new(id, ev["title"], DEFAULT_MODEL)) unless @flow.contains?(id)
      when "item_deleted"
        @flow.remove_item(ItemId.new(ev["id"])) # remove-if-present (no-op if already gone)
      when "gate_set"
        safe { @flow.set_gate(ItemId.new(ev["id"]), ev["gate"]) }
      when "status_posted"
        # The tree owns status (post_status writes back, ingest re-reads), so replay
        # is a no-op in tree mode (never reverts a tree edit). With no tree there is
        # nothing to own it, so apply it to keep status durable.
        unless @roadmap_tree
          item = @flow.get(ItemId.new(ev["id"]))
          item.status = ev["status"] if item && STATUSES.include?(ev["status"])
        end
      when "spend_appended"
        id = ItemId.new(ev["id"])
        safe { @flow.append_spend(id, ev["delta"]) }
        ancs = ev["ancestors"] ? ev["ancestors"].filter_map { |a| ItemId.parse(a) }
                               : Telemetry.ancestors(@flow, id) # legacy logs
        ancs.each { |a| safe { @flow.accrue_tokens(a, ev["delta"]) } }
      when "model_set"
        safe { @flow.set_model(ItemId.new(ev["id"]), ev["model"]) }
      when "connection_added"
        safe { @flow.add_connection(ItemId.new(ev["from"]), ItemId.new(ev["to"])) }
      when "connection_removed"
        safe { @flow.remove_connection(ItemId.new(ev["from"]), ItemId.new(ev["to"])) }
      when "rewrite_requested"
        safe { @flow.bump_draft(ItemId.new(ev["id"])) }
      when "annotated"
        @annotations[ev["id"]] << ev["text"] # rebuild the in-memory index
        # sys_msg is a no-op on in-memory state (EARS-FLOW-090)
      end
    end

    def safe
      yield
    rescue FlowMcp::Error
      nil
    end

    # Write the id->gate map atomically (sorted keys) (EARS-FLOW-092). A
    # human-readable external view; the event log is the authoritative gate record.
    def persist_gates!
      map = {}
      @flow.items_in_order.sort_by { |i| i.id.to_s }.each { |i| map[i.id.to_s] = i.gate }
      tmp = "#{@gates_path}.tmp"
      File.write(tmp, JSON.generate(map))
      File.rename(tmp, @gates_path)
    end

    def annotation_target(id, title)
      plan = File.join(@doc_dir, Annotation.plan_doc_filename(title))
      if File.file?(plan)
        [@doc_dir, plan]
      else
        [@annotations_dir, File.join(@annotations_dir, "#{id}.md")]
      end
    end

    # ── tree write-back (EARS-FLOW-033/034/035/036) ─────────────────────────────

    TREE_FOLDER = { "do" => "do", "doing" => "doing", "done" => "done" }.freeze
    TREE_LABEL = { "do" => "PENDING", "doing" => "IN PROGRESS", "done" => "COMPLETE" }.freeze

    def write_status_to_tree!(id, status)
      num = id.to_s.delete_prefix("item-")
      matches = []
      History::TREE_FOLDERS.each do |folder|
        dir = File.join(@roadmap_tree, folder)
        next unless File.directory?(dir)

        Dir.children(dir).each do |name|
          next unless name.end_with?(".md")

          path = File.join(dir, name)
          contents = (File.read(path) rescue next)
          matches << [path, contents] if History.parse_front_matter(contents)["id"] == num
        end
      end
      return if matches.empty?  # no tree file -> no-op (EARS-FLOW-036)

      path, contents = matches.pop
      if matches.any?
        warn "flow-mcp: WARNING — #{matches.length + 1} files share roadmap id #{num}; " \
             "moving the last (the loader's authoritative copy) and leaving the rest. Fix the duplicate."
      end

      updated = rewrite_front_matter_field(contents, "status", TREE_LABEL.fetch(status))
      dest_dir = File.join(@roadmap_tree, TREE_FOLDER.fetch(status))
      begin
        FileUtils.mkdir_p(dest_dir)
        file_name = File.basename(path)
        dest = File.join(dest_dir, file_name)
        tmp = File.join(dest_dir, ".#{file_name}.tmp")
        File.write(tmp, updated)
        File.rename(tmp, dest)
        File.delete(path) if File.absolute_path(path) != File.absolute_path(dest) && File.exist?(path)
      rescue SystemCallError => e
        raise StoreIoError, "tree write-back failed: #{e.message}"
      end
    end

    # Replace the first `<key>:` line inside the leading front-matter fence.
    def rewrite_front_matter_field(contents, key, value)
      out = +""
      in_fm = false
      replaced = false
      contents.lines.each_with_index do |line, i|
        t = line.strip
        if i.zero? && t == "---"
          in_fm = true
          out << line
          next
        end
        if in_fm && t == "---"
          in_fm = false
          out << line
          next
        end
        if in_fm && !replaced && t.start_with?("#{key}:")
          indent = line[/\A\s*/]
          out << "#{indent}#{key}: #{value}\n"
          replaced = true
          next
        end
        out << line
      end
      out
    end

    # ── create / delete tree write-back (EARS-FLOW-104/105) ─────────────────────

    def write_item_to_tree!(num, title, status, deps)
      dep_str = deps.empty? ? "—" : deps.map { |d| "##{d.to_s.delete_prefix('item-')}" }.join(", ")
      body = "---\nid: #{num}\ntitle: #{title}\nstatus: #{TREE_LABEL.fetch(status)}\n" \
             "depends_on: \"#{dep_str}\"\n---\n"
      dir = File.join(@roadmap_tree, TREE_FOLDER.fetch(status))
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "#{num}.md"), body)
    rescue SystemCallError => e
      raise StoreIoError, "tree write failed: #{e.message}"
    end

    # Delete the item's tree file and prune it from every other item's depends_on
    # (so a re-ingest does not carry a dangling dependency).
    def delete_from_tree!(id)
      num = id.to_s.delete_prefix("item-")
      History::TREE_FOLDERS.each do |folder|
        dir = File.join(@roadmap_tree, folder)
        next unless File.directory?(dir)

        Dir.children(dir).each do |name|
          next unless name.end_with?(".md")

          path = File.join(dir, name)
          contents = (File.read(path) rescue next)
          if History.parse_front_matter(contents)["id"] == num
            File.delete(path)
          else
            prune_dep_in_file!(path, contents, num)
          end
        end
      end
    rescue SystemCallError => e
      raise StoreIoError, "tree delete failed: #{e.message}"
    end

    def prune_dep_in_file!(path, contents, removed_num)
      raw = History.parse_front_matter(contents)["depends_on"]
      return unless raw

      nums = raw.split(/[,\s]+/).filter_map { |t| t.strip.delete_prefix("#")[/\A[0-9]+\z/] }
      return unless nums.include?(removed_num)

      kept = nums.reject { |n| n == removed_num }
      dep_str = kept.empty? ? "—" : kept.map { |n| "##{n}" }.join(", ")
      File.write(path, rewrite_front_matter_field(contents, "depends_on", "\"#{dep_str}\""))
    end

    # ── IO + render helpers ─────────────────────────────────────────────────────

    def append_line!(path, line)
      File.open(path, "a") { |f| f.write(line); f.write("\n") }
    rescue SystemCallError => e
      raise StoreIoError, "append failed (#{path}): #{e.message}"
    end

    def append_raw!(path, content)
      File.open(path, "a") { |f| f.write(content) }
    rescue SystemCallError => e
      raise StoreIoError, "append failed (#{path}): #{e.message}"
    end

    # Capitalized status/gate match the Rust reference's enum Debug formatting
    # ({:?}) so ROADMAP.flow.md is byte-identical across implementations.
    MD_STATUS = { "do" => "Do", "doing" => "Doing", "done" => "Done" }.freeze
    MD_GATE = { "go" => "Go", "wait" => "Wait" }.freeze

    def write_markdown!
      out = +"# Flow board\n\n"
      [["## DO", "do"], ["## DOING", "doing"], ["## DONE", "done"]].each do |heading, status|
        out << heading << "\n"
        @flow.items_in_order.each do |item|
          next unless item.status == status

          out << "- [#{item.id}] #{item.title} (#{MD_STATUS[item.status]}/#{MD_GATE[item.gate]}, " \
                 "#{item.tokens} tok, #{item.model})\n"
        end
        out << "\n"
      end
      File.write(@markdown_path, out)
    rescue SystemCallError => e
      raise StoreIoError, "markdown write failed: #{e.message}"
    end

    def now_millis = (Time.now.to_f * 1000).to_i
  end
end

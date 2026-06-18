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
  # The ONE serialized writer of flow state (EARS-FLOW-088/089). Every mutation
  # goes through a verb method here; there is no direct-write path. The in-memory
  # Flow, the append-only JSONL event log, the rendered markdown board, the gate
  # sidecar, and the telemetry ledger are all written from here.
  class Store
    SPEND_AGENT = "carriage-agent"
    SPEND_ACTIVITY = "spend"

    attr_reader :grafana_pushes # test observability (EARS-FLOW-097)

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
      @grafana_pushes = []

      @flow = Flow.new
      replay!
      write_markdown!
    end

    # A consistent view of the flow for reads. The stdio loop is single-threaded,
    # so the live flow is already a consistent snapshot.
    def snapshot = @flow

    def roadmap_source = @roadmap_tree

    # Read + parse the full JSONL event log (EARS-FLOW-070).
    def read_events
      out = []
      return out unless File.exist?(@jsonl_path)

      File.foreach(@jsonl_path) do |line|
        s = line.strip
        next if s.empty?

        out << Event.from_jsonl(s)
      end
      out
    end

    # ── mutation verbs (the only write path) ────────────────────────────────────

    def upsert_item(id, title, model)
      @flow.upsert_item(Item.new(id, title, model))
      commit(Event.item_upserted(id, title))
    end

    def set_gate(id, gate)
      @flow.set_gate(id, gate)               # raises FlowError.unknown
      commit(Event.gate_set(id, gate))
      begin
        persist_gates!                       # EARS-FLOW-027 (atomic)
      rescue StandardError => e              # EARS-FLOW-028 (warn-and-continue)
        warn "flow-mcp: warning — could not write gates.json: #{e.message}"
      end
      nil
    end

    # Restore gate state from gates.json (EARS-FLOW-093/094). Infallible: missing
    # -> all GO; malformed -> warn + all GO; stale id -> silently skipped. MUST run
    # AFTER ingest (EARS-FLOW-078).
    def restore_gates
      return unless File.exist?(@gates_path)

      text = File.read(@gates_path)
      map =
        begin
          JSON.parse(text)
        rescue JSON::ParserError
          warn "flow-mcp: warning — gates.json is malformed; all gates default to go"
          return
        end
      return unless map.is_a?(Hash)

      map.each do |id_str, gate|
        id = ItemId.parse(id_str)
        next unless id && GATES.include?(gate)

        begin
          @flow.set_gate(id, gate)
        rescue FlowError
          # stale id -> discard (EARS-FLOW-094)
        end
      end
    end

    def post_status(id, status)
      prior = @flow.get(id)&.status
      @flow.advance_status(id, status)       # raises waiting/unknown
      if @roadmap_tree
        begin
          write_status_to_tree!(id, status)  # EARS-FLOW-033
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
      commit(Event.spend_appended(id, delta, total))

      rec = Telemetry.record(
        ts: now_millis, item_id: id, agent: SPEND_AGENT, activity: SPEND_ACTIVITY,
        tokens_delta: delta, tokens_total: total, ancestors: ancs
      )
      append_line!(@telemetry_path, Telemetry.to_jsonl(rec))  # EARS-FLOW-044
      push_to_grafana([rec])                                   # EARS-FLOW-097
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

    # ── ingest ──────────────────────────────────────────────────────────────────

    def ingest_roadmap(md)
      apply_roadmap(History.parse_roadmap(md))
    end

    def ingest_roadmap_tree(tree_dir)
      @roadmap_tree = tree_dir
      apply_roadmap(History.load_roadmap_tree(tree_dir))
    end

    private

    def apply_roadmap(roadmap)
      events = []
      roadmap.items.each do |item|
        @flow.upsert_item(Item.new(item.id, item.title, item.model))
        # status is part of identity on the board; set on the just-upserted item
        # (it is GO, so advance_status never refuses here).
        @flow.advance_status(item.id, item.status)
        events << Event.item_upserted(item.id, item.title)
      end
      roadmap.edges.each do |edge|
        begin
          @flow.add_connection(edge.from, edge.to)  # refused edge -> skip (EARS-FLOW-086)
          events << Event.connection_added(edge.from, edge.to)
        rescue GraphError
          next
        end
      end
      events.each { |ev| commit(ev) }
      roadmap.items.length
    end

    # Append the event, then re-render the markdown board, under the one writer.
    def commit(event)
      append_line!(@jsonl_path, Event.to_jsonl(event))
      write_markdown!
      nil
    end

    def replay!
      return unless File.exist?(@jsonl_path)

      File.foreach(@jsonl_path) do |line|
        s = line.strip
        next if s.empty?

        apply_event(Event.from_jsonl(s))  # malformed -> raises, aborts open (EARS-FLOW-091)
      end
    end

    # Best-effort replay of one event (EARS-FLOW-090). A logged verb the domain
    # would now refuse is simply skipped rather than aborting replay.
    def apply_event(ev)
      case ev["kind"]
      when "item_upserted"
        @flow.upsert_item(Item.new(ItemId.new(ev["id"]), ev["title"], "claude-sonnet-4-6"))
      when "gate_set"
        safe { @flow.set_gate(ItemId.new(ev["id"]), ev["gate"]) }
      when "status_posted"
        safe { @flow.advance_status(ItemId.new(ev["id"]), ev["status"]) }
      when "spend_appended"
        id = ItemId.new(ev["id"])
        safe { @flow.append_spend(id, ev["delta"]) }
        Telemetry.ancestors(@flow, id).each { |a| safe { @flow.accrue_tokens(a, ev["delta"]) } }
      when "model_set"
        safe { @flow.set_model(ItemId.new(ev["id"]), ev["model"]) }
      when "connection_added"
        safe { @flow.add_connection(ItemId.new(ev["from"]), ItemId.new(ev["to"])) }
      when "connection_removed"
        safe { @flow.remove_connection(ItemId.new(ev["from"]), ItemId.new(ev["to"])) }
      when "rewrite_requested"
        safe { @flow.bump_draft(ItemId.new(ev["id"])) }
        # annotated / sys_msg are no-ops on in-memory state (EARS-FLOW-090)
      end
    end

    def safe
      yield
    rescue FlowMcp::Error
      nil
    end

    # Write the id->gate map atomically (sorted keys) (EARS-FLOW-092).
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

      updated = rewrite_status_front_matter(contents, TREE_LABEL.fetch(status))
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

    # Replace the first `status:` line inside the leading front-matter fence.
    def rewrite_status_front_matter(contents, label)
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
        if in_fm && !replaced && t.start_with?("status:")
          indent = line[/\A\s*/]
          out << "#{indent}status: #{label}\n"
          replaced = true
          next
        end
        out << line
      end
      out
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

    # Best-effort telemetry push (EARS-FLOW-097). Absent GRAFANA_URL is a pure
    # no-op; a present endpoint resolves the payload but does not transmit (the
    # ledger is the source of truth, a spend never fails on the push). Recorded
    # for test observability.
    def push_to_grafana(records)
      base = ENV["GRAFANA_URL"]
      if base.nil? || base.empty?
        @grafana_pushes << :no_endpoint
        return :no_endpoint
      end
      _payload = Telemetry.grafana_payload(records) # built, not transmitted
      @grafana_pushes << :attempted
      :attempted
    end
  end
end

# frozen_string_literal: true

require "set"
require_relative "ids"
require_relative "model"

module FlowMcp
  # Roadmap ingest parsers (EARS-FLOW-083/084/086/087) — pure except the thin
  # directory/file reads in load_roadmap_tree / read_roadmap_file. Faithful: a
  # cyclic-but-otherwise-valid declared edge is KEPT here; cycle rejection is the
  # Flow graph validator's job downstream.
  module History
    # The faithful result of ingest: items in display order + declared edges.
    Roadmap = Struct.new(:items, :edges) do
      def get(id) = items.find { |i| i.id == id }
    end

    HISTORY_MODEL = "claude-sonnet-4-6"
    # Tree status folders in display order (folder name -> status).
    TREE_FOLDERS = %w[backlog do doing done].freeze

    module_function

    # Map a tree folder onto a board status. backlog/do -> do; doing/done direct;
    # unknown -> do.
    def status_for_folder(folder)
      case folder
      when "doing" then "doing"
      when "done"  then "done"
      else "do"
      end
    end

    # Map a `> STATUS:` legend value onto a board status (case-insensitive).
    def status_from(raw)
      case raw.upcase
      when "COMPLETE", "AWAITING MERGE" then "done"
      when "IN PROGRESS" then "doing"
      else "do"
      end
    end

    # Build the stable slug for a roadmap number, e.g. "5" -> item-5, or nil if
    # the token is not slug-safe.
    def item_id_for(num)
      ItemId.parse("item-#{num.strip.downcase}")
    end

    # The next free item number given the current item ids: max numeric suffix + 1
    # (1 when none) — so create_item assigns a stable, non-colliding `item-N`.
    def next_item_number(ids)
      max = ids.filter_map { |id| id.to_s.delete_prefix("item-")[/\A[0-9]+\z/]&.to_i }.max || 0
      max + 1
    end

    # ── legacy single-file ROADMAP.md ──────────────────────────────────────────

    def parse_roadmap(md)
      items = []
      raw_edges = []
      current = nil # index into items

      md.each_line do |raw|
        line = raw.strip

        if (rest = line.delete_prefix("## [")) != line
          num, title = split_heading(rest)
          if num && (id = item_id_for(num))
            current = upsert(items, id, title)
          else
            current = nil
          end
          next
        end

        if (rest = line.delete_prefix("> STATUS:")) != line
          items[current].status = status_from(rest.strip) if current
          next
        end

        if (rest = line.delete_prefix("> DEPENDS ON:")) != line
          if current
            from = items[current].id
            dep_ids(rest).each { |to| raw_edges << Edge.new(from, to) }
          end
          next
        end

        if (pair = parse_blocks_on(line))
          from, tos = pair
          tos.each { |to| raw_edges << Edge.new(from, to) }
        end
      end

      Roadmap.new(items, resolve_edges(items, raw_edges))
    end

    # ── .i2p/roadmap/ file-per-item tree ───────────────────────────────────────

    # Parse the leading `---`…`---` front-matter into key=>value (first fence
    # only; unquoted scalars; tolerates a leading BOM).
    def parse_front_matter(contents)
      map = {}
      lines = contents.sub(/\A\u{feff}/, "").lines
      return map unless lines.first&.strip == "---"

      lines.drop(1).each do |line|
        t = line.strip
        break if t == "---"

        k, v = line.split(":", 2)
        next unless v

        key = k.strip
        val = v.strip.gsub(/\A["']|["']\z/, "").strip
        map[key] = val unless key.empty?
      end
      map
    end

    # Parse one tree item file (its folder sets the status) into [Item, [Edge]].
    # nil when there is no usable id.
    def parse_item_file(folder, contents)
      fm = parse_front_matter(contents)
      id = fm["id"] && item_id_for(fm["id"])
      return nil unless id

      item = Item.new(id, fm.fetch("title", ""), HISTORY_MODEL)
      item.status = status_for_folder(folder)
      edges = (fm["depends_on"] ? dep_ids_from_front_matter(fm["depends_on"]) : [])
              .map { |to| Edge.new(id, to) }
      [item, edges]
    end

    # Load the tree at +tree_dir+ into a faithful Roadmap. Missing folder skipped;
    # absent tree -> empty roadmap (never an error). Last file wins on a dup id.
    def load_roadmap_tree(tree_dir)
      items = []
      raw_edges = []
      TREE_FOLDERS.each do |folder|
        dir = File.join(tree_dir, folder)
        next unless File.directory?(dir)

        Dir.children(dir).sort.each do |name|
          next unless name.end_with?(".md")

          path = File.join(dir, name)
          contents = (File.read(path) rescue next)
          parsed = parse_item_file(folder, contents)
          next unless parsed

          item, edges = parsed
          idx = items.index { |i| i.id == item.id }
          idx ? items[idx] = item : items << item
          raw_edges.concat(edges)
        end
      end
      Roadmap.new(items, resolve_edges(items, raw_edges))
    end

    def read_roadmap_file(path)
      parse_roadmap(File.read(path))
    end

    # ── helpers ────────────────────────────────────────────────────────────────

    def upsert(items, id, title)
      idx = items.index { |i| i.id == id }
      if idx
        items[idx].title = title
        idx
      else
        items << Item.new(id, title, HISTORY_MODEL)
        items.length - 1
      end
    end

    def resolve_edges(items, raw)
      known = items.map(&:id).to_set
      edges = []
      raw.each do |e|
        next if e.from == e.to || !known.include?(e.from) || !known.include?(e.to)

        edges << e unless edges.any? { |x| x.from == e.from && x.to == e.to }
      end
      edges
    end

    def split_heading(rest)
      idx = rest.index("]")
      return [nil, nil] unless idx

      num = rest[0...idx].strip
      return [nil, nil] if num.empty?

      [num, rest[(idx + 1)..].strip]
    end

    def dep_ids(rest) = extract_hash_ids(rest)

    def dep_ids_from_front_matter(raw)
      ids = []
      raw.split(/[,\s]+/).each do |tok|
        t = tok.strip.delete_prefix("#")
        next if t.empty? || !t.match?(/\A[0-9]+\z/)

        id = item_id_for(t)
        ids << id if id && !ids.include?(id)
      end
      ids
    end

    def parse_blocks_on(line)
      idx = line.index("blocks on")
      return nil unless idx

      from = first_hash_id(line[0...idx])
      return nil unless from

      tos = extract_hash_ids(line[idx..])
      return nil if tos.empty?

      [from, tos]
    end

    def extract_hash_ids(text)
      ids = []
      hash_tokens(text).each do |tok|
        id = item_id_for(tok)
        ids << id if id && !ids.include?(id)
      end
      ids
    end

    def first_hash_id(text)
      hash_tokens(text).each { |tok| id = item_id_for(tok); return id if id }
      nil
    end

    # Split on '#', taking the leading [a-z0-9] run after each '#'.
    def hash_tokens(text)
      text.split("#").drop(1).filter_map do |seg|
        m = seg.match(/\A[a-z0-9]+/i)
        m && m[0]
      end
    end
  end
end

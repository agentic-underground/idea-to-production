# frozen_string_literal: true

require_relative "helper"

# Roadmap parsers (legacy ROADMAP.md + .i2p/roadmap tree) and CLI config.
class TestHistoryConfig < Minitest::Test
  include FlowTestHelper

  # ── legacy parse_roadmap (EARS-FLOW-084/086/087) ────────────────────────────

  def test_parses_items_statuses_and_edges # @EARS-FLOW-084
    md = <<~MD
      ## [1] Flow server
      > STATUS: IN PROGRESS
      > DEPENDS ON: —

      ## [5] Roadmap history
      > STATUS: COMPLETE
      > DEPENDS ON: #1

      ## [2] Canvas
      > STATUS: PENDING
      > DEPENDS ON: #1, #5
    MD
    rm = History.parse_roadmap(md)
    assert_equal %w[item-1 item-5 item-2], rm.items.map { |i| i.id.to_s }
    assert_equal "doing", rm.get(iid("item-1")).status
    assert_equal "done", rm.get(iid("item-5")).status
    edges = rm.edges.map { |e| [e.from.to_s, e.to.to_s] }.sort
    assert_equal [%w[item-2 item-1], %w[item-2 item-5], %w[item-5 item-1]], edges
  end

  def test_status_legends_map # @EARS-FLOW-084
    assert_equal "done", History.status_from("complete")
    assert_equal "done", History.status_from("AWAITING MERGE")
    assert_equal "doing", History.status_from("In Progress")
    assert_equal "do", History.status_from("DEFERRED")
  end

  def test_blocks_on_tree_notation # @EARS-FLOW-084
    md = <<~MD
      ` ├─ #2 Canvas  → blocks on #1`
      ` └─ #4 Loop    → blocks on #2, #3`
      ## [1] A
      ## [2] B
      ## [3] C
      ## [4] D
    MD
    rm = History.parse_roadmap(md)
    edges = rm.edges.map { |e| [e.from.to_s, e.to.to_s] }.sort
    assert_equal [%w[item-2 item-1], %w[item-4 item-2], %w[item-4 item-3]], edges
  end

  def test_tolerant_parsing # @EARS-FLOW-087
    assert_empty History.parse_roadmap("").items
    # duplicate id: last title/status wins
    rm = History.parse_roadmap("## [1] First\n> STATUS: PENDING\n## [1] Second\n> STATUS: COMPLETE\n")
    assert_equal 1, rm.items.length
    assert_equal "Second", rm.get(iid("item-1")).title
    assert_equal "done", rm.get(iid("item-1")).status
    # self-edge, unknown dep, dash placeholder -> dropped
    assert_empty History.parse_roadmap("## [1] A\n> DEPENDS ON: #1, #99, —\n").edges
    # malformed heading ignored
    assert_empty History.parse_roadmap("## [1 broken\n> STATUS: COMPLETE\n").items
  end

  def test_cyclic_edges_are_kept_by_parser # @EARS-FLOW-086
    rm = History.parse_roadmap("## [1] A\n> DEPENDS ON: #2\n## [2] B\n> DEPENDS ON: #1\n")
    assert_equal 2, rm.edges.length # parser keeps cycles; the graph validator rejects later
  end

  # ── tree ingest (EARS-FLOW-083) ─────────────────────────────────────────────

  def test_front_matter_parsing # @EARS-FLOW-083
    fm = History.parse_front_matter("---\nid: 42\ntitle: \"A: colon\"\nstatus: PENDING\n---\nbody\n")
    assert_equal "42", fm["id"]
    assert_equal "A: colon", fm["title"]
    assert_empty History.parse_front_matter("# no fence\nid: 1\n")
  end

  def test_load_roadmap_tree # @EARS-FLOW-083
    with_tmpdir do |dir|
      write_item(dir, "backlog", "16.md", "---\nid: 16\ntitle: Epic\ndepends_on: \"—\"\n---\n")
      write_item(dir, "doing", "42.md", "---\nid: 42\ntitle: Tree\ndepends_on: \"#16\"\n---\n")
      write_item(dir, "done", "01.md", "---\nid: 1\ntitle: First\n---\n")
      rm = History.load_roadmap_tree(dir)
      assert_equal 3, rm.items.length
      assert_equal "do", rm.get(iid("item-16")).status
      assert_equal "doing", rm.get(iid("item-42")).status
      assert_equal "done", rm.get(iid("item-1")).status
      assert_equal [%w[item-42 item-16]], rm.edges.map { |e| [e.from.to_s, e.to.to_s] }
    end
  end

  def test_load_roadmap_tree_absent_is_empty # @EARS-FLOW-085
    rm = History.load_roadmap_tree("/no/such/tree")
    assert_empty rm.items
    assert_empty rm.edges
  end

  # ── config (EARS-FLOW-079/080/081) ──────────────────────────────────────────

  def test_config_defaults_and_flags # @EARS-FLOW-079
    assert_equal ".flow", Config.default.data_dir
    cfg = Config.from_args(%w[--data /srv/d --roadmap /repo/ROADMAP.md --mcp])
    assert_equal "/srv/d", cfg.data_dir
    assert_equal "/repo/ROADMAP.md", cfg.roadmap_path
    assert cfg.mcp
    refute Config.from_args([]).mcp
  end

  def test_config_missing_value_and_unknown_flag # @EARS-FLOW-080 @EARS-FLOW-081
    assert_raises(FlowMcp::ConfigError) { Config.from_args(%w[--roadmap]) }
    assert_raises(FlowMcp::ConfigError) { Config.from_args(%w[--data]) }
    assert_raises(FlowMcp::ConfigError) { Config.from_args(%w[--nope x]) }
    # removed web flags are unknown
    assert_raises(FlowMcp::ConfigError) { Config.from_args(%w[--port 8080]) }
  end

  private

  def write_item(root, folder, name, body)
    dir = File.join(root, folder)
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, name), body)
  end
end

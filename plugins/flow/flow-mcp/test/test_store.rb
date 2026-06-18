# frozen_string_literal: true

require_relative "helper"

# Store: persistence, replay, gate sidecar, tree write-back, telemetry, faults.
class TestStore < Minitest::Test
  include FlowTestHelper

  def data_dir(root) = File.join(root, ".flow")

  # ── persistence + replay (EARS-FLOW-088..091) ───────────────────────────────

  def test_spend_rollup_survives_restart # @EARS-FLOW-088 @EARS-FLOW-090
    with_tmpdir do |root|
      s = Store.open(data_dir(root))
      seed(s, "child"); seed(s, "parent")
      s.mutate_connection("add", iid("child"), iid("parent"))
      s.append_spend(iid("child"), 100)

      s2 = Store.open(data_dir(root))
      assert_equal 100, s2.snapshot.get(iid("child")).tokens
      assert_equal 100, s2.snapshot.get(iid("parent")).tokens
    end
  end

  def test_annotate_and_sysmsg_are_noops_on_replay # @EARS-FLOW-090
    with_tmpdir do |root|
      s = Store.open(data_dir(root))
      seed(s, "child")
      s.append_sysmsg("hi")
      s.annotate(iid("child"), "note")
      s2 = Store.open(data_dir(root))
      assert_equal "do", s2.snapshot.get(iid("child")).status
    end
  end

  def test_blank_line_skipped_malformed_aborts_open # @EARS-FLOW-091
    with_tmpdir do |root|
      s = Store.open(data_dir(root))
      seed(s, "item-a")
      log = File.join(data_dir(root), "events.jsonl")
      File.open(log, "a") { |f| f.write("\n") }
      Store.open(data_dir(root)) # blank line tolerated
      File.open(log, "a") { |f| f.write("{\"kind\":\"nope\"}\n") }
      assert_raises(FlowMcp::Error) { Store.open(data_dir(root)) }
    end
  end

  def test_markdown_board_rerendered_on_mutation # @EARS-FLOW-089
    with_tmpdir do |root|
      s = Store.open(data_dir(root))
      seed(s, "item-a", "Alpha")
      s.post_status(iid("item-a"), "doing")
      md = File.read(File.join(data_dir(root), "ROADMAP.flow.md"))
      assert_includes md, "## DOING"
      # capitalized status/gate match the Rust enum Debug bytes (fleet oracle diffs this)
      assert_includes md, "[item-a] Alpha (Doing/Go"
    end
  end

  # ── gate sidecar (EARS-FLOW-027/028/092/093/094) + restore order (078) ──────

  def test_gate_sidecar_atomic_and_sorted # @EARS-FLOW-027 @EARS-FLOW-092
    with_tmpdir do |root|
      s = Store.open(data_dir(root))
      seed(s, "item-b"); seed(s, "item-a")
      s.set_gate(iid("item-b"), "wait")
      s.set_gate(iid("item-a"), "go")
      gates_path = File.join(data_dir(root), "gates.json")
      assert JSON.parse(File.read(gates_path)) # valid JSON
      refute File.exist?("#{gates_path}.tmp")
      assert_equal %w[item-a item-b], JSON.parse(File.read(gates_path)).keys
    end
  end

  def test_sidecar_write_failure_warns_but_succeeds # @EARS-FLOW-028
    with_tmpdir do |root|
      s = Store.open(data_dir(root))
      seed(s, "item-a")
      FileUtils.mkdir_p(File.join(data_dir(root), "gates.json")) # rename target is a dir -> fails
      out = capture_stderr { s.set_gate(iid("item-a"), "wait") }
      assert_equal "wait", s.snapshot.get(iid("item-a")).gate
      assert_match(/gates\.json/, out)
    end
  end

  def test_restore_missing_malformed_and_stale # @EARS-FLOW-093 @EARS-FLOW-094
    with_tmpdir do |root|
      s = Store.open(data_dir(root))
      s.restore_gates # missing sidecar -> no-op, no raise
      File.write(File.join(data_dir(root), "gates.json"), "{not json}")
      out = capture_stderr { s.restore_gates }
      assert_match(/malformed/, out)
      # stale id discarded, known id applied
      seed(s, "item-a")
      File.write(File.join(data_dir(root), "gates.json"), JSON.generate({ "ghost" => "wait", "item-a" => "wait" }))
      s.restore_gates
      assert_equal "wait", s.snapshot.get(iid("item-a")).gate
    end
  end

  def test_restore_runs_after_ingest_clobber # @EARS-FLOW-077 @EARS-FLOW-078
    with_tmpdir do |root|
      tree = File.join(root, ".i2p", "roadmap")
      FileUtils.mkdir_p(File.join(tree, "do"))
      File.write(File.join(tree, "do", "01.md"), "---\nid: 1\ntitle: Alpha\nstatus: PENDING\n---\n")
      s = Store.open(data_dir(root))
      s.ingest_roadmap_tree(tree)            # upsert resets gate to go
      File.write(File.join(data_dir(root), "gates.json"), JSON.generate({ "item-1" => "wait" }))
      s.restore_gates                        # re-applies after ingest
      assert_equal "wait", s.snapshot.get(iid("item-1")).gate
    end
  end

  # ── tree write-back (EARS-FLOW-033/034/035) ─────────────────────────────────

  def build_tree(root, *placements)
    tree = File.join(root, ".i2p", "roadmap")
    placements.each do |folder, num, title|
      dir = File.join(tree, folder)
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "#{num}.md"), "---\nid: #{num}\ntitle: #{title}\nstatus: PENDING\n---\nbody\n")
    end
    tree
  end

  def test_status_writeback_moves_file_and_label # @EARS-FLOW-033
    with_tmpdir do |root|
      tree = build_tree(root, ["do", 1, "Alpha"])
      s = Store.open(data_dir(root))
      s.ingest_roadmap_tree(tree)
      s.post_status(iid("item-1"), "done")
      refute File.exist?(File.join(tree, "do", "1.md"))
      moved = File.read(File.join(tree, "done", "1.md"))
      assert_match(/status: COMPLETE/, moved)
    end
  end

  def test_item_without_tree_file_still_advances # @EARS-FLOW-036
    with_tmpdir do |root|
      tree = build_tree(root, ["do", 1, "Alpha"])
      s = Store.open(data_dir(root))
      s.ingest_roadmap_tree(tree)
      seed(s, "item-9", "Loose") # in the flow, no tree file
      s.post_status(iid("item-9"), "doing")
      assert_equal "doing", s.snapshot.get(iid("item-9")).status
    end
  end

  def test_annotate_prefers_plan_doc_over_ledger # @EARS-FLOW-060
    with_tmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "doc"))
      File.write(File.join(root, "doc", "ALPHA_PLAN.md"), "# plan\n")
      s = Store.open(data_dir(root))
      s.upsert_item(iid("item-a"), "Alpha", "m")
      s.annotate(iid("item-a"), "note")
      assert_match(/### Annotation on `item-a`/, File.read(File.join(root, "doc", "ALPHA_PLAN.md")))
      refute File.exist?(File.join(data_dir(root), "annotations", "item-a.md"))
    end
  end

  def test_runs_on_ruby_floor_with_stdlib_only # @EARS-FLOW-099
    assert_operator Gem::Version.new(RUBY_VERSION), :>=, Gem::Version.new("3.3.8")
    with_tmpdir do |root|
      s = Store.open(data_dir(root))
      assert_equal "hello from the flow MCP", call(s, "ping")["result"]["message"]
    end
  end

  def test_duplicate_id_moves_last_and_warns # @EARS-FLOW-035
    with_tmpdir do |root|
      tree = build_tree(root, ["do", 1, "Alpha"], ["doing", 1, "Alpha dup"])
      s = Store.open(data_dir(root))
      s.ingest_roadmap_tree(tree)
      out = capture_stderr { s.post_status(iid("item-1"), "done") }
      assert File.exist?(File.join(tree, "done", "1.md"))
      assert_match(/share roadmap id 1/, out)
    end
  end

  def test_failed_writeback_rolls_back # @EARS-FLOW-034
    with_tmpdir do |root|
      tree = build_tree(root, ["do", 1, "Alpha"])
      # Make the destination "done" a FILE so mkdir_p of the dest folder fails.
      File.write(File.join(tree, "done"), "blocker")
      s = Store.open(data_dir(root))
      s.ingest_roadmap_tree(tree)
      assert_raises(FlowMcp::StoreIoError) { s.post_status(iid("item-1"), "done") }
      assert_equal "do", s.snapshot.get(iid("item-1")).status # rolled back
    end
  end

  # ── telemetry + grafana (EARS-FLOW-044/045/097) ─────────────────────────────

  def test_spend_appends_telemetry_record # @EARS-FLOW-044 @EARS-FLOW-045
    with_tmpdir do |root|
      s = Store.open(data_dir(root))
      seed(s, "child"); seed(s, "parent")
      s.mutate_connection("add", iid("child"), iid("parent"))
      s.append_spend(iid("child"), 50)
      lines = File.read(File.join(data_dir(root), "telemetry.jsonl")).lines
      rec = JSON.parse(lines.last)
      assert_equal "carriage-agent", rec["agent"]
      assert_equal "spend", rec["activity"]
      assert_equal ["parent"], rec["ancestors"]
      assert_equal 50, rec["tokens_delta"]
    end
  end

  def test_grafana_attempted_when_endpoint_set # @EARS-FLOW-097
    with_tmpdir do |root|
      old = ENV["GRAFANA_URL"]
      ENV["GRAFANA_URL"] = "http://localhost:3100"
      s = Store.open(data_dir(root))
      seed(s, "item-a")
      s.append_spend(iid("item-a"), 10)
      assert_equal [:attempted], s.grafana_pushes
    ensure
      old ? ENV["GRAFANA_URL"] = old : ENV.delete("GRAFANA_URL")
    end
  end

  def test_ingest_single_file_via_store # @EARS-FLOW-084 @EARS-FLOW-086
    with_tmpdir do |root|
      s = Store.open(data_dir(root))
      n = s.ingest_roadmap("## [1] A\n> DEPENDS ON: #2\n## [2] B\n> DEPENDS ON: #1\n")
      assert_equal 2, n
      assert s.snapshot.get(iid("item-1"))
      assert_operator s.snapshot.edges.length, :<=, 1 # one cyclic edge skipped by the graph validator
    end
  end

  def test_grafana_no_endpoint_when_unset # @EARS-FLOW-097
    with_tmpdir do |root|
      old = ENV.delete("GRAFANA_URL")
      s = Store.open(data_dir(root))
      seed(s, "item-a")
      s.append_spend(iid("item-a"), 10)
      assert_equal [:no_endpoint], s.grafana_pushes
    ensure
      ENV["GRAFANA_URL"] = old if old
    end
  end

  # ── internal error mapping (EARS-FLOW-095/096) ──────────────────────────────

  def test_store_io_error_maps_to_minus_32603 # @EARS-FLOW-095
    stub = Object.new
    def stub.snapshot = FlowMcp::Flow.new
    def stub.roadmap_source = nil
    def stub.append_sysmsg(_text) = raise(FlowMcp::StoreIoError, "boom")
    resp = call(stub, "append_sysmsg", { "text" => "x" })
    assert_equal(-32603, resp["error"]["code"])
  end

  def test_unexpected_error_logs_backtrace_and_maps_32603 # @EARS-FLOW-096
    stub = Object.new
    def stub.snapshot = FlowMcp::Flow.new
    def stub.roadmap_source = nil
    def stub.append_sysmsg(_text) = raise("kaboom")
    out = capture_stderr do
      resp = call(stub, "append_sysmsg", { "text" => "x" })
      assert_equal(-32603, resp["error"]["code"])
    end
    assert_match(/kaboom/, out)
  end
end

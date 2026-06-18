# frozen_string_literal: true

require_relative "helper"

# Store: persistence, replay, gate sidecar, tree write-back, telemetry, faults.
class TestStore < Minitest::Test
  include FlowTestHelper

  def data_dir(root) = File.join(root, ".flow")

  # Reopen a store the way Server.run does: open (empty) -> ingest tree -> replay.
  def reopen(root, tree: nil)
    s = Store.open(data_dir(root))
    s.ingest_roadmap_tree(tree) if tree
    s.replay!
    s
  end

  # ── persistence + replay (EARS-FLOW-088..094, 102, 103) ─────────────────────

  # THE WART regression: runtime state (tokens + roll-up, model, draft) must
  # survive a restart instead of being clobbered by re-ingest.
  def test_runtime_state_survives_restart # @EARS-FLOW-090 @EARS-FLOW-094 @EARS-FLOW-103
    with_tmpdir do |root|
      s = Store.open(data_dir(root))
      seed(s, "child"); seed(s, "parent")
      s.mutate_connection("add", iid("child"), iid("parent"))
      s.append_spend(iid("child"), 100)
      s.set_item_model(iid("child"), "claude-opus-4-8")
      s.request_rewrite(iid("child"), "redo")
      # the spend event carries its ancestor set (103)
      spend = s.read_events.find { |e| e["kind"] == "spend_appended" }
      assert_equal ["parent"], spend["ancestors"]

      s2 = reopen(root)
      assert_equal 100, s2.snapshot.get(iid("child")).tokens
      assert_equal 100, s2.snapshot.get(iid("parent")).tokens  # roll-up survived
      assert_equal "claude-opus-4-8", s2.snapshot.get(iid("child")).model
      assert_equal 1, s2.snapshot.get(iid("child")).draft
    end
  end

  # Replay uses the STORED ancestor set, not a recomputation from a graph the tree
  # has since grown — so a restart reproduces the exact historical roll-up (103).
  def test_replay_uses_stored_ancestors_not_current_graph # @EARS-FLOW-103
    with_tmpdir do |root|
      tree = File.join(root, ".i2p", "roadmap")
      FileUtils.mkdir_p(File.join(tree, "do"))
      File.write(File.join(tree, "do", "1.md"), "---\nid: 1\ntitle: Child\ndepends_on: \"#2\"\n---\n")
      File.write(File.join(tree, "do", "2.md"), "---\nid: 2\ntitle: Parent\n---\n")
      s = reopen(root, tree: tree)
      s.append_spend(iid("item-1"), 100) # ancestors at spend time = [item-2]

      # The tree grows a new dependency #3 AFTER the spend.
      File.write(File.join(tree, "do", "3.md"), "---\nid: 3\ntitle: Epic\n---\n")
      File.write(File.join(tree, "do", "1.md"), "---\nid: 1\ntitle: Child\ndepends_on: \"#2, #3\"\n---\n")

      s2 = reopen(root, tree: tree)
      assert_equal 100, s2.snapshot.get(iid("item-2")).tokens
      assert_equal 0, s2.snapshot.get(iid("item-3")).tokens # NOT recomputed onto the new edge
    end
  end

  # Re-ingesting the same tree across restarts must not append events (102).
  def test_reingest_does_not_grow_the_log # @EARS-FLOW-088 @EARS-FLOW-102
    with_tmpdir do |root|
      tree = build_tree(root, ["do", 1, "Alpha"])
      s = reopen(root, tree: tree)
      s.append_spend(iid("item-1"), 5) # one genuine runtime event
      log = File.join(data_dir(root), "events.jsonl")
      before = File.readlines(log).count { |l| !l.strip.empty? }
      2.times { reopen(root, tree: tree) }
      after = File.readlines(log).count { |l| !l.strip.empty? }
      assert_equal before, after, "re-ingest must not append events"
      assert_equal 0, reopen(root, tree: tree).read_events.count { |e| e["kind"] == "item_upserted" }
    end
  end

  def test_annotations_survive_restart_sysmsg_is_noop # @EARS-FLOW-090
    with_tmpdir do |root|
      s = Store.open(data_dir(root))
      seed(s, "child")
      s.append_sysmsg("hi")
      s.annotate(iid("child"), "note")
      s2 = reopen(root)
      assert_equal "do", s2.snapshot.get(iid("child")).status
      assert_equal ["note"], s2.annotations_for(iid("child")) # index rebuilt on replay
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

  def test_gates_restore_from_log_sidecar_not_read # @EARS-FLOW-093
    with_tmpdir do |root|
      s = Store.open(data_dir(root))
      seed(s, "item-a")
      s.set_gate(iid("item-a"), "wait")
      # corrupt the sidecar: it is a write-only external view and is never read on
      # startup, so this must not affect restore (gates come from the event log).
      File.write(File.join(data_dir(root), "gates.json"), "{not json}")
      s2 = reopen(root)
      assert_equal "wait", s2.snapshot.get(iid("item-a")).gate
    end
  end

  def test_runtime_wait_survives_ingest_then_replay # @EARS-FLOW-077 @EARS-FLOW-078
    with_tmpdir do |root|
      tree = build_tree(root, ["do", 1, "Alpha"])
      s = reopen(root, tree: tree)
      s.set_gate(iid("item-1"), "wait")      # runtime gate, logged
      s2 = reopen(root, tree: tree)          # ingest (gate->go default) THEN replay (gate->wait)
      assert_equal "wait", s2.snapshot.get(iid("item-1")).gate
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

  # ── telemetry ledger is the single sink (EARS-FLOW-044/045/097) ─────────────

  def test_spend_appends_telemetry_record # @EARS-FLOW-044 @EARS-FLOW-045 @EARS-FLOW-097
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

  def test_ingest_single_file_via_store # @EARS-FLOW-084 @EARS-FLOW-086
    with_tmpdir do |root|
      s = Store.open(data_dir(root))
      n = s.ingest_roadmap("## [1] A\n> DEPENDS ON: #2\n## [2] B\n> DEPENDS ON: #1\n")
      assert_equal 2, n
      assert s.snapshot.get(iid("item-1"))
      assert_operator s.snapshot.edges.length, :<=, 1 # one cyclic edge skipped by the graph validator
    end
  end

  # ── item lifecycle: tree write-back + restart (EARS-FLOW-104/105/106) ───────

  def test_create_item_writes_tree_and_survives_restart # @EARS-FLOW-104 @EARS-FLOW-106
    with_tmpdir do |root|
      tree = build_tree(root, ["do", 1, "Alpha"])
      s = reopen(root, tree: tree)
      newid = s.create_item("Bravo", status: "doing", depends_on: [iid("item-1")])
      assert_equal "item-2", newid
      assert File.exist?(File.join(tree, "doing", "2.md"))
      assert_match(/depends_on: "#1"/, File.read(File.join(tree, "doing", "2.md")))

      s2 = reopen(root, tree: tree)
      assert_equal "doing", s2.snapshot.get(iid("item-2")).status
      assert(s2.snapshot.edges.any? { |e| e.from.to_s == "item-2" && e.to.to_s == "item-1" })
    end
  end

  def test_delete_item_removes_file_prunes_deps_survives_restart # @EARS-FLOW-105 @EARS-FLOW-106
    with_tmpdir do |root|
      tree = File.join(root, ".i2p", "roadmap")
      FileUtils.mkdir_p(File.join(tree, "do"))
      File.write(File.join(tree, "do", "1.md"), "---\nid: 1\ntitle: Alpha\n---\n")
      File.write(File.join(tree, "do", "2.md"), "---\nid: 2\ntitle: Bravo\ndepends_on: \"#1\"\n---\n")
      s = reopen(root, tree: tree)
      s.delete_item(iid("item-1"))
      refute File.exist?(File.join(tree, "do", "1.md"))
      assert_match(/depends_on: "—"/, File.read(File.join(tree, "do", "2.md"))) # pruned

      s2 = reopen(root, tree: tree)
      assert_nil s2.snapshot.get(iid("item-1"))
      assert s2.snapshot.get(iid("item-2"))
      refute(s2.snapshot.edges.any? { |e| e.to.to_s == "item-1" })
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

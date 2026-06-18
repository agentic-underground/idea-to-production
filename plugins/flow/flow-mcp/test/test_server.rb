# frozen_string_literal: true

require_relative "helper"
require "stringio"

# Server wiring (in-process so coverage sees it): the stdio serve loop, roadmap
# source resolution, and the full run() startup sequence.
class TestServer < Minitest::Test
  include FlowTestHelper

  def serve(store, lines)
    out = StringIO.new
    FlowMcp::Server.serve(store, StringIO.new(lines.map { |l| "#{l}\n" }.join), out)
    out.string.lines.map(&:strip).reject(&:empty?).map { |l| JSON.parse(l) }
  end

  def test_serve_loop_handles_requests_notifications_and_parse_errors # @EARS-FLOW-001 @EARS-FLOW-005 @EARS-FLOW-009
    store = fresh_store
    seed(store, "item-a", "Alpha")
    responses = serve(store, [
      '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05"}}',
      '{"jsonrpc":"2.0","method":"notifications/initialized"}',
      '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"ping","arguments":{}}}',
      "", # blank -> parse error
      "{bad json" # parse error
    ])
    ids = responses.map { |r| r["id"] }
    assert_includes ids, 1
    assert_includes ids, 2
    assert_equal 2, responses.count { |r| r.dig("error", "code") == -32700 }
    assert_equal 4, responses.length # 5 inputs minus the 1 notification (no response)
  end

  def test_non_object_json_line_does_not_crash_the_loop # @EARS-FLOW-001 @EARS-FLOW-009
    store = fresh_store
    responses = serve(store, [
      "5",                                                                  # valid JSON, not an object
      "[1,2,3]",                                                            # array
      '{"jsonrpc":"2.0","id":9,"method":"tools/call","params":{"name":"ping","arguments":{}}}'
    ])
    # The non-object lines produce no response; the later request still answers.
    assert_equal [9], responses.map { |r| r["id"] }
  end

  def test_ingest_source_single_file_and_tree_and_absent # @EARS-FLOW-082 @EARS-FLOW-083 @EARS-FLOW-084 @EARS-FLOW-085
    # single file
    with_tmpdir do |root|
      store = Store.open(File.join(root, ".flow"))
      file = File.join(root, "ROADMAP.md")
      File.write(file, "## [1] Alpha\n> STATUS: IN PROGRESS\n")
      capture_stderr { FlowMcp::Server.ingest_source(store, Config.new(File.join(root, ".flow"), file, false)) }
      assert_equal "doing", store.snapshot.get(iid("item-1")).status
    end
    # tree
    with_tmpdir do |root|
      store = Store.open(File.join(root, ".flow"))
      tree = File.join(root, "tree")
      FileUtils.mkdir_p(File.join(tree, "do"))
      File.write(File.join(tree, "do", "01.md"), "---\nid: 1\ntitle: Alpha\n---\n")
      capture_stderr { FlowMcp::Server.ingest_source(store, Config.new(File.join(root, ".flow"), tree, false)) }
      assert store.snapshot.get(iid("item-1"))
    end
    # explicit path that does not exist -> warn, empty
    with_tmpdir do |root|
      store = Store.open(File.join(root, ".flow"))
      out = capture_stderr { FlowMcp::Server.ingest_source(store, Config.new(File.join(root, ".flow"), "/no/such", false)) }
      assert_empty store.snapshot.items_in_order
      assert_match(/not found|starting empty/, out)
    end
    # no source at all (cwd without .i2p/roadmap) -> warn empty
    with_tmpdir do |root|
      Dir.chdir(root) do
        store = Store.open(File.join(root, ".flow"))
        out = capture_stderr { FlowMcp::Server.ingest_source(store, Config.default) }
        assert_match(/no roadmap source/, out)
      end
    end
  end

  def test_run_full_startup_sequence # @EARS-FLOW-077
    with_tmpdir do |root|
      tree = File.join(root, ".i2p", "roadmap", "do")
      FileUtils.mkdir_p(tree)
      File.write(File.join(tree, "01.md"), "---\nid: 1\ntitle: Alpha\nstatus: PENDING\n---\n")
      Dir.chdir(root) do
        out = StringIO.new
        argv = ["--data", File.join(root, ".flow"), "--mcp"]
        req = %({"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"ping","arguments":{}}}\n)
        code = nil
        capture_stderr { code = FlowMcp::Server.run(argv, input: StringIO.new(req), output: out) }
        assert_equal 0, code
        ping = JSON.parse(out.string.lines.first)
        assert_equal 1, ping["result"]["items"]
      end
    end
  end
end

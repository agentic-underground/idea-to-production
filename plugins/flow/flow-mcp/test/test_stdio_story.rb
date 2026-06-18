# frozen_string_literal: true

require_relative "helper"
require "open3"

# End-to-end story test (EARS-FLOW-001/009/012): spawn the real exe over stdio,
# speak newline-delimited JSON-RPC, and assert the wire behaviour + clean exit.
class TestStdioStory < Minitest::Test
  include FlowTestHelper

  EXE = File.expand_path("../exe/flow-mcp", __dir__)

  def run_session(lines, root)
    cmd = ["ruby", EXE, "--data", File.join(root, ".flow"), "--mcp"]
    out, _err, status = Open3.capture3(*cmd, stdin_data: lines.map { |l| "#{l}\n" }.join)
    [out.lines.map(&:strip).reject(&:empty?).map { |l| JSON.parse(l) }, status]
  end

  def test_full_stdio_roundtrip_and_clean_exit # @EARS-FLOW-001 @EARS-FLOW-009 @EARS-FLOW-012
    with_tmpdir do |root|
      responses, status = run_session([
        '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05"}}',
        '{"jsonrpc":"2.0","method":"notifications/initialized"}', # notification: no response
        '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"ping","arguments":{}}}',
        '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"render_roadmap","arguments":{}}}',
        "not json" # parse error
      ], root)

      # init(1) + ping(2) + render(3) + parse-error(null) = 4 responses; the
      # notification produced none (EARS-FLOW-005).
      assert_equal 4, responses.length
      init = responses.find { |r| r["id"] == 1 }
      assert_equal "flow-mcp", init["result"]["serverInfo"]["name"]
      ping = responses.find { |r| r["id"] == 2 }
      assert_equal "hello from the flow MCP", ping["result"]["message"]
      parse_err = responses.find { |r| r["id"].nil? }
      assert_equal(-32700, parse_err["error"]["code"])
      assert_predicate status, :success? # clean exit 0 on EOF
    end
  end

  def test_roadmap_tree_ingest_over_stdio # @EARS-FLOW-082 @EARS-FLOW-083
    with_tmpdir do |root|
      FileUtils.mkdir_p(File.join(root, ".flow"))
      Dir.chdir(root) do
        FileUtils.mkdir_p(".i2p/roadmap/do")
        File.write(".i2p/roadmap/do/01.md", "---\nid: 1\ntitle: Alpha\nstatus: PENDING\n---\n")
        out, _err, _status = Open3.capture3(
          "ruby", EXE, "--mcp",
          stdin_data: %({"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"ping","arguments":{}}}\n)
        )
        ping = JSON.parse(out.lines.map(&:strip).reject(&:empty?).first)
        assert_equal 1, ping["result"]["items"]
      end
    end
  end
end

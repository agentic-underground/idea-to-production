# frozen_string_literal: true

# Standalone stdio smoke (no minitest): boot the real exe, exchange a handshake +
# a couple of tool calls, assert sane replies and a clean exit. `rake smoke`.
require "open3"
require "json"
require "tmpdir"

exe = File.expand_path("../exe/flow-mcp", __dir__)

Dir.mktmpdir("flow-smoke-") do |root|
  requests = [
    '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05"}}',
    '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"ping","arguments":{}}}',
    '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"render_roadmap","arguments":{}}}'
  ].map { |l| "#{l}\n" }.join

  out, err, status = Open3.capture3("ruby", exe, "--data", File.join(root, ".flow"), "--mcp", stdin_data: requests)
  responses = out.lines.map(&:strip).reject(&:empty?).map { |l| JSON.parse(l) }

  fail "expected 3 responses, got #{responses.length}\nstderr:\n#{err}" unless responses.length == 3
  fail "bad serverInfo" unless responses[0].dig("result", "serverInfo", "name") == "flow-mcp"
  fail "bad ping" unless responses[1].dig("result", "message") == "hello from the flow MCP"
  fail "bad render" unless responses[2].dig("result", "rendered")&.start_with?("ROADMAP")
  fail "non-zero exit" unless status.success?

  puts "smoke OK — flow-mcp #{responses[0].dig('result', 'serverInfo', 'version')} (clean exit)"
end

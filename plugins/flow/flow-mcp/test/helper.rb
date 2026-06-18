# frozen_string_literal: true

# Shared test harness. Runs on bare Debian-13 system Ruby — minitest is a bundled
# gem, no `gem install` required (see ../spec/EARS.md EARS-FLOW-099).

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "json"

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "flow_mcp"

module FlowTestHelper
  include FlowMcp

  # A fresh store in a throwaway data dir, cleaned at process exit.
  def fresh_store
    dir = Dir.mktmpdir("flow-test-")
    @tmp_dirs ||= []
    @tmp_dirs << dir
    Store.open(File.join(dir, ".flow"))
  end

  def with_tmpdir
    dir = Dir.mktmpdir("flow-test-")
    yield dir
  ensure
    FileUtils.remove_entry(dir) if dir && File.exist?(dir)
  end

  def iid(s) = ItemId.new(s)

  # In-process MCP call: returns the response hash.
  def call(store, name, args = {}, id: 1)
    Mcp.dispatch(store, { "id" => id, "method" => "tools/call",
                          "params" => { "name" => name, "arguments" => args } })
  end

  def result(resp) = resp.fetch("result")
  def error(resp) = resp.fetch("error")

  def assert_domain_error(resp, code, data_error)
    assert_equal code, error(resp)["code"]
    assert_equal data_error, error(resp).dig("data", "error")
  end

  def seed(store, id, title = nil)
    store.upsert_item(iid(id), title || id.capitalize, "claude-sonnet-4-6")
  end

  # Capture everything written to $stderr while the block runs.
  def capture_stderr
    orig = $stderr
    io = StringIO.new
    $stderr = io
    yield
    io.string
  ensure
    $stderr = orig
  end
end

require "stringio"

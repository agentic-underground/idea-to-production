# frozen_string_literal: true

require_relative "helper"

# The MCP JSON-RPC surface: handshake, tools/list, every verb, and error mapping.
class TestMcp < Minitest::Test
  include FlowTestHelper

  def setup
    @store = fresh_store
  end

  def dispatch(req) = Mcp.dispatch(@store, req)

  # ── handshake / protocol (EARS-FLOW-002..013) ───────────────────────────────

  def test_initialize_echoes_supported_and_negotiates_unsupported # @EARS-FLOW-002 @EARS-FLOW-003 @EARS-FLOW-004
    r = dispatch({ "id" => 1, "method" => "initialize", "params" => { "protocolVersion" => "2024-11-05" } })
    assert_equal "2024-11-05", r["result"]["protocolVersion"]
    assert_equal({}, r["result"]["capabilities"]["tools"])
    assert_equal "flow-mcp", r["result"]["serverInfo"]["name"]
    refute_empty r["result"]["serverInfo"]["version"]
    r2 = dispatch({ "id" => 1, "method" => "initialize", "params" => { "protocolVersion" => "2099-01-01" } })
    assert_equal "2024-11-05", r2["result"]["protocolVersion"]
  end

  def test_notifications_get_no_response # @EARS-FLOW-005
    assert_nil dispatch({ "method" => "notifications/initialized" })
    assert_nil dispatch({ "method" => "initialized" })
  end

  def test_tools_list_has_14_dispatchable_with_schemas # @EARS-FLOW-006 @EARS-FLOW-007 @EARS-FLOW-008
    r = dispatch({ "id" => 1, "method" => "tools/list" })
    tools = r["result"]["tools"]
    assert_equal 14, tools.length
    tools.each do |t|
      assert t["name"] && t["description"] && t["inputSchema"].is_a?(Hash)
    end
    ps = tools.find { |t| t["name"] == "post_status" }["inputSchema"]
    assert_equal %w[id status], ps["required"]
    assert_equal %w[do doing done], ps["properties"]["status"]["enum"]
    assert_equal %w[wait go], tools.find { |t| t["name"] == "set_wait_go" }["inputSchema"]["properties"]["gate"]["enum"]
    assert_equal %w[add remove], tools.find { |t| t["name"] == "mutate_connection" }["inputSchema"]["properties"]["op"]["enum"]
    # every advertised name dispatchable (not -32602 unknown tool)
    tools.each do |t|
      resp = call(@store, t["name"], {})
      next unless resp["error"]

      refute_equal "unknown tool: #{t['name']}", resp["error"]["message"]
    end
  end

  def test_unknown_method_and_unknown_tool # @EARS-FLOW-010 @EARS-FLOW-011
    assert_equal(-32601, dispatch({ "id" => 1, "method" => "frobnicate" })["error"]["code"])
    r = call(@store, "teleport", {})
    assert_equal(-32602, r["error"]["code"])
    assert_includes r["error"]["message"], "teleport"
  end

  def test_id_preserved # @EARS-FLOW-013
    assert_equal 77, call(@store, "ping", {}, id: 77)["id"]
  end

  # ── read verbs (EARS-FLOW-017..022) ─────────────────────────────────────────

  def test_list_items_grouping # @EARS-FLOW-017 @EARS-FLOW-018
    seed(@store, "item-a", "Alpha"); seed(@store, "item-b", "Bravo"); seed(@store, "item-c", "Charlie")
    @store.set_gate(iid("item-a"), "wait")
    @store.post_status(iid("item-b"), "doing")
    @store.post_status(iid("item-c"), "done")
    g = result(call(@store, "list_items"))
    assert_equal ["item-a"], g["pending"]["wait"].map { |i| i["id"] }
    assert_empty g["pending"]["go"]
    assert_equal ["item-b"], g["in_progress"].map { |i| i["id"] }
    assert_equal ["item-c"], g["done"].map { |i| i["id"] }
  end

  def test_get_item_shape_and_unknown # @EARS-FLOW-019 @EARS-FLOW-020 @EARS-FLOW-021
    seed(@store, "item-a", "Alpha"); seed(@store, "item-b", "Bravo")
    @store.mutate_connection("add", iid("item-a"), iid("item-b"))
    @store.annotate(iid("item-a"), "looks good")
    item = result(call(@store, "get_item", { "id" => "item-a" }))["item"]
    assert_equal %w[id title status gate tokens model draft deps annotations commits pr].sort, item.keys.sort
    assert_equal ["item-b"], item["deps"]
    assert_equal ["looks good"], item["annotations"]
    assert_equal [], item["commits"]
    assert_nil item["pr"]
    assert_equal(-32004, call(@store, "get_item", { "id" => "item-z" })["error"]["code"])
  end

  def test_reads_do_not_mutate # @EARS-FLOW-022
    seed(@store, "item-a")
    before = @store.read_events.length
    call(@store, "list_items")
    call(@store, "get_item", { "id" => "item-a" })
    assert_equal before, @store.read_events.length
  end

  # ── gate (EARS-FLOW-023..026) ───────────────────────────────────────────────

  def test_set_wait_go_and_unknown # @EARS-FLOW-023 @EARS-FLOW-024 @EARS-FLOW-025 @EARS-FLOW-026
    seed(@store, "item-a")
    assert_equal({ "ok" => true }, result(call(@store, "set_wait_go", { "id" => "item-a", "gate" => "wait" })))
    assert_equal "wait", @store.snapshot.get(iid("item-a")).gate
    assert(@store.read_events.any? { |e| e["kind"] == "gate_set" })
    # toggle back allowed
    call(@store, "set_wait_go", { "id" => "item-a", "gate" => "go" })
    assert_equal "go", @store.snapshot.get(iid("item-a")).gate
    assert_domain_error(call(@store, "set_wait_go", { "id" => "item-z", "gate" => "wait" }), -32000, "unknown")
  end

  # ── status (EARS-FLOW-029..031) ─────────────────────────────────────────────

  def test_post_status_happy_wait_unknown # @EARS-FLOW-029 @EARS-FLOW-030 @EARS-FLOW-031 @EARS-FLOW-032
    seed(@store, "item-a")
    assert_equal({ "ok" => true }, result(call(@store, "post_status", { "id" => "item-a", "status" => "doing" })))
    assert_equal "doing", @store.snapshot.get(iid("item-a")).status
    assert(@store.read_events.any? { |e| e["kind"] == "status_posted" })
    @store.set_gate(iid("item-a"), "wait")
    assert_domain_error(call(@store, "post_status", { "id" => "item-a", "status" => "done" }), -32000, "waiting")
    assert_domain_error(call(@store, "post_status", { "id" => "item-z", "status" => "done" }), -32000, "unknown")
  end

  # ── spend (EARS-FLOW-037..045) ──────────────────────────────────────────────

  def test_spend_rolls_up_and_guards # @EARS-FLOW-037 @EARS-FLOW-038 @EARS-FLOW-039 @EARS-FLOW-040 @EARS-FLOW-042
    seed(@store, "child"); seed(@store, "parent"); seed(@store, "epic")
    @store.mutate_connection("add", iid("child"), iid("parent"))
    @store.mutate_connection("add", iid("parent"), iid("epic"))
    @store.set_gate(iid("epic"), "wait")
    assert_equal 100, result(call(@store, "append_spend", { "id" => "child", "delta" => 100 }))["total"]
    assert_equal 100, @store.snapshot.get(iid("parent")).tokens
    assert_equal 100, @store.snapshot.get(iid("epic")).tokens # roll-up onto WAIT ancestor
    @store.set_gate(iid("child"), "wait")
    assert_domain_error(call(@store, "append_spend", { "id" => "child", "delta" => 1 }), -32000, "waiting")
    assert_equal(-32602, call(@store, "append_spend", { "id" => "child" })["error"]["code"])
    assert_equal(-32602, call(@store, "append_spend", { "id" => "child", "delta" => -5 })["error"]["code"])
  end

  # ── model (EARS-FLOW-046..048) ──────────────────────────────────────────────

  def test_set_item_model # @EARS-FLOW-046 @EARS-FLOW-047 @EARS-FLOW-048 @EARS-FLOW-049
    seed(@store, "item-a")
    call(@store, "set_item_model", { "id" => "item-a", "model" => "claude-opus-4-8" })
    assert_equal "claude-opus-4-8", @store.snapshot.get(iid("item-a")).model
    assert(@store.read_events.any? { |e| e["kind"] == "model_set" })
    assert_domain_error(call(@store, "set_item_model", { "id" => "item-z", "model" => "x" }), -32000, "unknown")
    assert_equal(-32602, call(@store, "set_item_model", { "id" => "item-a" })["error"]["code"])
  end

  # ── connections (EARS-FLOW-050..058) ────────────────────────────────────────

  def test_validate_and_mutate_connection # @EARS-FLOW-050 @EARS-FLOW-051 @EARS-FLOW-052 @EARS-FLOW-053 @EARS-FLOW-054 @EARS-FLOW-055 @EARS-FLOW-056 @EARS-FLOW-057 @EARS-FLOW-058
    seed(@store, "item-a"); seed(@store, "item-b")
    assert_equal({ "ok" => true }, result(call(@store, "validate_connection", { "from" => "item-a", "to" => "item-b" })))
    assert_domain_error(call(@store, "validate_connection", { "from" => "item-a", "to" => "item-z" }), -32000, "unknown")
    assert_domain_error(call(@store, "validate_connection", { "from" => "item-a", "to" => "item-a" }), -32000, "cycle")
    call(@store, "mutate_connection", { "op" => "add", "from" => "item-a", "to" => "item-b" })
    call(@store, "mutate_connection", { "op" => "add", "from" => "item-a", "to" => "item-b" }) # idempotent (054)
    assert_equal 1, @store.snapshot.edges.length
    assert(@store.read_events.any? { |e| e["kind"] == "connection_added" })
    assert_domain_error(call(@store, "mutate_connection", { "op" => "add", "from" => "item-b", "to" => "item-a" }), -32000, "cycle")
    assert_equal 1, @store.snapshot.edges.length # refused add leaves edge set unchanged (058)
    call(@store, "mutate_connection", { "op" => "remove", "from" => "item-a", "to" => "item-b" })
    assert(@store.read_events.any? { |e| e["kind"] == "connection_removed" })
    assert_domain_error(call(@store, "mutate_connection", { "op" => "remove", "from" => "item-a", "to" => "item-b" }), -32000, "broken_dep")
    assert_equal(-32602, call(@store, "mutate_connection", { "op" => "toggle", "from" => "item-a", "to" => "item-b" })["error"]["code"])
  end

  # ── comment loop (EARS-FLOW-059..067) ───────────────────────────────────────

  def test_annotate_and_rewrite # @EARS-FLOW-059 @EARS-FLOW-062 @EARS-FLOW-063 @EARS-FLOW-064 @EARS-FLOW-065 @EARS-FLOW-066 @EARS-FLOW-067
    seed(@store, "item-a", "Alpha")
    call(@store, "annotate", { "id" => "item-a", "text" => "ship it" })
    assert(@store.read_events.any? { |e| e["kind"] == "annotated" })
    assert_domain_error(call(@store, "annotate", { "id" => "item-z", "text" => "x" }), -32000, "unknown")
    assert_equal 1, result(call(@store, "request_rewrite", { "id" => "item-a", "comment" => "redo" }))["draft"]
    # request_rewrite only records the request (the re-draft is external) — the
    # event log carries the comment + draft number (067).
    rr = @store.read_events.find { |e| e["kind"] == "rewrite_requested" }
    assert_equal "redo", rr["comment"]
    @store.set_gate(iid("item-a"), "wait")
    assert_equal 2, result(call(@store, "request_rewrite", { "id" => "item-a", "comment" => "again" }))["draft"]
    assert_domain_error(call(@store, "request_rewrite", { "id" => "item-z", "comment" => "x" }), -32000, "unknown")
  end

  # ── events + render + ping (EARS-FLOW-068..076) ─────────────────────────────

  def test_sysmsg_and_list_events_filter # @EARS-FLOW-068 @EARS-FLOW-069 @EARS-FLOW-070 @EARS-FLOW-071 @EARS-FLOW-072
    seed(@store, "item-a")
    call(@store, "append_sysmsg", { "text" => "one" })
    call(@store, "set_wait_go", { "id" => "item-a", "gate" => "wait" })
    assert_equal(-32602, call(@store, "append_sysmsg", {})["error"]["code"])
    all = result(call(@store, "list_events"))["events"]
    assert(all.any? { |e| e["kind"] == "sys_msg" } && all.any? { |e| e["kind"] == "gate_set" })
    only = result(call(@store, "list_events", { "kind" => "sys_msg" }))["events"]
    assert_equal ["sys_msg"], only.map { |e| e["kind"] }.uniq
    # non-string kind ignored -> full log
    assert_equal all.length, result(call(@store, "list_events", { "kind" => 5 }))["events"].length
  end

  def test_render_empty_diagnostic_and_ping # @EARS-FLOW-074 @EARS-FLOW-075 @EARS-FLOW-076 @EARS-FLOW-098
    rendered = result(call(@store, "render_roadmap"))["rendered"]
    assert_includes rendered, "0 item(s)"
    assert_includes rendered, "ping"
    # byte-stable across calls (075)
    assert_equal rendered, result(call(@store, "render_roadmap"))["rendered"]
    p = result(call(@store, "ping"))
    assert_equal 0, p["items"]
    assert_nil p["source"]
    refute_empty p["version"]
    assert_equal FlowMcp::VERSION, p["version"] # version identifies the build (098)
  end
end

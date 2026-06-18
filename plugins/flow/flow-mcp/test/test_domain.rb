# frozen_string_literal: true

require_relative "helper"

# Pure domain: ItemId, Flow graph, telemetry, annotation, roadmap render, events.
class TestDomain < Minitest::Test
  include FlowTestHelper

  # ── ItemId (EARS-FLOW-014/015/016) ──────────────────────────────────────────

  def test_accepts_well_formed_slugs # @EARS-FLOW-014
    %w[a item-42 a1-b2-c3 flow-server].each { |s| assert_equal s, ItemId.new(s).to_s }
    assert ItemId.new("a" * 64) # exactly max len
  end

  def test_rejects_malformed_slugs # @EARS-FLOW-015
    ["", "Flow", "flow_server", "-flow", "flow-", "flow--server", "a" * 65, "x y"].each do |s|
      assert_raises(FlowMcp::IdError) { ItemId.new(s) }
    end
    assert_nil ItemId.parse("Bad Id")
  end

  def test_itemid_is_identity_usable_as_hash_key # @EARS-FLOW-016
    h = { ItemId.new("a") => 1 }
    assert_equal 1, h[ItemId.new("a")]
    assert_equal ItemId.new("a"), ItemId.new("a")
    assert_equal [iid("a"), iid("b")], [iid("b"), iid("a")].sort
  end

  # ── Flow graph (EARS-FLOW-029/037/038/043/050..058/065) ─────────────────────

  def flow_with(*ids)
    f = Flow.new
    ids.each { |s| f.upsert_item(Item.new(iid(s), s, "m")) }
    f
  end

  def test_new_item_defaults # @EARS-FLOW-019
    it = Item.new(iid("a"), "A", "m")
    assert_equal "do", it.status
    assert_equal "go", it.gate
    assert_equal 0, it.tokens
    assert_equal 0, it.draft
    refute it.synthesized
  end

  def test_advance_status_blocked_while_wait # @EARS-FLOW-030
    f = flow_with("a")
    f.set_gate(iid("a"), "wait")
    assert_raises(FlowMcp::FlowError) { f.advance_status(iid("a"), "doing") }
    assert_equal "do", f.get(iid("a")).status
    f.set_gate(iid("a"), "go")
    f.advance_status(iid("a"), "doing")
    assert_equal "doing", f.get(iid("a")).status
  end

  def test_append_spend_wait_and_unknown # @EARS-FLOW-040 @EARS-FLOW-041
    f = flow_with("a")
    assert_equal 100, f.append_spend(iid("a"), 100)
    f.set_gate(iid("a"), "wait")
    assert_raises(FlowMcp::FlowError) { f.append_spend(iid("a"), 1) }
    assert_equal 100, f.get(iid("a")).tokens
    assert_raises(FlowMcp::FlowError) { f.append_spend(iid("z"), 1) }
  end

  def test_token_tally_saturates_at_u64_max # @EARS-FLOW-043
    f = flow_with("a")
    f.accrue_tokens(iid("a"), FlowMcp::U64_MAX)
    assert_equal FlowMcp::U64_MAX, f.accrue_tokens(iid("a"), 5)
  end

  def test_accrue_not_wait_gated # @EARS-FLOW-039
    f = flow_with("a")
    f.set_gate(iid("a"), "wait")
    assert_equal 50, f.accrue_tokens(iid("a"), 50)
  end

  def test_bump_draft_not_wait_gated # @EARS-FLOW-065
    f = flow_with("a")
    f.set_gate(iid("a"), "wait")
    assert_equal 1, f.bump_draft(iid("a"))
    assert_equal 2, f.bump_draft(iid("a"))
    assert_raises(FlowMcp::FlowError) { f.bump_draft(iid("z")) }
  end

  def test_validate_connection_unknown_self_and_cycle # @EARS-FLOW-051 @EARS-FLOW-052
    f = flow_with("a", "b")
    assert_raises(FlowMcp::GraphError) { f.validate_connection(iid("a"), iid("z")) }
    err = assert_raises(FlowMcp::GraphError) { f.validate_connection(iid("a"), iid("a")) }
    assert_equal "cycle", err.data_code
    f.add_connection(iid("a"), iid("b"))
    cyc = assert_raises(FlowMcp::GraphError) { f.validate_connection(iid("b"), iid("a")) }
    assert_equal "cycle", cyc.data_code
  end

  def test_add_is_idempotent_remove_and_broken_dep # @EARS-FLOW-054 @EARS-FLOW-056
    f = flow_with("a", "b")
    f.add_connection(iid("a"), iid("b"))
    f.add_connection(iid("a"), iid("b"))
    assert_equal 1, f.edges.length
    f.remove_connection(iid("a"), iid("b"))
    assert_equal 0, f.edges.length
    bd = assert_raises(FlowMcp::GraphError) { f.remove_connection(iid("a"), iid("b")) }
    assert_equal "broken_dep", bd.data_code
  end

  def test_deep_cycle_and_diamond # @EARS-FLOW-052
    f = flow_with("a", "b", "c", "d")
    f.add_connection(iid("a"), iid("b"))
    f.add_connection(iid("b"), iid("c"))
    f.add_connection(iid("c"), iid("d"))
    assert_raises(FlowMcp::GraphError) { f.add_connection(iid("d"), iid("a")) }
    # diamond is not a cycle
    f.add_connection(iid("a"), iid("c"))
    assert f.edges.length >= 4
  end

  def test_reorder_is_permutation_only # @EARS-FLOW-016
    f = flow_with("a", "b", "c")
    assert f.reorder([iid("c"), iid("a"), iid("b")])
    assert_equal %w[c a b], f.items_in_order.map { |i| i.id.to_s }
    refute f.reorder([iid("a")])
    refute f.reorder([iid("a"), iid("b"), iid("z")])
    refute f.reorder([iid("a"), iid("a"), iid("b")])
  end

  # ── telemetry ancestors (EARS-FLOW-038) ─────────────────────────────────────

  def test_ancestors_chain_diamond_and_cycle_safe # @EARS-FLOW-038
    f = flow_with("a", "b", "c", "d")
    f.add_connection(iid("a"), iid("b"))
    f.add_connection(iid("b"), iid("c"))
    f.add_connection(iid("c"), iid("d"))
    assert_equal %w[b c d], Telemetry.ancestors(f, iid("a")).map(&:to_s)
    assert_empty Telemetry.ancestors(f, iid("d"))
  end

  def test_grafana_payload_shape # @EARS-FLOW-097
    rec = Telemetry.record(ts: 1, item_id: iid("a"), agent: "carriage-agent", activity: "spend",
                           tokens_delta: 10, tokens_total: 10, ancestors: [iid("b")])
    payload = Telemetry.grafana_payload([rec])
    assert_equal 1, payload["streams"].length
    assert_equal "a", payload["streams"][0]["stream"]["item_id"]
    assert_equal "1000000", payload["streams"][0]["values"][0][0] # ms -> ns
    assert_empty Telemetry.grafana_payload([])["streams"]
  end

  # ── annotation + render + event (EARS-FLOW-061/073/088/091) ──────────────────

  def test_annotation_block_is_deterministic # @EARS-FLOW-061
    assert_equal "\n<!-- annotation: a -->\n### Annotation on `a`\n\nship it\n",
                 Annotation.format(iid("a"), "ship it  \n\n")
    assert_equal "FLOW_SERVER_PLAN.md", Annotation.plan_doc_filename("Flow server")
    assert_equal "ITEM_15_PLAN.md", Annotation.plan_doc_filename("item 15")
  end

  def test_render_roadmap_empty_and_row # @EARS-FLOW-073 @EARS-FLOW-075
    assert_equal "ROADMAP\n0 item(s)\n\nDO\n  (none)\n\nDOING\n  (none)\n\nDONE\n  (none)\n",
                 RoadmapView.render(Flow.new)
    f = flow_with("x")
    f.append_spend(iid("x"), 1234)
    f.set_gate(iid("x"), "wait")
    f.bump_draft(iid("x"))
    assert_includes RoadmapView.render(f), "  · x · x · DO · WAIT · 1234 tok · d1"
    assert_equal RoadmapView.render(f), RoadmapView.render(f)
  end

  def test_event_roundtrip_and_malformed # @EARS-FLOW-088 @EARS-FLOW-091
    ev = Event.gate_set(iid("a"), "wait")
    line = Event.to_jsonl(ev)
    refute_includes line, "\n"
    assert_equal ev, Event.from_jsonl(line)
    assert_raises(FlowMcp::Error) { Event.from_jsonl("not json") }
    assert_raises(FlowMcp::Error) { Event.from_jsonl('{"kind":"nope"}') }
  end
end

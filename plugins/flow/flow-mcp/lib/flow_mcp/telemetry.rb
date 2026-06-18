# frozen_string_literal: true

require "json"
require_relative "ids"

module FlowMcp
  # Token telemetry — pure core (EARS-FLOW-038/044/045). Ancestor roll-up over the
  # dependency graph and the JSONL telemetry record. The thin IO that appends a line
  # to the telemetry ledger lives in the Store; the ledger (telemetry.jsonl) is the
  # single telemetry sink (EARS-FLOW-097).
  module Telemetry
    module_function

    # The transitive ancestors of +id+: every item it depends on, following
    # `from -> to` edges, excluding +id+ itself. Unique and sorted, so a spend
    # roll-up is deterministic. Cycle-safe via a visited set.
    def ancestors(flow, id)
      seen = {}
      stack = []
      flow.edges.each { |e| stack << e.to if e.from == id }
      until stack.empty?
        node = stack.pop
        next if node == id          # a cycle led back to the origin — never self-ancestor
        next if seen[node]

        seen[node] = true
        flow.edges.each { |e| stack << e.to if e.from == node }
      end
      seen.keys.sort
    end

    # One telemetry record (EARS-FLOW-044 schema), as a string-keyed hash that
    # serializes straight to a JSONL line.
    def record(ts:, item_id:, agent:, activity:, tokens_delta:, tokens_total:, ancestors:)
      {
        "ts" => ts,
        "item_id" => item_id.to_s,
        "agent" => agent,
        "activity" => activity,
        "tokens_delta" => tokens_delta,
        "tokens_total" => tokens_total,
        "ancestors" => ancestors.map(&:to_s)
      }
    end

    def to_jsonl(rec) = JSON.generate(rec)
  end
end

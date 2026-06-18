# frozen_string_literal: true

require "json"
require_relative "ids"

module FlowMcp
  # Token telemetry — pure core (EARS-FLOW-038/044/045/097). Ancestor roll-up over
  # the dependency graph, the JSONL telemetry record, and the Grafana/Loki push
  # payload builder. The thin IO that appends a line / pushes to Grafana lives in
  # the Store.
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

    # Build the Loki push body (one stream per event). Pure: the actual transport
    # (and graceful no-op when GRAFANA_URL is absent) lives in the Store.
    def grafana_payload(records)
      streams = records.map do |ev|
        {
          "stream" => { "job" => "flow-telemetry", "item_id" => ev["item_id"], "agent" => ev["agent"] },
          "values" => [[((ev["ts"] * 1_000_000)).to_s, JSON.generate(ev)]]
        }
      end
      { "streams" => streams }
    end
  end
end

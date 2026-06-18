# frozen_string_literal: true

require "json"
require "tmpdir"

# Step definitions for the flow-mcp FEATURE suite, executed in-process against a
# real Store. Regular verb scenarios run end-to-end here; steps with no matching
# definition (raw-transport handshake assertions, fault injection, launcher/Ruby
# environment) raise Pending so the runner reports them rather than passing
# silently — the rigorous coverage of those lives in the minitest suite.
module FeatureSteps
  class Pending < StandardError; end
  class Failure < StandardError; end

  # Execution context for one scenario.
  class World
    include FlowMcp
    attr_accessor :store, :resp, :rendered, :events_before, :edges_before, :arranging, :cfg, :config_error

    def initialize
      @arranging = true
      @rendered = []
    end

    def iid(s) = ItemId.new(s)

    def call(name, args)
      Mcp.dispatch(@store, { "id" => 1, "method" => "tools/call",
                             "params" => { "name" => name, "arguments" => args } })
    end
  end

  module_function

  def unescape(str) = str.gsub('\\n', "\n").gsub('\\t', "\t")

  def assert(cond, msg)
    raise Failure, msg unless cond
  end

  # Ordered [regex, handler] table. First match wins. Handler: ->(w, m, step).
  def table
    @table ||= [
      # ── arrange ──────────────────────────────────────────────────────────────
      [/\Aa running flow-mcp with (?:an empty store|a temporary data directory)\z/, lambda { |w, _m, _s|
        w.store = FlowMcp::Store.open(File.join(Dir.mktmpdir("flow-feat-"), ".flow"))
      }],
      [/\Athe store contains an item "(.+?)" titled "(.+?)"\z/, lambda { |w, m, _s|
        w.store.upsert_item(w.iid(m[1]), m[2], "claude-sonnet-4-6")
      }],
      [/\Athe store contains an item "(.+?)" titled "(.+?)"\z/i, lambda { |w, m, _s|
        w.store.upsert_item(w.iid(m[1]), m[2], "claude-sonnet-4-6")
      }],
      [/\Aitem "(.+?)" is in WAIT\z/, lambda { |w, m, _s| w.store.set_gate(w.iid(m[1]), "wait") }],
      [/\Aa dependency "(.+?)" -> "(.+?)"\z/, lambda { |w, m, _s|
        w.store.mutate_connection("add", w.iid(m[1]), w.iid(m[2]))
      }],
      [/\Aitem "(.+?)" has an annotation "(.+?)"\z/, lambda { |w, m, _s|
        w.store.annotate(w.iid(m[1]), m[2])
      }],
      [/\Aitem "(.+?)" already has the maximum token tally\z/, lambda { |w, m, _s|
        w.store.snapshot.get(w.iid(m[1])).tokens = FlowMcp::U64_MAX
      }],
      # "item X has status Y" — arrange form (before the When)
      [/\Aitem "(.+?)" has status "(.+?)"\z/, lambda { |w, m, _s|
        if w.arranging
          w.store.post_status(w.iid(m[1]), m[2])
        else
          assert(w.store.snapshot.get(w.iid(m[1]))&.status == m[2],
                 "expected #{m[1]} status #{m[2]}, got #{w.store.snapshot.get(w.iid(m[1]))&.status.inspect}")
        end
      }],

      # ── act ──────────────────────────────────────────────────────────────────
      [/\AI call "(.+?)" with (\{.*\}) twice\z/, lambda { |w, m, _s|
        w.arranging = false
        args = JSON.parse(m[2])
        w.rendered = [w.call(m[1], args), w.call(m[1], args)].map { |r| r.dig("result", "rendered") }
      }],
      [/\AI call "(.+?)" with (\{.*\})\z/, lambda { |w, m, _s|
        w.arranging = false
        w.events_before = w.store.read_events.length
        w.edges_before = w.store.snapshot.edges.length
        w.resp = w.call(m[1], JSON.parse(m[2]))
      }],
      # table-driven setup: "the following calls have been made:" + | call | args |
      [/\Athe following calls have been made:\z/, lambda { |w, _m, s|
        (s.table || []).drop(1).each { |row| w.call(row[0], JSON.parse(row[1])) }
      }],

      # ── config / startup (EARS-FLOW-079/080/081) ───────────────────────────────
      [/\Athe server starts with no flags\z/, lambda { |w, _m, _s| w.cfg = FlowMcp::Config.from_args([]) }],
      [/\Athe server starts with args "(.+?)"\z/, lambda { |w, m, _s|
        begin
          w.cfg = FlowMcp::Config.from_args(m[1].split(/\s+/))
        rescue FlowMcp::ConfigError => e
          w.config_error = e
        end
      }],
      [/\Athe data directory is "(.+?)"\z/, lambda { |w, m, _s| assert(w.cfg.data_dir == m[1], "data dir #{w.cfg.data_dir} != #{m[1]}") }],
      [/\Athe "--mcp" flag is accepted as a no-op\z/, lambda { |_w, _m, _s| assert(FlowMcp::Config.from_args(["--mcp"]).mcp == true, "--mcp not accepted") }],
      [/\Astartup fails with a missing-value error naming "(.+?)"\z/, lambda { |w, m, _s|
        assert(w.config_error.is_a?(FlowMcp::ConfigError) && w.config_error.message.include?(m[1]), "expected missing-value error for #{m[1]}")
      }],
      [/\Astartup fails with an unknown-flag error\z/, lambda { |w, _m, _s|
        assert(w.config_error.is_a?(FlowMcp::ConfigError), "expected unknown-flag error")
      }],

      # ── assert: edges (EARS-FLOW-050/053/054/055/058) ──────────────────────────
      [/\Athe edge "(.+?)" -> "(.+?)" exists\z/, lambda { |w, m, _s|
        assert(w.store.snapshot.edges.any? { |e| e.from.to_s == m[1] && e.to.to_s == m[2] }, "edge #{m[1]}->#{m[2]} missing")
      }],
      [/\Athe edge "(.+?)" -> "(.+?)" does not exist\z/, lambda { |w, m, _s|
        assert(w.store.snapshot.edges.none? { |e| e.from.to_s == m[1] && e.to.to_s == m[2] }, "edge #{m[1]}->#{m[2]} present")
      }],
      [/\Aexactly one edge "(.+?)" -> "(.+?)" exists\z/, lambda { |w, m, _s|
        n = w.store.snapshot.edges.count { |e| e.from.to_s == m[1] && e.to.to_s == m[2] }
        assert(n == 1, "expected exactly one edge #{m[1]}->#{m[2]}, got #{n}")
      }],
      [/\Aexactly one edge exists\z/, lambda { |w, _m, _s| assert(w.store.snapshot.edges.length == 1, "expected exactly one edge") }],
      [/\Athe edge set is unchanged\z/, lambda { |w, _m, _s|
        assert(w.store.snapshot.edges.length == (w.edges_before || 0), "edge set changed")
      }],

      # ── assert: responses ──────────────────────────────────────────────────────
      [/\Athe response result is (\{.*\})\z/, lambda { |w, m, _s|
        assert(w.resp["result"] == JSON.parse(m[1]), "result #{w.resp['result'].inspect} != #{m[1]}")
      }],
      [/\Athe response is an error with code (-?\d+) and data\.error "(.+?)"\z/, lambda { |w, m, _s|
        e = w.resp["error"] or raise Failure, "expected an error, got #{w.resp.inspect}"
        assert(e["code"] == m[1].to_i, "code #{e['code']} != #{m[1]}")
        assert(e.dig("data", "error") == m[2], "data.error #{e.dig('data', 'error').inspect} != #{m[2]}")
      }],
      [/\Athe response is an error with code (-?\d+)\z/, lambda { |w, m, _s|
        e = w.resp["error"] or raise Failure, "expected an error, got #{w.resp.inspect}"
        assert(e["code"] == m[1].to_i, "code #{e['code']} != #{m[1]}")
      }],
      [/\Athe response is an error\z/, lambda { |w, _m, _s| assert(w.resp["error"], "expected an error") }],
      [/\Athe response is not an invalid-params error\z/, lambda { |w, _m, _s|
        assert(w.resp.dig("error", "code") != -32602, "unexpected invalid-params: #{w.resp.inspect}")
      }],
      [/\Athe response result total is (\d+)\z/, lambda { |w, m, _s|
        assert(w.resp.dig("result", "total") == m[1].to_i, "total #{w.resp.dig('result', 'total')} != #{m[1]}")
      }],
      [/\Athe response result draft is (\d+)\z/, lambda { |w, m, _s|
        assert(w.resp.dig("result", "draft") == m[1].to_i, "draft #{w.resp.dig('result', 'draft')} != #{m[1]}")
      }],

      # ── assert: item state ─────────────────────────────────────────────────────
      [/\Aitem "(.+?)" has gate "(.+?)"(?: in memory)?\z/, lambda { |w, m, _s|
        assert(w.store.snapshot.get(w.iid(m[1]))&.gate == m[2], "gate mismatch for #{m[1]}")
      }],
      [/\Aitem "(.+?)" has tokens (\d+)\z/, lambda { |w, m, _s|
        assert(w.store.snapshot.get(w.iid(m[1]))&.tokens == m[2].to_i, "tokens mismatch for #{m[1]}")
      }],
      [/\Aitem "(.+?)" has model "(.+?)"\z/, lambda { |w, m, _s|
        assert(w.store.snapshot.get(w.iid(m[1]))&.model == m[2], "model mismatch for #{m[1]}")
      }],
      [/\Aitem "(.+?)" still has the maximum token tally\z/, lambda { |w, m, _s|
        assert(w.store.snapshot.get(w.iid(m[1]))&.tokens == FlowMcp::U64_MAX, "not saturated")
      }],

      # ── assert: event log ──────────────────────────────────────────────────────
      [/\Aa "(.+?)" event was appended to the log\z/, lambda { |w, m, _s|
        assert(w.store.read_events.any? { |e| e["kind"] == m[1] }, "no #{m[1]} event")
      }],
      [/\Aa "(.+?)" event carrying "(.+?)" was appended to the log\z/, lambda { |w, m, _s|
        assert(w.store.read_events.any? { |e| e["kind"] == m[1] && e.values.include?(m[2]) }, "no #{m[1]} carrying #{m[2]}")
      }],
      [/\Ano event was appended to the log\z/, lambda { |w, _m, _s|
        assert(w.store.read_events.length == (w.events_before || 0), "events changed")
      }],

      # ── assert: list_items + get_item shapes ───────────────────────────────────
      [/\Athe response result "(.+?)" contains item "(.+?)"\z/, lambda { |w, m, _s|
        coll = dig_path(w.resp["result"], m[1])
        assert(coll.is_a?(Array) && coll.any? { |i| i["id"] == m[2] }, "#{m[1]} missing #{m[2]}")
      }],
      [/\Athe response result "(.+?)" is empty\z/, lambda { |w, m, _s|
        assert(Array(dig_path(w.resp["result"], m[1])).empty?, "#{m[1]} not empty")
      }],
      [/\Athe response result item "(.+?)" is "(.+?)"\z/, lambda { |w, m, _s|
        assert(w.resp.dig("result", "item", m[1]) == m[2], "item.#{m[1]} != #{m[2]}")
      }],
      [/\Athe response result item "(.+?)" is null\z/, lambda { |w, m, _s|
        assert(w.resp.dig("result", "item", m[1]).nil?, "item.#{m[1]} not null")
      }],
      [/\Athe response result item "(.+?)" is an empty array\z/, lambda { |w, m, _s|
        assert(w.resp.dig("result", "item", m[1]) == [], "item.#{m[1]} not []")
      }],
      [/\Athe response result item "(.+?)" contains "(.+?)"\z/, lambda { |w, m, _s|
        assert(Array(w.resp.dig("result", "item", m[1])).include?(m[2]), "item.#{m[1]} missing #{m[2]}")
      }],

      # ── assert: render + ping ──────────────────────────────────────────────────
      [/\Athe response result rendered starts with "(.*)"\z/, lambda { |w, m, _s|
        assert(w.resp.dig("result", "rendered").to_s.start_with?(unescape(m[1])), "render prefix mismatch")
      }],
      [/\Athe response result rendered contains a warning mentioning "(.+?)"\z/, lambda { |w, m, _s|
        assert(w.resp.dig("result", "rendered").to_s.include?(m[1]), "render missing #{m[1]}")
      }],
      [/\Athe response result rendered contains "(.*)"\z/, lambda { |w, m, _s|
        assert(w.resp.dig("result", "rendered").to_s.include?(unescape(m[1])), "render missing fragment")
      }],
      [/\Aboth rendered results are byte-identical\z/, lambda { |w, _m, _s|
        assert(w.rendered[0] == w.rendered[1], "renders differ")
      }],
      [/\Athe response result message is present\z/, lambda { |w, _m, _s|
        assert(!w.resp.dig("result", "message").to_s.empty?, "no message")
      }],
      [/\Athe response result version is a non-empty string\z/, lambda { |w, _m, _s|
        assert(!w.resp.dig("result", "version").to_s.empty?, "no version")
      }],
      [/\Athe response result items is (\d+)\z/, lambda { |w, m, _s|
        assert(w.resp.dig("result", "items") == m[1].to_i, "items != #{m[1]}")
      }],
      [/\Athe response result source is null\z/, lambda { |w, _m, _s|
        assert(w.resp.dig("result", "source").nil?, "source not null")
      }]
    ]
  end

  def dig_path(obj, path)
    path.split(".").reduce(obj) { |acc, k| acc.is_a?(Hash) ? acc[k] : nil }
  end

  # Run one step; raise Pending if no definition matches.
  def run(world, step)
    table.each do |re, handler|
      m = step.text.match(re)
      return handler.call(world, m, step) if m
    end
    raise Pending, step.text
  end
end

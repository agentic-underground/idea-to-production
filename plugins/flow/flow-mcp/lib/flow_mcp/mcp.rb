# frozen_string_literal: true

require "json"
require_relative "version"
require_relative "ids"
require_relative "model"
require_relative "roadmap_view"
require_relative "errors"

module FlowMcp
  # Hand-rolled MCP JSON-RPC surface (EARS-FLOW-001..013). `dispatch` is the single
  # transport-agnostic entry point, driven by the stdio loop in Server.
  module Mcp
    SUPPORTED_PROTOCOL_VERSIONS = ["2024-11-05"].freeze
    LATEST_PROTOCOL_VERSION = "2024-11-05"
    SERVER_NAME = "flow-mcp"

    # One (name, one-line description) per verb — the single source of truth for
    # the verb set (EARS-FLOW-007). Order is the tools/list order.
    TOOL_DESCRIPTIONS = [
      ["ping", "Health check — returns a greeting plus server version, ingested item count, and roadmap source."],
      ["list_items", "List roadmap items grouped by status (pending/in_progress/done)."],
      ["get_item", "Fetch one roadmap item by id with its deps and annotations."],
      ["set_wait_go", "Toggle an item's WAIT/GO gate."],
      ["post_status", "Move an item to a new status (the folder = the status)."],
      ["append_spend", "Record token spend against an item (rolls up to ancestors)."],
      ["set_item_model", "Set the model tier for an item."],
      ["validate_connection", "Validate a proposed dependency edge without applying it."],
      ["mutate_connection", "Add or remove a dependency edge between two items."],
      ["append_sysmsg", "Append a system message to the event feed."],
      ["render_roadmap", "Render 'what's on the roadmap' as text — ~0 LLM tokens."],
      ["annotate", "Annotate an item's plan (pauses the item)."],
      ["request_rewrite", "Request a plan rewrite, bumping the draft number."],
      ["list_events", "Read the append-only event log, oldest first."]
    ].freeze

    # Internal sentinel for argument-shape failures -> JSON-RPC -32602.
    class InvalidParams < FlowMcp::Error; end

    module_function

    def server_version = FlowMcp::VERSION

    # Dispatch one JSON-RPC request, returning a response Hash, or nil for a
    # notification that must receive no response (EARS-FLOW-005).
    def dispatch(store, req)
      # A valid-JSON line that is not an object (e.g. `5`, `[]`, `true`) carries no
      # id/method; treat it as a no-id notification (no response) rather than
      # crashing the loop — matches the Rust reference's graceful handling.
      return nil unless req.is_a?(Hash)

      id = req["id"]
      method = req["method"].to_s

      case method
      when "initialize"
        requested = req.dig("params", "protocolVersion")
        protocol = SUPPORTED_PROTOCOL_VERSIONS.include?(requested) ? requested : LATEST_PROTOCOL_VERSION
        ok(id, {
          "protocolVersion" => protocol,
          "capabilities" => { "tools" => {} },
          "serverInfo" => { "name" => SERVER_NAME, "version" => server_version }
        })
      when "notifications/initialized", "initialized"
        nil
      when "tools/list"
        ok(id, { "tools" => tool_descriptors })
      when "tools/call"
        params = req["params"] || {}
        name = params["name"].to_s
        args = params["arguments"] || {}
        call_tool(store, id, name, args)
      else
        rpc_error(id, -32601, "method not found: #{method}", nil)
      end
    end

    def call_tool(store, id, name, args)
      flow = store.snapshot
      case name
      when "ping"
        items = flow.items_in_order.length
        ok(id, { "message" => "hello from the flow MCP", "version" => server_version,
                 "items" => items, "source" => store.roadmap_source&.to_s })
      when "list_items"
        groups = { "pending" => { "wait" => [], "go" => [] }, "in_progress" => [], "done" => [] }
        flow.items_in_order.each do |i|
          v = item_json(i, deps_for(i, flow.edges), store.annotations_for(i.id))
          case i.status
          when "do"   then groups["pending"][i.gate == "wait" ? "wait" : "go"] << v
          when "doing" then groups["in_progress"] << v
          when "done"  then groups["done"] << v
          end
        end
        ok(id, groups)
      when "get_item"
        item_id = arg_id(args, "id")
        item = flow.get(item_id)
        return rpc_error(id, -32004, "unknown item", { "error" => "unknown" }) unless item

        ok(id, { "item" => item_json(item, deps_for(item, flow.edges), store.annotations_for(item.id)) })
      when "set_wait_go"
        item_id = arg_id(args, "id")
        gate = arg_enum(args, "gate", GATES)
        store.set_gate(item_id, gate)
        ok(id, { "ok" => true })
      when "post_status"
        item_id = arg_id(args, "id")
        status = arg_enum(args, "status", STATUSES)
        store.post_status(item_id, status)
        ok(id, { "ok" => true })
      when "append_spend"
        item_id = arg_id(args, "id")
        delta = arg_u64(args, "delta")
        total = store.append_spend(item_id, delta)
        ok(id, { "total" => total })
      when "set_item_model"
        item_id = arg_id(args, "id")
        model = arg_string(args, "model")
        store.set_item_model(item_id, model)
        ok(id, { "ok" => true })
      when "validate_connection"
        from = arg_id(args, "from")
        to = arg_id(args, "to")
        store.validate_connection(from, to)
        ok(id, { "ok" => true })
      when "mutate_connection"
        op = args["op"]
        raise InvalidParams, "op must be 'add' or 'remove'" unless %w[add remove].include?(op)

        from = arg_id(args, "from")
        to = arg_id(args, "to")
        store.mutate_connection(op, from, to)
        ok(id, { "ok" => true })
      when "append_sysmsg"
        store.append_sysmsg(arg_string(args, "text"))
        ok(id, { "ok" => true })
      when "render_roadmap"
        rendered = RoadmapView.render(flow).dup
        if flow.items_in_order.empty?
          rendered << "\n⚠ 0 items — the roadmap store is empty. If a .i2p/roadmap/ tree exists on disk, " \
                      "the server may be stale or misconfigured; call `ping` to check its version + source.\n"
        end
        ok(id, { "rendered" => rendered })
      when "annotate"
        item_id = arg_id(args, "id")
        text = arg_string(args, "text")
        store.annotate(item_id, text)
        ok(id, { "ok" => true })
      when "request_rewrite"
        item_id = arg_id(args, "id")
        comment = arg_string(args, "comment")
        draft = store.request_rewrite(item_id, comment)
        ok(id, { "draft" => draft })
      when "list_events"
        kind = args["kind"]
        kind = nil unless kind.is_a?(String)  # non-string kind ignored (EARS-FLOW-072)
        events = store.read_events
        events = events.select { |e| e["kind"] == kind } if kind
        ok(id, { "events" => events })
      else
        rpc_error(id, -32602, "unknown tool: #{name}", nil)
      end
    rescue InvalidParams, IdError => e
      rpc_error(id, -32602, e.message, nil)
    rescue FlowError, GraphError => e
      rpc_error(id, -32000, e.message, { "error" => e.data_code })
    rescue StoreIoError
      rpc_error(id, -32603, "internal store error", { "error" => "io" })
    rescue StandardError => e
      # An unexpected internal error: emit a full backtrace to stderr
      # (EARS-FLOW-096) and surface -32603 so one bad call never crashes the loop.
      warn "flow-mcp: internal error in #{name}: #{e.class}: #{e.message}"
      warn e.backtrace.join("\n")
      rpc_error(id, -32603, "internal error", { "error" => "internal" })
    end

    # ── tool descriptors ────────────────────────────────────────────────────────

    def tool_descriptors
      TOOL_DESCRIPTIONS.map { |name, desc| { "name" => name, "description" => desc, "inputSchema" => input_schema(name) } }
    end

    def input_schema(name)
      id = { "type" => "string", "description" => "Item id (e.g. \"item-42\")." }
      obj = ->(props, req) { { "type" => "object", "properties" => props, "required" => req } }
      case name
      when "get_item" then obj.call({ "id" => id }, ["id"])
      when "set_wait_go" then obj.call({ "id" => id, "gate" => { "type" => "string", "enum" => %w[wait go] } }, %w[id gate])
      when "post_status" then obj.call({ "id" => id, "status" => { "type" => "string", "enum" => %w[do doing done] } }, %w[id status])
      when "append_spend" then obj.call({ "id" => id, "delta" => { "type" => "integer", "minimum" => 0, "description" => "Tokens to add." } }, %w[id delta])
      when "set_item_model" then obj.call({ "id" => id, "model" => { "type" => "string", "description" => "Model tier id." } }, %w[id model])
      when "validate_connection"
        obj.call({ "from" => { "type" => "string", "description" => "Dependent item id." }, "to" => { "type" => "string", "description" => "Dependency item id." } }, %w[from to])
      when "mutate_connection"
        obj.call({ "op" => { "type" => "string", "enum" => %w[add remove] },
                   "from" => { "type" => "string", "description" => "Dependent item id." },
                   "to" => { "type" => "string", "description" => "Dependency item id." } }, %w[op from to])
      when "append_sysmsg" then obj.call({ "text" => { "type" => "string", "description" => "Message to append to the feed." } }, %w[text])
      when "annotate" then obj.call({ "id" => id, "text" => { "type" => "string", "description" => "Annotation text." } }, %w[id text])
      when "request_rewrite" then obj.call({ "id" => id, "comment" => { "type" => "string", "description" => "Rewrite request." } }, %w[id comment])
      when "list_events" then { "type" => "object", "properties" => { "kind" => { "type" => "string", "description" => "Optional event-kind filter." } } }
      else { "type" => "object" }
      end
    end

    # ── argument helpers ────────────────────────────────────────────────────────

    def arg_id(args, key)
      raw = args[key]
      raise InvalidParams, "#{key} must be a string" unless raw.is_a?(String)

      ItemId.new(raw) # raises IdError -> -32602
    end

    def arg_string(args, key)
      v = args[key]
      raise InvalidParams, "#{key} must be a string" unless v.is_a?(String)

      v
    end

    def arg_enum(args, key, allowed)
      v = args[key]
      raise InvalidParams, "#{key} must be one of #{allowed.join('/')}" unless allowed.include?(v)

      v
    end

    def arg_u64(args, key)
      v = args[key]
      raise InvalidParams, "#{key} must be a u64" unless v.is_a?(Integer) && v >= 0 && v <= FlowMcp::U64_MAX

      v
    end

    # ── JSON render helpers ──────────────────────────────────────────────────────

    def item_json(item, deps, annotations)
      {
        "id" => item.id.to_s, "title" => item.title, "status" => item.status, "gate" => item.gate,
        "tokens" => item.tokens, "model" => item.model, "draft" => item.draft,
        "deps" => deps, "annotations" => annotations, "commits" => [], "pr" => nil
      }
    end

    def deps_for(item, edges)
      edges.select { |e| e.from == item.id }.map { |e| e.to.to_s }
    end

    # ── response builders ────────────────────────────────────────────────────────

    def ok(id, result) = { "jsonrpc" => "2.0", "id" => id, "result" => result }

    def rpc_error(id, code, message, data)
      { "jsonrpc" => "2.0", "id" => id, "error" => { "code" => code, "message" => message, "data" => data } }
    end
  end
end

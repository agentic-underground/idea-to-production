# frozen_string_literal: true

module FlowMcp
  # Base class for every typed flow-mcp error. No strings-as-errors: each subclass
  # is matchable and (where it crosses the MCP surface) carries the JSON-RPC code
  # and the `error.data.error` string the spec pins.
  class Error < StandardError; end

  # Raised while parsing a stable slug ItemId (EARS-FLOW-014/015). Surfaces as a
  # JSON-RPC -32602 (invalid params) at the MCP boundary.
  class IdError < Error; end

  # A graph mutation was refused (EARS-FLOW-051/052/056/058). `data_code` is the
  # `error.data.error` string: "cycle" | "broken_dep" | "unknown".
  class GraphError < Error
    attr_reader :data_code

    def initialize(message, data_code)
      super(message)
      @data_code = data_code
    end

    def self.cycle(from, to)
      new("connection #{from} -> #{to} would form a cycle", "cycle")
    end

    def self.broken_dep(from, to)
      new("connection #{from} -> #{to} would break a dependency", "broken_dep")
    end

    def self.unknown(id)
      new("unknown item #{id} referenced in connection", "unknown")
    end
  end

  # A carriage-advance / mutation verb was refused at the domain level
  # (EARS-FLOW-025/030/031/040/041/047/063/066). `data_code`: "waiting" | "unknown".
  class FlowError < Error
    attr_reader :data_code

    def initialize(message, data_code)
      super(message)
      @data_code = data_code
    end

    def self.waiting(id)
      new("item #{id} is in WAIT; carriage-advance is refused", "waiting")
    end

    def self.unknown(id)
      new("unknown item #{id}", "unknown")
    end
  end

  # An IO / serialization failure on a write path (EARS-FLOW-095). Surfaces as a
  # JSON-RPC -32603 (internal error), never conflated with a domain refusal.
  class StoreIoError < Error; end

  # A CLI configuration error (EARS-FLOW-080/081). Fatal at startup.
  class ConfigError < Error; end
end

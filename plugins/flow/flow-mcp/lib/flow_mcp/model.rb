# frozen_string_literal: true

require_relative "ids"
require_relative "errors"

module FlowMcp
  # Cap token tallies at the unsigned 64-bit maximum (EARS-FLOW-043) so the Ruby
  # port matches the retired Rust reference's saturating u64 arithmetic. The draft
  # counter is a u32 in the reference, so it saturates one ceiling lower.
  U64_MAX = (2**64) - 1
  U32_MAX = (2**32) - 1

  STATUSES = %w[do doing done].freeze
  GATES = %w[wait go].freeze

  # A single work item, keyed by its stable slug ItemId.
  class Item
    attr_accessor :title, :status, :gate, :tokens, :model, :draft, :synthesized
    attr_reader :id

    def initialize(id, title, model)
      @id = id
      @title = title
      @status = "do"
      @gate = "go"
      @tokens = 0
      @model = model
      @draft = 0
      @synthesized = false
    end
  end

  Edge = Struct.new(:from, :to)

  # The flow graph: ordered items + dependency edges, kept acyclic with all edge
  # endpoints known. An edge `from -> to` means "from depends on to".
  class Flow
    def initialize
      @items = {}          # ItemId => Item
      @order = []          # [ItemId] display order
      @edges = []          # [Edge]
    end

    def upsert_item(item)
      @order << item.id unless @items.key?(item.id)
      @items[item.id] = item
    end

    def get(id) = @items[id]
    def contains?(id) = @items.key?(id)
    def items_in_order = @order.map { |id| @items[id] }.compact
    def edges = @edges

    # Remove an item and every edge incident on it (EARS-FLOW-105). Returns false
    # if the item was absent.
    def remove_item(id)
      return false unless @items.key?(id)

      @items.delete(id)
      @order.delete(id)
      @edges.reject! { |e| e.from == id || e.to == id }
      true
    end

    # Reorder the display sequence; the new order must be a permutation of the
    # existing ids, else the order is left unchanged and false returned.
    def reorder(new_order)
      return false unless new_order.length == @order.length
      return false unless new_order.all? { |id| @items.key?(id) }
      return false unless new_order.uniq.length == new_order.length

      @order = new_order
      true
    end

    def set_gate(id, gate)
      item = fetch!(id)
      item.gate = gate
      nil
    end

    # Advance status; refused with FlowError.waiting if the item is in WAIT
    # (EARS-FLOW-029/030).
    def advance_status(id, status)
      item = fetch!(id)
      raise FlowError.waiting(id) if item.gate == "wait"

      item.status = status
      nil
    end

    # Add the item's own spend; WAIT-gated (EARS-FLOW-037/040). Returns the tally.
    def append_spend(id, delta)
      item = fetch!(id)
      raise FlowError.waiting(id) if item.gate == "wait"

      item.tokens = [item.tokens + delta, U64_MAX].min
      item.tokens
    end

    # Roll a tally up onto an item unconditionally — NOT WAIT-gated, because a
    # roll-up is a derived sub-tree total, not the item's own carriage work
    # (EARS-FLOW-038/039).
    def accrue_tokens(id, delta)
      item = fetch!(id)
      item.tokens = [item.tokens + delta, U64_MAX].min
      item.tokens
    end

    def set_model(id, model)
      fetch!(id).model = model
      nil
    end

    # Increment the draft counter and return it. NOT WAIT-gated (EARS-FLOW-065).
    def bump_draft(id)
      item = fetch!(id)
      item.draft = [item.draft + 1, U32_MAX].min
      item.draft
    end

    # Pure validation that adding `from -> to` keeps the graph buildable: both
    # endpoints known, not a self-edge, no cycle (EARS-FLOW-050/051/052).
    def validate_connection(from, to)
      raise GraphError.unknown(from) unless @items.key?(from)
      raise GraphError.unknown(to) unless @items.key?(to)
      raise GraphError.cycle(from, to) if from == to
      raise GraphError.cycle(from, to) if reachable?(to, from)

      nil
    end

    def add_connection(from, to)
      validate_connection(from, to)
      @edges << Edge.new(from, to) unless edge?(from, to)
      nil
    end

    def remove_connection(from, to)
      raise GraphError.unknown(from) unless @items.key?(from)
      raise GraphError.unknown(to) unless @items.key?(to)
      raise GraphError.broken_dep(from, to) unless edge?(from, to)

      @edges.reject! { |e| e.from == from && e.to == to }
      nil
    end

    private

    def fetch!(id)
      @items[id] or raise FlowError.unknown(id)
    end

    def edge?(from, to)
      @edges.any? { |e| e.from == from && e.to == to }
    end

    # Is +target+ reachable from +start+ following `from -> to` edges?
    def reachable?(start, target)
      stack = [start]
      visited = {}
      until stack.empty?
        node = stack.pop
        return true if node == target
        next if visited[node]

        visited[node] = true
        @edges.each { |e| stack << e.to if e.from == node }
      end
      false
    end
  end
end

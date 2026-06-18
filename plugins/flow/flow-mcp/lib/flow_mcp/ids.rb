# frozen_string_literal: true

require_relative "errors"

module FlowMcp
  # A validated, stable slug identifier for a flow item (EARS-FLOW-014).
  #
  # Parse-don't-validate: once you hold an ItemId, its invariants (non-empty,
  # `[a-z0-9-]`, no leading/trailing/double hyphen, <= 64 chars) are guaranteed.
  # The display number `[N]` is NOT the identity — this slug is (EARS-FLOW-016).
  class ItemId
    include Comparable

    MAX_LEN = 64
    PATTERN = /\A[a-z0-9-]+\z/

    attr_reader :value

    # Parse +candidate+ into an ItemId or raise IdError. The single construction
    # path; downstream code never re-checks the invariants.
    def initialize(candidate)
      raise IdError, "item id must not be empty" if candidate.nil? || candidate.empty?

      got = candidate.length
      if got > MAX_LEN
        raise IdError, "item id too long: max #{MAX_LEN}, got #{got}"
      end
      unless candidate.match?(PATTERN)
        bad = candidate.each_char.find { |c| !c.match?(/[a-z0-9-]/) }
        raise IdError, "item id contains invalid character #{bad.inspect} (allowed: a-z 0-9 '-')"
      end
      if candidate.start_with?("-") || candidate.end_with?("-") || candidate.include?("--")
        raise IdError, "item id has a malformed hyphen (no leading/trailing '-' and no '--')"
      end

      @value = candidate.dup.freeze
      freeze
    end

    # Parse without raising: returns an ItemId or nil.
    def self.parse(candidate)
      new(candidate)
    rescue IdError
      nil
    end

    def to_s = @value
    def to_str = @value

    def ==(other) = other.is_a?(ItemId) && other.value == @value
    alias eql? ==

    def hash = @value.hash
    def <=>(other) = other.is_a?(ItemId) ? @value <=> other.value : nil
  end
end

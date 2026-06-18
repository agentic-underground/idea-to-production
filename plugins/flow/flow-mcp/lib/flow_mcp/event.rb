# frozen_string_literal: true

require "json"
require_relative "errors"

module FlowMcp
  # The append-only event schema (EARS-FLOW-088). Each mutation produces one
  # `kind`-tagged JSON object, serialized as a single JSONL line. Events are
  # represented as plain string-keyed Hashes so they round-trip through JSON with
  # no bespoke (de)serialization and render directly in `list_events`.
  module Event
    KINDS = %w[
      item_upserted gate_set status_posted spend_appended model_set
      connection_added connection_removed annotated rewrite_requested sys_msg
    ].freeze

    module_function

    def item_upserted(id, title) = { "kind" => "item_upserted", "id" => id.to_s, "title" => title }
    def gate_set(id, gate) = { "kind" => "gate_set", "id" => id.to_s, "gate" => gate }
    def status_posted(id, status) = { "kind" => "status_posted", "id" => id.to_s, "status" => status }

    def spend_appended(id, delta, total)
      { "kind" => "spend_appended", "id" => id.to_s, "delta" => delta, "total" => total }
    end

    def model_set(id, model) = { "kind" => "model_set", "id" => id.to_s, "model" => model }
    def connection_added(from, to) = { "kind" => "connection_added", "from" => from.to_s, "to" => to.to_s }
    def connection_removed(from, to) = { "kind" => "connection_removed", "from" => from.to_s, "to" => to.to_s }
    def annotated(id, text) = { "kind" => "annotated", "id" => id.to_s, "text" => text }

    def rewrite_requested(id, comment, draft)
      { "kind" => "rewrite_requested", "id" => id.to_s, "comment" => comment, "draft" => draft }
    end

    def sys_msg(text) = { "kind" => "sys_msg", "text" => text }

    # Serialize one event as a single JSONL line (no trailing newline).
    def to_jsonl(event) = JSON.generate(event)

    # Parse one JSONL line back into an event hash. A line that is not a valid
    # event — malformed JSON OR a recognised object with an unknown `kind` —
    # raises, so replay aborts the open rather than silently dropping state
    # (EARS-FLOW-091).
    def from_jsonl(line)
      parsed =
        begin
          JSON.parse(line)
        rescue JSON::ParserError => e
          raise FlowMcp::Error, "malformed event line: #{e.message}"
        end
      unless parsed.is_a?(Hash) && KINDS.include?(parsed["kind"])
        raise FlowMcp::Error, "malformed event line: unknown kind #{parsed.is_a?(Hash) ? parsed['kind'].inspect : 'n/a'}"
      end
      parsed
    end
  end
end

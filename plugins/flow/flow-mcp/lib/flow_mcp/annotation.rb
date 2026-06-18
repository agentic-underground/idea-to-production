# frozen_string_literal: true

module FlowMcp
  # Pure annotation formatter (EARS-FLOW-061) — no IO. Turns a human comment into
  # the deterministic, append-safe markdown block the store appends to an item's
  # plan document. Byte-identical to the retired Rust reference.
  module Annotation
    module_function

    def format(id, comment)
      body = comment.rstrip
      "\n<!-- annotation: #{id} -->\n### Annotation on `#{id}`\n\n#{body}\n"
    end

    # Derive the plan-doc filename for an item title (EARS-FLOW-060): uppercase,
    # each run of non-alphanumerics collapsed to a single `_`, surrounding `_`
    # trimmed, suffixed `_PLAN.md`. e.g. "Flow server" -> "FLOW_SERVER_PLAN.md".
    def plan_doc_filename(title)
      name = +""
      last_us = false
      title.each_char do |ch|
        if ch.match?(/[A-Za-z0-9]/)
          name << ch.upcase
          last_us = false
        elsif !last_us
          name << "_"
          last_us = true
        end
      end
      "#{name.gsub(/\A_+|_+\z/, '')}_PLAN.md"
    end
  end
end

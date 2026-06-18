# frozen_string_literal: true

module FlowMcp
  # Pure roadmap renderer (EARS-FLOW-073/075) — no IO. Turns a Flow into a
  # deterministic, byte-stable text board grouped DO/DOING/DONE. Identical bytes
  # for identical state, so it can be cached, diffed, and compared.
  module RoadmapView
    STATUS_LABEL = { "do" => "DO", "doing" => "DOING", "done" => "DONE" }.freeze

    module_function

    def render(flow)
      items = flow.items_in_order
      out = +"ROADMAP\n"
      out << "#{items.length} item(s)\n"
      [%w[DO do], %w[DOING doing], %w[DONE done]].each do |heading, status|
        out << "\n" << heading << "\n"
        group = items.select { |i| i.status == status }
        if group.empty?
          out << "  (none)\n"
        else
          group.each { |item| out << render_row(item) << "\n" }
        end
      end
      out
    end

    def render_row(item)
      "  · #{item.id} · #{item.title} · #{STATUS_LABEL.fetch(item.status)} · " \
        "#{item.gate == 'wait' ? 'WAIT' : 'GO'} · #{item.tokens} tok · d#{item.draft}"
    end
  end
end

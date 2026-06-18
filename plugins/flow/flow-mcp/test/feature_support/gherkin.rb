# frozen_string_literal: true

# A tiny stdlib-only Gherkin parser — enough to drive the flow-mcp FEATURE suite
# without the cucumber gem (EARS-FLOW-099: runs on bare Debian-13 system Ruby).
# It recognises Feature/Background/Scenario/Scenario Outline/Examples, @tags,
# Given/When/Then/And/But steps, """ docstrings, and | tables.
module Gherkin
  Step = Struct.new(:keyword, :text, :docstring, :table)
  Scenario = Struct.new(:name, :tags, :steps, :outline, :examples)
  Feature = Struct.new(:name, :path, :background, :scenarios)

  module_function

  def parse_file(path)
    parse(File.read(path), path)
  end

  def parse(text, path = "(memory)")
    feature = Feature.new(nil, path, [], [])
    pending_tags = []
    current = nil          # current scenario being built (or :background)
    bg_steps = []
    lines = text.each_line.map { |l| l.chomp }
    i = 0
    while i < lines.length
      raw = lines[i]
      line = raw.strip
      i += 1
      next if line.empty? || line.start_with?("#")

      if line.start_with?("@")
        pending_tags.concat(line.split(/\s+/).map { |t| t.delete_prefix("@") })
        next
      end

      if (m = line.match(/\AFeature:\s*(.*)\z/))
        feature.name = m[1]
        current = nil
      elsif line.start_with?("Background:")
        current = :background
      elsif (m = line.match(/\A(Scenario Outline|Scenario):\s*(.*)\z/))
        sc = Scenario.new(m[2], pending_tags, [], m[1] == "Scenario Outline", nil)
        pending_tags = []
        feature.scenarios << sc
        current = sc
      elsif line.start_with?("Examples:")
        # collect the table that follows
        rows = []
        while i < lines.length && lines[i].strip.start_with?("|")
          rows << split_row(lines[i].strip)
          i += 1
        end
        current.examples = { header: rows.first, rows: rows.drop(1) } if current.is_a?(Scenario)
      elsif (m = line.match(/\A(Given|When|Then|And|But)\s+(.*)\z/))
        step = Step.new(m[1], m[2], nil, nil)
        # docstring?
        if i < lines.length && lines[i].strip == '"""'
          i += 1 # skip opening """
          doc = []
          until i >= lines.length || lines[i].strip == '"""'
            doc << lines[i]
            i += 1
          end
          i += 1 # skip closing """
          step.docstring = doc.join("\n")
        end
        # data table?
        if i < lines.length && lines[i].strip.start_with?("|")
          table = []
          while i < lines.length && lines[i].strip.start_with?("|")
            table << split_row(lines[i].strip)
            i += 1
          end
          step.table = table
        end
        (current == :background ? bg_steps : current.steps) << step
      end
    end
    feature.background = bg_steps
    feature
  end

  def split_row(line)
    line.sub(/\A\|/, "").sub(/\|\z/, "").split("|").map(&:strip)
  end

  # Expand a Scenario Outline into concrete scenarios (one per Examples row).
  def expand(scenario)
    return [scenario] unless scenario.outline && scenario.examples

    header = scenario.examples[:header]
    scenario.examples[:rows].map do |row|
      subs = header.zip(row).to_h
      steps = scenario.steps.map do |s|
        Step.new(s.keyword, substitute(s.text, subs), s.docstring, s.table)
      end
      Scenario.new("#{scenario.name} [#{row.join(',')}]", scenario.tags, steps, false, nil)
    end
  end

  def substitute(text, subs)
    text.gsub(/<([^>]+)>/) { subs.fetch(Regexp.last_match(1), Regexp.last_match(0)) }
  end
end

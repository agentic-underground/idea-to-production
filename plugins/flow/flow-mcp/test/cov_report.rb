# frozen_string_literal: true

# Line + branch coverage over lib/flow_mcp using the stdlib Coverage module
# (no simplecov gem — runs on bare Debian-13 system Ruby). Registered before the
# tests are required so its at_exit fires AFTER minitest's (at_exit is LIFO).
require "coverage"
Coverage.start(lines: true, branches: true)

LIB_DIR = File.expand_path("../lib", __dir__)
# Dual floors: lines held high; branch coverage held a notch lower because the
# remaining uncovered branches are defensive IO/nil arms needing contrived fault
# injection to reach. Override via env for a stricter local run.
LINE_MIN = Float(ENV.fetch("FLOW_COV_LINE", "98"))
BRANCH_MIN = Float(ENV.fetch("FLOW_COV_BRANCH", "80"))

at_exit do
  result = Coverage.result
  files = result.select { |path, _| path.start_with?(LIB_DIR) }

  line_total = line_hit = br_total = br_hit = 0
  rows = files.map do |path, data|
    lines = data[:lines].compact
    lt = lines.length
    lh = lines.count { |c| c.positive? }
    branches = (data[:branches] || {}).values.flat_map(&:values)
    bt = branches.length
    bh = branches.count(&:positive?)
    line_total += lt; line_hit += lh; br_total += bt; br_hit += bh
    [File.basename(path), lt, lh, bt, bh]
  end

  lpct = line_total.zero? ? 100.0 : (line_hit * 100.0 / line_total)
  bpct = br_total.zero? ? 100.0 : (br_hit * 100.0 / br_total)

  puts "\n== coverage (lib/flow_mcp) =="
  rows.sort_by { |r| r[0] }.each do |name, lt, lh, bt, bh|
    lp = lt.zero? ? 100.0 : lh * 100.0 / lt
    bp = bt.zero? ? 100.0 : bh * 100.0 / bt
    printf("  %-18s lines %3d/%-3d %5.1f%%   branches %3d/%-3d %5.1f%%\n", name, lh, lt, lp, bh, bt, bp)
  end
  printf("  %-18s lines %3d/%-3d %5.1f%%   branches %3d/%-3d %5.1f%%\n", "TOTAL", line_hit, line_total, lpct, br_hit, br_total, bpct)

  if lpct < LINE_MIN || bpct < BRANCH_MIN
    warn "coverage below floor (lines #{lpct.round(1)}%/min #{LINE_MIN}, branches #{bpct.round(1)}%/min #{BRANCH_MIN})"
    exit 1
  end
end

$LOAD_PATH.unshift(File.expand_path("../test", __dir__))
require "set"
Dir[File.expand_path("test_*.rb", __dir__)].sort.each { |f| require f }

#!/usr/bin/env bash
# layout-check.sh — programmatic layout pre-flight for the animated README figures.
# The machine catches HORIZONTAL TEXT OVERFLOW before a single GIF is ever assembled, so it is the
# FIRST step of every figure rebuild. It runs a generator into a throwaway dir, parses every <text>
# element it emits, estimates the rendered text width, and fails the moment any glyph extent crosses
# the SVG's own bounds. Deterministic, 0-GPU, pure bash + awk — no python, no rendering engine.
#
# Usage: bash layout-check.sh <path/to/build-*-frames.sh>
#   (generators take an output dir as $1 and emit f*.svg frames.)
#
# What it CATCHES:
#   • text whose left extent  < 0           (runs off the left edge)
#   • text whose right extent > svg width   (runs off the right edge)
#   Width is estimated as chars × font-size × 0.55; extent is derived from text-anchor
#   (start / middle / end). It understands single-line and multi-line <text>, several <text> on
#   one line, nested <tspan> (concatenated for the char count, parent x/anchor/font-size used),
#   both font-size="17" and font-size='17', and the handful of XML entities the generators use
#   (&amp; &lt; &gt; &#NNN; → one glyph each). It also adds the x-offset of the nearest enclosing
#   <g transform="translate(X …)"> so group-translated text (x="0" + anchor=middle) is measured at
#   its real position rather than flagged as a phantom left-overflow.
#
# What it does NOT catch (by design — these are the pixel reviewer's job, A1):
#   • OVERLAP / CROWDING between elements that the maths cannot see.
#   • CONTAINER overflow — a label crossing an inner box/pill it belongs to. Doing that generically
#     (mapping each text to "its" rect through arbitrary nesting) is unreliable; this tool implements
#     only the must-have SVG-bounds check. A glyph past the canvas edge is unambiguous; a glyph past
#     an inner box is left to human/visual review.
#   • the 0.55 width factor is an estimate; it can mildly over- or under-shoot a specific font. The
#     spec fixes the constant at 0.55 — it is NOT loosened to hide a real overflow.
set -euo pipefail

GEN="${1:-}"
[ -n "$GEN" ] || { echo "usage: bash layout-check.sh <generator.sh>" >&2; exit 2; }
[ -f "$GEN" ] || { echo "no generator: $GEN" >&2; exit 2; }

TMPDIR_LC="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_LC"' EXIT

# Run the generator into the temp dir (its stdout is noise — keep stderr for real failures).
if ! bash "$GEN" "$TMPDIR_LC" >/dev/null; then
  echo "generator failed: $GEN" >&2
  exit 2
fi

shopt -s nullglob
FRAMES=( "$TMPDIR_LC"/*.svg )
[ "${#FRAMES[@]}" -gt 0 ] || { echo "no svg frames emitted by $GEN" >&2; exit 2; }

# One awk pass per file. awk reads the whole file as a single record (RS set to a byte that does not
# occur) so multi-line <text> elements are handled. It walks <g transform="translate(…)"> /</g> to
# keep a translate-x offset stack, then measures every <text>…</text> against the svg width.
GEN_NAME="$(basename "$GEN")"

# Capture the text-element count (awk's stdout). Violations + the FIRST-violation line go to stderr,
# so they surface live; awk exits 7 on the first violation. Disable -e around the capture so we can
# read the exit status ourselves.
set +e
TEXTCOUNT="$(awk -v genname="$GEN_NAME" '
function decode(s,   out, n, m, ent) {
  # collapse all whitespace runs to a single space, trim
  gsub(/[ \t\r\n]+/, " ", s)
  sub(/^ /, "", s); sub(/ $/, "", s)
  # numeric entities &#NNN; and &#xHH; → one glyph each (best-effort: count as 1 char)
  while (match(s, /&#[xX]?[0-9A-Fa-f]+;/)) {
    s = substr(s, 1, RSTART-1) "\001" substr(s, RSTART+RLENGTH)
  }
  gsub(/&amp;/,  "\002", s)
  gsub(/&lt;/,   "\002", s)
  gsub(/&gt;/,   "\002", s)
  gsub(/&quot;/, "\002", s)
  gsub(/&apos;/, "\002", s)
  return s
}
function attr(tag, name,   re, v) {
  # match name="..." or name='...'
  re = name "=\"[^\"]*\""
  if (match(tag, re)) { v = substr(tag, RSTART, RLENGTH); sub(name "=\"", "", v); sub(/"$/, "", v); return v }
  re = name "='\''[^'\'']*'\''"
  if (match(tag, re)) { v = substr(tag, RSTART, RLENGTH); sub(name "='\''", "", v); sub(/'\''$/, "", v); return v }
  return ""
}
function num(s) { s = s + 0; return s }
BEGIN { RS = "\030" }   # read entire file as one record
{
  doc = $0
  file = FILENAME

  # ---- svg width: root <svg ... width="NNN"> else viewBox 3rd value ----
  svgw = 0
  if (match(doc, /<svg[^>]*>/)) {
    svgtag = substr(doc, RSTART, RLENGTH)
    w = attr(svgtag, "width")
    if (w != "") svgw = num(w)
    if (svgw <= 0) {
      vb = attr(svgtag, "viewBox")
      if (vb != "") { nvb = split(vb, a, /[ ,]+/); if (nvb >= 3) svgw = num(a[3]) }
    }
  }
  if (svgw <= 0) { printf("%s: WARN could not read svg width — skipping\n", file) > "/dev/stderr"; next }

  # ---- linear scan: track translate-x via <g transform="translate(X …)"> / </g> ; measure <text> ----
  depth = 0           # group nesting depth
  txoff = 0           # current accumulated translate-x
  delete offstack
  pos = 1
  L = length(doc)
  while (pos <= L) {
    lt = index(substr(doc, pos), "<")
    if (lt == 0) break
    pos += lt - 1
    rest = substr(doc, pos)

    if (substr(rest, 1, 2) == "<g") {
      gt = index(rest, ">")
      if (gt == 0) break
      gtag = substr(rest, 1, gt)
      depth++
      addx = 0
      if (match(gtag, /translate\([^)]*\)/)) {
        tr = substr(gtag, RSTART, RLENGTH)
        sub(/translate\(/, "", tr); sub(/\)/, "", tr)
        nt = split(tr, t, /[ ,]+/)
        if (nt >= 1) addx = num(t[1])
      }
      offstack[depth] = addx
      txoff += addx
      pos += gt
      continue
    }
    if (substr(rest, 1, 4) == "</g>") {
      if (depth > 0) { txoff -= offstack[depth]; depth-- }
      pos += 4
      continue
    }
    if (substr(rest, 1, 5) == "<text") {
      # opening tag up to first ">"
      ot = index(rest, ">")
      if (ot == 0) break
      opentag = substr(rest, 1, ot)
      # closing </text>
      ce = index(rest, "</text>")
      if (ce == 0) { pos += ot; continue }
      inner = substr(rest, ot + 1, ce - ot - 2)   # between > and <
      # strip any tspan tags, keep their text
      gsub(/<\/?tspan[^>]*>/, "", inner)
      # also strip any other inline child tags defensively
      gsub(/<[^>]*>/, "", inner)
      content = decode(inner)
      x = num(attr(opentag, "x"))
      anchor = attr(opentag, "text-anchor"); if (anchor == "") anchor = "start"
      fs = attr(opentag, "font-size"); if (fs == "") fs = "16"
      fsv = num(fs)
      nchars = length(content)
      tw = nchars * fsv * 0.55
      ax = x + txoff
      if (anchor == "middle")    { left = ax - tw/2; right = ax + tw/2 }
      else if (anchor == "end")  { left = ax - tw;   right = ax }
      else                       { left = ax;        right = ax + tw }

      total_text++
      summary = sprintf("text@x=%g anchor=%s fs=%g", x, anchor, fsv)
      snippet = content
      if (length(snippet) > 40) snippet = substr(snippet, 1, 40)
      tol = 2
      if (right > svgw + tol) {
        printf("%s:%s: \"%s…\" extends to x=%d > bound=%d\n", file, summary, snippet, int(right + 0.5), int(svgw)) > "/dev/stderr"
        exit 7
      }
      if (left < -tol) {
        printf("%s:%s: \"%s…\" extends to x=%d < 0\n", file, summary, snippet, int(left - 0.5)) > "/dev/stderr"
        exit 7
      }
      pos += ce + 6   # past "</text>"
      continue
    }
    # any other tag — skip past its "<"
    pos += 1
  }
}
END { print total_text + 0 }
' "${FRAMES[@]}" )"
status=$?
set -e

if [ "$status" -eq 7 ]; then
  exit 1
elif [ "$status" -ne 0 ]; then
  echo "layout-check: awk error ($status) on $GEN_NAME" >&2
  exit 2
fi

echo "layout-check OK: $GEN_NAME — ${#FRAMES[@]} frames, ${TEXTCOUNT:-0} text elements, 0 violations"
exit 0

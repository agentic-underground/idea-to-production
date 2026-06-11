#!/usr/bin/env bash
# layout-check.sh — programmatic layout & legibility pre-flight for the animated README figures.
# The machine catches LAYOUT defects before a single GIF is ever assembled, so it is the FIRST step
# of every figure rebuild. It runs a generator into a throwaway dir (or reads one finished .svg),
# parses every <text> element, estimates the rendered glyph extent, and fails the moment a label
# crosses the SVG's own bounds or would render illegibly small at GitHub's inline width.
# Deterministic, 0-GPU, pure bash + awk — no python, no rendering engine.
#
# Usage:
#   bash layout-check.sh <path/to/build-*-frames.sh>   # generator mode: runs it, globs f*.svg
#   bash layout-check.sh <path/to/figure.svg>          # standalone mode: checks ONE finished .svg
#                                                       #   (graphviz / mermaid / composition output)
#   (generators take an output dir as $1 and emit f*.svg frames.)
#
# Tunables (env-overridable; passed straight through to awk as -v):
#   INLINE_W=640  — the assumed GitHub inline render width in px (VSCode is narrower → stricter).
#   FLOOR=6       — the SHIPPED default min rendered text height in px at INLINE_W. This is the
#                   *corpus floor*: the smallest legible label in the house's own clean generators
#                   (mission-control's 13px caption → ~6.5px @640) must pass, while a genuinely
#                   illegible label (10px-in-2246 → ~2.85px) is caught. The plan's authored target
#                   is FLOOR=9 (the stricter VSCode-narrow goal) — reach it with -v / the env below
#                   once the corpus has been uplifted to clear it; locking it now would false-fail
#                   the very generators this gate guards. Corpus-validated, then locked (the plan's
#                   "configurable, corpus-validated before locking" decision).
#   Override:  INLINE_W=480 FLOOR=9 bash layout-check.sh <target>      # the stricter target
#
# What it CATCHES:
#   • HORIZONTAL overflow — text whose left extent < 0 or right extent > svg width (runs off an edge).
#     Width is estimated as chars × font-size × 0.55; extent is derived from text-anchor
#     (start / middle / end).
#   • VERTICAL overflow — text whose box (top ≈ y − fs·0.8, bottom ≈ y + fs·0.2) is clipped past the
#     top (top < 0) or bottom (bottom > svg height) of the canvas. This is what would have caught the
#     market-scanner DISCOVER label pushed off the canvas bottom.
#   • INLINE-LEGIBILITY (the "inline-legibility rule") — a label too small to read at GitHub's inline
#     width. The figure is authored large but rendered scaled-to-fit a ~640px column, so the real
#     on-screen height is  inline_h = font_size × INLINE_W / svg_width .  Fails when inline_h < FLOOR.
#     The masthead's big wordmark self-exempts (62px in a 1280px svg → ~31px, fine); value-flow's
#     10px label in a 2246px svg → ~2.85px is correctly caught.
#   • ASPECT advisory (SOFT — never the sole cause of a non-zero exit) — a figure wider than 2.4:1
#     renders tiny inline; warns once per file UNLESS the filename is a banner/masthead/hero/cycle
#     (those are intentionally wide and self-exempt). Advisory only; the per-text floor above still
#     runs on whitelisted files and is the real gate.
#
#   Inline-legibility sanity: masthead 62px-in-1280 → ~31px (pass); house body labels 13–17px-in-1280
#   → ~6.5–8.5px (pass at the shipped FLOOR=6); a crafted 10px-in-2246 label → ~2.85px (fail). At the
#   stricter target FLOOR=9 the house corpus is flagged for uplift — that is the gate doing its job,
#   which is why 9 is the goal and 6 is what ships until the corpus clears it.
#
# It understands single-line and multi-line <text>, several <text> on one line, nested <tspan>
# (concatenated for the char count, parent x/y/anchor/font-size used), both font-size="17" and
# font-size='17', the handful of XML entities the generators use (&amp; &lt; &gt; &#NNN; → one glyph
# each), and group transforms: it keeps a translate-X *and* translate-Y offset stack from the nearest
# enclosing <g transform="translate(X, Y …)"> so group-translated text is measured at its real
# position rather than flagged as a phantom edge-overflow.
#
# What it does NOT catch (by design — these are the raster-lint tier's + the pixel reviewer's job, A1):
#   • OVERLAP / CROWDING / OCCLUSION between elements — a label sitting on another label, a thin line
#     crossing a glyph cluster, text hidden behind a z-ordered shape. The maths sees positions, not
#     pixels; these are raster-lint heuristics + the reviewer's vision.
#   • CONTAINER overflow — a label crossing an inner box/pill it belongs to (mapping each text to "its"
#     rect through arbitrary nesting is unreliable). A glyph past the *canvas* edge is unambiguous and
#     IS caught; a glyph past an inner box is left to visual review.
#   • INLINE-LEGIBILITY of a FLAT PNG with no SVG source — with no <text> to read the font-size from,
#     the math tier is blind. That is exactly the raster-lint tier + the reviewer's vision.
#   • the 0.55 width factor is an estimate; it can mildly over- or under-shoot a specific font. The
#     spec fixes the constant at 0.55 — it is NOT loosened to hide a real overflow.
#
# Exit codes:
#   0  clean — no violations (aspect WARN lines do not change this)
#   1  a VIOLATION was found (horizontal OR vertical overflow OR inline-legibility floor breach)
#   2  usage / setup error (bad args, generator failed, no frames, awk error)
set -euo pipefail

# Tunables — env-overridable, passed through to awk as -v.
INLINE_W="${INLINE_W:-640}"
FLOOR="${FLOOR:-6}"   # corpus floor (ships); FLOOR=9 is the stricter VSCode-narrow target (see header)

ARG="${1:-}"
[ -n "$ARG" ] || { echo "usage: bash layout-check.sh <generator.sh | figure.svg>" >&2; exit 2; }

# ---- Standalone .svg mode: if $1 is a finished .svg file, check it directly (skip the generator). ----
TMPDIR_LC=""
case "$ARG" in
  *.svg)
    [ -f "$ARG" ] || { echo "no svg: $ARG" >&2; exit 2; }
    FRAMES=( "$ARG" )
    GEN_NAME="$(basename "$ARG")"
    ;;
  *)
    # ---- Generator mode: run the generator into a temp dir and glob its frames. ----
    GEN="$ARG"
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
    GEN_NAME="$(basename "$GEN")"
    ;;
esac

# One awk pass per file. awk reads the whole file as a single record (RS set to a byte that does not
# occur) so multi-line <text> elements are handled. It walks <g transform="translate(…)"> /</g> to
# keep translate-x AND translate-y offset stacks, then measures every <text>…</text> against the svg
# width (horizontal + inline-legibility) and the svg height (vertical), with a soft aspect advisory.

# Capture the text-element count (awk's stdout). Violations + the FIRST-violation line go to stderr,
# so they surface live; awk exits 7 on the first violation. Disable -e around the capture so we can
# read the exit status ourselves.
set +e
TEXTCOUNT="$(awk -v genname="$GEN_NAME" -v INLINE_W="$INLINE_W" -v FLOOR="$FLOOR" '
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
  # ---- svg height: root <svg ... height="NNN"> else viewBox 4th value ----
  svgw = 0; svgh = 0
  if (match(doc, /<svg[^>]*>/)) {
    svgtag = substr(doc, RSTART, RLENGTH)
    w = attr(svgtag, "width")
    if (w != "") svgw = num(w)
    h = attr(svgtag, "height")
    if (h != "") svgh = num(h)
    if (svgw <= 0 || svgh <= 0) {
      vb = attr(svgtag, "viewBox")
      if (vb != "") {
        nvb = split(vb, a, /[ ,]+/)
        if (svgw <= 0 && nvb >= 3) svgw = num(a[3])
        if (svgh <= 0 && nvb >= 4) svgh = num(a[4])
      }
    }
  }
  if (svgw <= 0) { printf("%s: WARN could not read svg width — skipping\n", file) > "/dev/stderr"; next }
  if (svgh <= 0) { printf("%s: WARN could not read svg height — vertical check skipped\n", file) > "/dev/stderr" }

  # ---- aspect advisory (SOFT, once per file): wide figures render tiny inline. ----
  # Self-exempt intentionally-wide classes by filename: banner / masthead / hero / cycle.
  if (svgh > 0) {
    ar = svgw / svgh
    if (ar > 2.4 && file !~ /(banner|masthead|hero|cycle)/) {
      printf("%s: WARN aspect %.2f:1 > 2.4 advisory (wide — verify inline legibility)\n", file, ar) > "/dev/stderr"
    }
  }

  # ---- linear scan: track translate-x/-y via <g transform="translate(X, Y …)"> / </g> ;
  #      measure every <text> for horizontal bounds, vertical bounds, and inline legibility. ----
  depth = 0           # group nesting depth
  txoff = 0           # current accumulated translate-x
  tyoff = 0           # current accumulated translate-y
  delete offstack     # per-depth translate-x to undo on </g>
  delete offstacky    # per-depth translate-y to undo on </g>
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
      addx = 0; addy = 0
      if (match(gtag, /translate\([^)]*\)/)) {
        tr = substr(gtag, RSTART, RLENGTH)
        sub(/translate\(/, "", tr); sub(/\)/, "", tr)
        nt = split(tr, t, /[ ,]+/)
        if (nt >= 1) addx = num(t[1])
        if (nt >= 2) addy = num(t[2])
      }
      offstack[depth]  = addx
      offstacky[depth] = addy
      txoff += addx
      tyoff += addy
      pos += gt
      continue
    }
    if (substr(rest, 1, 4) == "</g>") {
      if (depth > 0) { txoff -= offstack[depth]; tyoff -= offstacky[depth]; depth-- }
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
      y = num(attr(opentag, "y"))
      anchor = attr(opentag, "text-anchor"); if (anchor == "") anchor = "start"
      fs = attr(opentag, "font-size"); if (fs == "") fs = "16"
      fsv = num(fs)
      nchars = length(content)
      tw = nchars * fsv * 0.55
      ax = x + txoff
      ay = y + tyoff
      if (anchor == "middle")    { left = ax - tw/2; right = ax + tw/2 }
      else if (anchor == "end")  { left = ax - tw;   right = ax }
      else                       { left = ax;        right = ax + tw }

      total_text++
      summary = sprintf("text@x=%g y=%g anchor=%s fs=%g", x, y, anchor, fsv)
      snippet = content
      if (length(snippet) > 40) snippet = substr(snippet, 1, 40)
      tol = 2

      # ---- horizontal bounds ----
      if (right > svgw + tol) {
        printf("%s:%s: \"%s…\" extends to x=%d > bound=%d\n", file, summary, snippet, int(right + 0.5), int(svgw)) > "/dev/stderr"
        exit 7
      }
      if (left < -tol) {
        printf("%s:%s: \"%s…\" extends to x=%d < 0\n", file, summary, snippet, int(left - 0.5)) > "/dev/stderr"
        exit 7
      }

      # ---- vertical bounds (skip if height unknown) ----
      if (svgh > 0) {
        top = ay - fsv * 0.8
        bot = ay + fsv * 0.2
        if (bot > svgh + tol) {
          printf("%s:%s: \"%s…\" extends to y=%d > H=%d (clipped at bottom)\n", file, summary, snippet, int(bot + 0.5), int(svgh)) > "/dev/stderr"
          exit 7
        }
        if (top < -tol) {
          printf("%s:%s: \"%s…\" extends to y=%d < 0 (clipped at top)\n", file, summary, snippet, int(top - 0.5)) > "/dev/stderr"
          exit 7
        }
      }

      # ---- inline legibility: rendered height at the inline column width ----
      if (fsv > 0) {
        inline_h = fsv * INLINE_W / svgw
        if (inline_h < FLOOR) {
          printf("%s:%s: \"%s…\" renders ~%.1fpx at %dpx inline width (< %d px floor)\n", file, summary, snippet, inline_h, INLINE_W, FLOOR) > "/dev/stderr"
          exit 7
        }
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

echo "layout-check OK: $GEN_NAME — ${#FRAMES[@]} frame(s), ${TEXTCOUNT:-0} text elements, 0 violations (horizontal + vertical bounds + inline-legibility @ ${INLINE_W}px/${FLOOR}px floor; aspect advisory)"
exit 0

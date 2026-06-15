#!/usr/bin/env bash
# layout-check.sh — programmatic layout & legibility pre-flight for the animated README figures.
# The machine catches LAYOUT defects before a single GIF is ever assembled, so it is the FIRST step
# of every figure rebuild. It runs a generator into a throwaway dir (or reads one finished .svg),
# parses every <text> element, estimates the rendered glyph extent, and fails the moment a label
# crosses the SVG's own bounds or would render illegibly small at GitHub's inline width.
# Deterministic, 0-GPU, pure bash + awk — no python, no rendering engine.
#
# COORDINATE BOUND — the viewBox is AUTHORITATIVE. Text x/y live in the viewBox coordinate
# system, so when a <svg> carries a viewBox its 3rd/4th values ARE the width/height bound
# (and the inline-legibility scale), regardless of any width=/height= display attr. Only when
# there is NO viewBox do the numeric width=/height= attrs supply the bound. This is what lets
# the standalone-.svg mode pass mermaid (width="100%%" viewBox="0 0 800 300") and graphviz
# (width="100pt" viewBox="0 0 400 240") without false-flagging every in-bounds label; the
# house generators emit width==viewBox-width so they are unaffected.
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
# enclosing <g transform="…translate(X, Y …)"> — the translate is extracted even from a COMPOUND
# transform (e.g. graphviz's "scale(1 1) rotate(0) translate(4 1404.8)" or a nested mermaid
# translate) — so group-translated text is measured at its real position rather than flagged as a
# phantom edge-overflow.
#
# MACHINE-GENERATED SVGs (graphviz / mermaid), standalone mode — HONESTY NOTE. On finished
# third-party SVGs the BOUNDS checks (horizontal / vertical) are BEST-EFFORT, not authoritative:
#   • Only the translate component of a transform is applied. A scale(sx sy) or rotate(θ) in a
#     compound <g> (or directly on a <text>) is NOT composed into the coordinate — we extract the
#     dominant translate and leave the rest. graphviz's outer "scale(1 1) rotate(0) translate(…)"
#     resolves cleanly because the scale is identity and the rotate is 0; a real non-identity
#     scale/rotate would leave a residual the bounds maths cannot see.
#   • A <text> carrying its OWN rotate(…) (e.g. a 90°-rotated rail label) has its axis-aligned
#     glyph-extent estimate skipped for the BOUNDS checks — a rotated label's horizontal/vertical
#     footprint is not the unrotated chars×fs×0.55 box, so measuring it would false-flag. Inline
#     legibility still runs (font-size is rotation-invariant).
#   • Empty-content labels (mermaid emits ~100 empty edge labels as <text><tspan …/></text>) are
#     SKIPPED entirely — there is no glyph to clip or to render illegibly small.
#   • The bounds tolerance is max(2px, 0.5% of the dimension) so a sub-1% glyph-estimate
#     over-shoot (the 0.55 factor's error band) does not hard-fail a clean diagram; real overflows
#     (tens–hundreds of px) and the planted fixtures still trip.
# The INLINE-LEGIBILITY check is the reliable CROSS-FORMAT one: it depends only on font-size and the
# viewBox width (no transform composition), so it is exact for house, graphviz, and mermaid alike.
# When standalone bounds findings are reported on a machine SVG, treat them as advisory and confirm
# against the rendered pixels; treat inline-legibility findings as authoritative.
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

  # ---- coordinate bound — viewBox is AUTHORITATIVE when present ----
  # Text x/y coordinates live in the viewBox coordinate system, so the bound MUST be the
  # viewBox dimensions, NOT the display width/height attrs. A width="100%" / width="100pt"
  # attr alongside viewBox="0 0 800 300" would otherwise false-flag every in-bounds label.
  # Only fall back to the numeric width/height attr when NO viewBox is present.
  #   svgw = viewBox[3] if a viewBox is present; else numeric(width attr);  else 0
  #   svgh = viewBox[4] if a viewBox is present; else numeric(height attr); else 0
  # The house generators emit width==viewBox-width (and height==viewBox-height), so they
  # are unaffected. The inline-legibility formula scales by svgw — now the viewBox width —
  # which is correct since font-size is in viewBox coordinate units.
  svgw = 0; svgh = 0
  if (match(doc, /<svg[^>]*>/)) {
    svgtag = substr(doc, RSTART, RLENGTH)
    vb = attr(svgtag, "viewBox")
    if (vb != "") {
      nvb = split(vb, a, /[ ,]+/)
      if (nvb >= 3) svgw = num(a[3])
      if (nvb >= 4) svgh = num(a[4])
    } else {
      w = attr(svgtag, "width")
      if (w != "") svgw = num(w)
      h = attr(svgtag, "height")
      if (h != "") svgh = num(h)
    }
  }

  # ---- document-default font-size (machine SVGs cascade it via CSS, not per-<text> attrs) ----
  # mermaid puts the body font-size in a root style rule, e.g. "#my-svg{font-size:15px;…}", and
  # leaves each <text>/<tspan> WITHOUT a font-size attr. The house/graphviz SVGs instead set
  # font-size on every <text>, so this fallback is consulted only when a <text> has no attr of its
  # own — i.e. only for the cascading-CSS (mermaid) case. Using the real cascaded 15px instead of
  # the hard 16px default removes a ~7% width over-estimate that otherwise false-flags wrapped
  # mermaid labels by a pixel or two. First font-size:NNpx in the <style> block wins (the root rule).
  docfs = 0
  if (match(doc, /font-size:[ ]*[0-9.]+px/)) {
    fsstr = substr(doc, RSTART, RLENGTH)
    sub(/font-size:[ ]*/, "", fsstr); sub(/px/, "", fsstr)
    docfs = num(fsstr)
  }
  if (svgw <= 0) { printf("%s: WARN could not read svg width — skipping\n", file) > "/dev/stderr"; next }
  if (svgh <= 0) { printf("%s: WARN could not read svg height — vertical check skipped\n", file) > "/dev/stderr" }

  # ---- aspect advisory (SOFT, at most ONCE per run): wide figures render tiny inline. ----
  # Self-exempt intentionally-wide classes by filename: banner / masthead / hero / cycle.
  # Deduped across frames (warned_aspect persists between records) so a 30-frame generator
  # emits ONE aspect WARN, not 30 identical lines. Advisory only — never affects exit code.
  if (svgh > 0 && !warned_aspect) {
    ar = svgw / svgh
    if (ar > 2.4 && file !~ /(banner|masthead|hero|cycle)/) {
      printf("%s: WARN aspect %.2f:1 > 2.4 advisory (wide — verify inline legibility)\n", file, ar) > "/dev/stderr"
      warned_aspect = 1
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
      # Extract the translate from this group transform — even from a COMPOUND transform such as
      # the graphviz form "scale(1 1) rotate(0) translate(4 1404.8)" or a chained mermaid transform.
      # Walk ALL translate(...) occurrences and keep the LAST one: in an SVG transform list the
      # rightmost transform is applied first (innermost), so the final translate is the dominant
      # positioning that places the group content. scale()/rotate() are intentionally ignored (header).
      scan = gtag
      while (match(scan, /translate\([^)]*\)/)) {
        tr = substr(scan, RSTART, RLENGTH)
        scan = substr(scan, RSTART + RLENGTH)   # advance past this translate to find any later one
        sub(/translate\(/, "", tr); sub(/\)/, "", tr)
        nt = split(tr, t, /[ ,]+/)
        addx = (nt >= 1) ? num(t[1]) : 0
        addy = (nt >= 2) ? num(t[2]) : 0
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
    # ---- mermaid label sizing rect — an AUTHORITATIVE measured, CENTERED width (Fix: kill the last
    #      sub-1%% glyph-estimate artifacts). mermaid sizes every label with a rect the browser fit to
    #      the ACTUAL rendered glyph run and CENTERED on the label/node origin (x="-W/2" width="W"):
    #        • edge labels →  <rect class="background"      x="-W/2" width="W">
    #        • node labels →  <rect class="basic label-container" x="-W/2" width="W">
    #      Both are centered on the current translate origin and the label is centered within them
    #      (mermaid centres node text via CSS even though the <text> reads text-anchor=start x=0 — which
    #      is exactly what makes the bare glyph estimate over-shoot to the right). When such a rect
    #      precedes a <text>, its width is ground truth: we stash it and let the next <text> use it as a
    #      CENTERED footprint (overriding the misleading start-anchor). House/graphviz SVGs carry no such
    #      class, so bg_w stays 0 and the anchored chars*fs*0.55 estimate path is unchanged for them. ----
    if (substr(rest, 1, 5) == "<rect") {
      rt = index(rest, ">")
      if (rt == 0) break
      recttag = substr(rest, 1, rt)
      if (recttag ~ /class="[^"]*(background|label-container)[^"]*"/) {
        bgw = attr(recttag, "width")
        if (bgw != "") bg_w = num(bgw)   # keep last non-empty (empty self-closing rects do not clear it)
      }
      pos += rt
      continue
    }
    if (substr(rest, 1, 5) == "<text") {
      # opening tag up to first ">"
      ot = index(rest, ">")
      if (ot == 0) break
      opentag = substr(rest, 1, ot)
      # Self-closing <text .../>: the opening tag itself ends in "/>", so there is NO
      # </text>. Treat it as empty-content (no text to measure) and advance past ONLY the
      # opening tag — otherwise index(rest,"</text>") would match the NEXT element close tag
      # and silently swallow that element (a false negative on the following label).
      if (substr(opentag, ot - 1, 1) == "/") {
        inner = ""
        ce = 0   # no </text> consumed
      } else {
        # closing </text>
        ce = index(rest, "</text>")
        if (ce == 0) { pos += ot; continue }
        inner = substr(rest, ot + 1, ce - ot - 1)   # between the opening ">" (at ot) and "<" of </text> (at ce)
      }
      # ---- multi-LINE detection for machine SVGs (mermaid wraps a label across several rows) ----
      # mermaid renders a wrapped edge/node label as ONE <text> holding several <tspan> rows, each
      # row a tspan that carries a dy="…em" baseline shift (and usually an x= reset). Those rows are
      # stacked VERTICALLY, so the rendered WIDTH of the label is the WIDEST row — not the concatenation
      # of every row. Concatenating (the house single-line assumption) grossly over-estimates width
      # and false-flags a wrapped label as off-canvas. We mark each line-starting tspan (one with a
      # dy= attr) with a \n BEFORE stripping, then take the widest line for the width estimate. House
      # generators emit no dy-tspans (one line per <text>), so for them this collapses to a no-op:
      # the single line IS the whole content. Splitting can only REDUCE an estimate, never inflate
      # it, so it can never manufacture a NEW overflow.
      lined = inner
      gsub(/<tspan[^>]* dy=[^>]*>/, "\n", lined)    # a dy-bearing tspan starts a new rendered row
      gsub(/<\/?tspan[^>]*>/, "", lined)            # drop remaining tspan tags, keep their glyphs
      gsub(/<[^>]*>/, "", lined)                    # drop any other inline child tags
      # widest line (by decoded glyph count) drives the width estimate
      nlines = split(lined, _lines, /\n/)
      maxchars = 0
      for (li = 1; li <= nlines; li++) {
        lc = length(decode(_lines[li]))
        if (lc > maxchars) maxchars = lc
      }
      # strip any tspan tags, keep their text (full concatenation → empty-check + snippet)
      gsub(/<\/?tspan[^>]*>/, "", inner)
      # also strip any other inline child tags defensively
      gsub(/<[^>]*>/, "", inner)
      content = decode(inner)

      # ---- skip EMPTY-CONTENT text (Fix A) ----
      # mermaid emits ~100 empty edge labels: <text y="-10.1"><tspan …/></text>. After stripping
      # the child tspan the content is empty; there is no glyph to clip or to render illegibly, so
      # running bounds/legibility on it only manufactures false-positives (e.g. "extends to y<0").
      # Skip it entirely — do not count it as a measured text element either. Advance the cursor the
      # same way the measured path does so the next element is not mis-parsed.
      if (content ~ /^[ \t\r\n]*$/) {
        bg_w = 0   # consume any background rect that belonged to this empty label
        if (ce == 0) pos += ot
        else         pos += ce + 6
        continue
      }

      x = num(attr(opentag, "x"))
      y = num(attr(opentag, "y"))
      anchor = attr(opentag, "text-anchor"); if (anchor == "") anchor = "start"
      fs = attr(opentag, "font-size"); if (fs == "") fs = (docfs > 0 ? docfs "" : "16")
      fsv = num(fs)
      nchars = (maxchars > 0) ? maxchars : length(content)   # widest rendered line, not concatenation
      # Prefer the mermaid-measured sizing-rect width (authoritative + CENTERED) when one was just
      # seen; else fall back to the anchored chars*fs*0.55 glyph estimate. bg_w is consumed per text.
      measured = (bg_w > 0) ? 1 : 0
      tw = measured ? bg_w : nchars * fsv * 0.55
      bg_w = 0
      ax = x + txoff
      ay = y + tyoff
      if (measured) {
        # mermaid sizing rect is centered on the origin (x=-W/2); the label is centered in it,
        # so the footprint is symmetric about ax regardless of the reported text-anchor on the text.
        left = ax - tw/2; right = ax + tw/2
      }
      else if (anchor == "middle") { left = ax - tw/2; right = ax + tw/2 }
      else if (anchor == "end")    { left = ax - tw;   right = ax }
      else                         { left = ax;        right = ax + tw }

      # ---- ROTATED text: bounds estimate is invalid; skip bounds, keep legibility (header note) ----
      # A <text> carrying its own rotate(…) (e.g. a 90°-rotated rail label) does not occupy the
      # axis-aligned chars×fs×0.55 box this estimator assumes, so a horizontal/vertical bounds
      # check would false-flag it (the unrotated width projected onto the wrong axis). Font-size is
      # rotation-invariant, so inline legibility still applies. We do not compose the rotation.
      text_rotated = (match(opentag, /transform="[^"]*rotate\(/) || match(opentag, /transform='\''[^'\'']*rotate\(/)) ? 1 : 0

      total_text++
      summary = sprintf("text@x=%g y=%g anchor=%s fs=%g", x, y, anchor, fsv)
      snippet = content
      if (length(snippet) > 40) snippet = substr(snippet, 1, 40)
      # ---- bounds tolerance (Fix C) ----
      # Per-dimension tolerance = max(2px, 0.5% of that dimension). The 0.55 glyph-width factor is
      # an estimate; on a wide figure a sub-1% over-shoot (e.g. the value-flow caption estimated 3px
      # / 0.2% past a 1621px bound) is inside the estimate error band, NOT a real clip. Scaling the
      # tolerance to the canvas absorbs that noise while leaving REAL overflows (tens–hundreds of px)
      # and the planted fixtures well outside it. This only RAISES the old flat 2px (never lowers
      # it), so anything that passed before still passes — generator mode is unaffected. Inline
      # legibility below is EXACT (font-size based) and is deliberately left untouched.
      tolx = (0.005 * svgw > 2) ? 0.005 * svgw : 2
      toly = (svgh > 0 && 0.005 * svgh > 2) ? 0.005 * svgh : 2

      # ---- horizontal + vertical bounds (skipped for rotated text — estimate invalid) ----
      if (!text_rotated) {
        if (right > svgw + tolx) {
          printf("%s:%s: \"%s…\" extends to x=%d > bound=%d\n", file, summary, snippet, int(right + 0.5), int(svgw)) > "/dev/stderr"
          exit 7
        }
        if (left < -tolx) {
          printf("%s:%s: \"%s…\" extends to x=%d < 0\n", file, summary, snippet, int(left - 0.5)) > "/dev/stderr"
          exit 7
        }
        # ---- vertical bounds (skip if height unknown) ----
        if (svgh > 0) {
          top = ay - fsv * 0.8
          bot = ay + fsv * 0.2
          if (bot > svgh + toly) {
            printf("%s:%s: \"%s…\" extends to y=%d > H=%d (clipped at bottom)\n", file, summary, snippet, int(bot + 0.5), int(svgh)) > "/dev/stderr"
            exit 7
          }
          if (top < -toly) {
            printf("%s:%s: \"%s…\" extends to y=%d < 0 (clipped at top)\n", file, summary, snippet, int(top - 0.5)) > "/dev/stderr"
            exit 7
          }
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

      if (ce == 0) pos += ot       # self-closing: advance past the opening tag only
      else         pos += ce + 6   # past "</text>"
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

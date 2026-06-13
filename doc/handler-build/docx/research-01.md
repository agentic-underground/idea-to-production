# Pandoc Markdown→DOCX Handler Research

## Reference Document (`--reference-doc`) Templating

**Best Practice**: Use pandoc-generated reference.docx as the base template, modify only styles in Word/LibreOffice, never alter content structure.

- **Extraction**: `pandoc -o custom-reference.docx --print-default-data-file reference.docx`
- **How it works**: Reference docx is stripped of content; only stylesheets, margins, page size, headers, footers are retained and applied to output
- **Critical limitation**: Contents of reference docx are ignored entirely—only metadata & formatting preserved
- **Canonical source**: https://pandoc.org/MANUAL.html (section: `--reference-doc`)

## Paragraph Styles (Customizable in reference.docx)

Pandoc reads these styles from reference template; all should exist for consistent output:
- Normal, Body Text, First Paragraph, Compact, Title, Subtitle, Author, Date, Abstract, AbstractTitle
- Bibliography, Heading 1–9, Block Text, Footnote Block Text, Source Code, Footnote Text
- Definition Term, Definition, Caption, Table Caption, Image Caption, Figure, Captioned Figure, TOC Heading

**Note**: Missing styles fallback to defaults; Word will warn on first open if any are undefined.

## Character Styles (Inline Formatting)

- Default Paragraph Font, Verbatim Char, Footnote Reference, Hyperlink, Section Number
- These control inline formatting and must be defined for docx to apply them without error

## Table Style

- **Table**: Single table style; all tables use this—limited control per-table in current pandoc (v3.10)

## Metadata & Front Matter

- **YAML metadata block** (enabled by default for markdown):
  ```yaml
  ---
  title: "My Document"
  author: "Author Name"
  date: "2025-06-13"
  ---
  ```
- **Pandoc title block** (legacy, still supported):
  ```
  % Title
  % Author
  % Date
  ```
- **YAML metadata via file**: `--metadata-file FILE` (parsed as YAML or JSON; supports multiple `--metadata-file` calls; later values override earlier)
- **Inline metadata**: `--metadata KEY=VALUE` or `-M KEY=VALUE` (escapes values when inserted into template)
- **Metadata accessibility**: Values accessible to Lua filters and some output formats (including docx document properties)

## Markdown→DOCX Feature Support

- **Headings**: Full support (h1–h9 mapped to Heading 1–9 styles)
- **Tables**: Supported (simple to complex), including captions; styles from "Table" style in reference.docx
- **Images**: Supported (inline & with captions via Figure/Captioned Figure styles); relative paths resolved at conversion time
- **Links**: Supported; hyperlinks use "Hyperlink" character style
- **Code blocks**: Highlighted if `--highlight` option used; mapped to "Source Code" paragraph style
- **Footnotes & endnotes**: Supported; use "Footnote Text" style
- **Lists** (ordered/unordered): Full support; nested lists preserved
- **Block quotes**: Mapped to "Block Text" paragraph style
- **Emphasis** (italic/bold): Supported; uses character styles
- **Definition lists**: Supported via "Definition Term" and "Definition" styles

## Known Limitations & Common Failure Modes

1. **No column widths in tables**: Tables span full page width; individual column sizing requires post-processing in Word
2. **Images without alt text**: If markdown image lacks alt, docx image lacks alt (accessibility issue)
3. **Complex nested structures**: Deeply nested lists or block quotes may flatten or lose nesting in edge cases
4. **Track Changes**: `--track-changes=all` reads MS Word Track Changes from input docx; docx writer does not generate Track Changes
5. **Custom color/font attributes**: Markdown has no syntax for per-element colors; custom styling requires reference.docx tweaks or post-processing
6. **Header/footer content**: Headers/footers defined in reference docx apply globally; no per-section header control in markdown
7. **Section breaks**: `--section-divs` (for docx output) adds section breaks before headings when enabled; behavior depends on reference docx structure

## Testing & Validation

- **Baseline test**: Convert simple markdown (headings, text, table, image, list) with default reference.docx:
  ```bash
  pandoc input.md -o output.docx
  ```
- **Custom reference test**: Create custom-reference.docx, apply to conversion:
  ```bash
  pandoc -o custom-reference.docx --print-default-data-file reference.docx
  # (edit custom-reference.docx in Word to change styles)
  pandoc input.md --reference-doc custom-reference.docx -o output.docx
  ```
- **Metadata test**: Verify YAML front matter appears in Word document properties:
  ```bash
  pandoc --metadata-file meta.yaml input.md -o output.docx
  ```
- **Validation**: Open output.docx in Word, check:
  - Styles applied match reference (use Styles pane: Ctrl+Alt+Shift+S on Windows)
  - Tables/images render correctly
  - Document properties (File > Info) show metadata
  - No corrupted or missing elements

## Canonical Versioning & Resources

- **Current stable**: Pandoc v3.10 (as of June 2025)
- **Manual**: https://pandoc.org/MANUAL.html
- **GitHub**: https://github.com/jgm/pandoc/releases
- **Default templates**: https://github.com/jgm/pandoc-templates

## Handler Build Considerations

1. **Pipeline**: markdown + metadata YAML + reference.docx → pandoc → .docx output
2. **Error surface**: Reference docx corruption, missing styles, malformed metadata YAML
3. **Customization depth**: Style tweaking possible in Word, but structural complexity (columns, complex layouts) requires post-processing or custom writer
4. **Automation**: Validate reference.docx integrity before each conversion; consider pre-check for required style names
5. **Asset management**: Ensure relative image paths resolve; consider embedding images if distribution portability is required

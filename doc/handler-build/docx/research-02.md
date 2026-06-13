# Research Axis 2: python-docx Fine Control & Accessibility

## python-docx Capabilities & Coverage

### Supported Features
- **Styles & Headings**: Full paragraph and character style support; apply predefined styles (Heading 1-9, Normal, etc.)
- **Tables**: Complete API for rows, columns, cells with configurable formatting
- **Headers/Footers**: Dedicated `_Header` and `_Footer` objects via document sections
- **Core Properties (Metadata)**: `CoreProperties` API for title, author, subject, keywords, comments
- **Images**: `add_picture(path/stream, width, height)` method with pixel/inch units
- **Document-level Access**: Direct manipulation of XML via underlying `oxml` layer for advanced control

### Critical Limitation: Alt Text
**Alt text for images is NOT natively exposed in python-docx API** (v0.8.11+). The `add_picture()` method lacks alt text parameters. **Workaround**: Drop to `python-docx.oxml` to set `<wp:docPr descr="">` or `<a:blip><a:alphaModFix>` attributes directly via raw XML access.

**Source**: https://python-docx.readthedocs.io/en/latest/api/document.html

---

## When to Use python-docx vs Pandoc

### Use **python-docx** when:
- Fine-grained control over styles, table structure, headers/footers required
- Dynamic document generation (API-driven, data-driven tables)
- Metadata and core properties must be set programmatically
- Incremental document assembly (add sections, run Python logic between elements)

### Use **Pandoc** when:
- Converting from markdown/RST/HTML source formats to DOCX
- Template-based styling via `--reference-doc` (external .docx template preservation)
- Batch document conversion with uniform styling
- Metadata from YAML front matter
- **Strength**: Pandoc's reference-doc system applies stylesheets without code; python-docx requires programmatic style assignment

**Note**: Pandoc does NOT expose alt text configuration in DOCX output (per manual); accessibility must be post-processed.

**Source**: https://pandoc.org/MANUAL.html

---

## WCAG 2.1 Accessibility Requirements for Documents

### Heading Structure (1.3.1 Info and Relationships)
- Use semantic heading levels (Heading 1 → H1, Heading 2 → H2, etc.)
- Establish logical hierarchy; avoid skipping levels
- Screen reader users navigate via heading outline
- **python-docx**: Use `document.add_heading(text, level=1)` or apply Heading N styles

### Alt Text (1.1.1 Non-text Content)
- All images must have programmatic alt text (not just caption or surrounding text)
- Alt text must convey purpose/content equivalently
- **python-docx gap**: No built-in API; requires raw XML manipulation or external tool
- **Word XML structure**: Alt text lives in `<wp:docPr descr="...">` (drawing properties)

### Table Headers (1.3.1 Info and Relationships)
- First row must be marked as header row semantically
- Header cells must use `<w:tblHeader>` property (OOXML)
- **python-docx**: No explicit table header markup API; set manually via `oxml` or post-process

**Source**: https://www.w3.org/WAI/WCAG21/quickref/

---

## Testing & Validation Strategy

### Automated Checks
1. **Microsoft Word Accessibility Checker** (built-in): Open generated .docx in Word, run Review → Check Accessibility
2. **Axe for PDF** (plugin): Some variants test OOXML; verify heading/alt-text detection
3. **PAC3 (PDF Accessibility Checker)**: Can analyze exported PDFs from DOCX for accessibility fallback

### Manual Verification
- Open DOCX in screen reader (NVDA, JAWS) and verify:
  - Heading navigation works (Tab key jumps by headings)
  - Alt text reads for images
  - Table headers are announced as header row
- Inspect raw DOCX XML: Unzip `.docx` (rename to `.zip`), inspect `word/document.xml` for:
  - `<w:pStyle w:val="Heading1">` on heading paragraphs
  - `<wp:docPr descr="...">` on images
  - `<w:tblHeader/>` in `<w:trPr>` of table header rows

### Common Failure Modes
- **Alt text missing entirely**: No `<wp:docPr descr="">` attribute
- **Heading hierarchy broken**: Jumping from Heading 1 to Heading 3 (no H2)
- **Tables not marked as header row**: No `<w:tblHeader/>` in first row; screen reader reads as data
- **Metadata not set**: No `<cp:title>` in core.xml; document title defaults to filename
- **Embedded fonts not licensed**: Custom fonts may not render on target systems

---

## Canonical Tooling & Versions

| Tool | Version | Use Case | Notes |
|------|---------|----------|-------|
| python-docx | 0.8.11+ | Fine control, dynamic generation | No native alt text; use oxml for advanced |
| Pandoc | 2.19+ | Format conversion, templating | Reference-doc system excellent for styling |
| python-pptx | 0.6.21+ | Sister library (presentations) | Similar architecture; also lacks alt-text API |
| lxml | Latest | Direct OOXML manipulation | Required for `python-docx.oxml` access |
| openpyxl | 3.10+ | Excel/spreadsheet alternative | OOXML same family; similar accessibility gaps |

---

## Implementation Patterns

### Alt Text Workaround (python-docx)
```python
from docx import Document
from docx.oxml import OxmlElement

doc = Document()
picture = doc.add_picture('image.png')
# Access underlying shape
shape = picture._element
# Find drawing properties and set alt text
docPr = shape.find('.//{http://schemas.openxmlformats.org/drawingml/2006/main}docPr')
if docPr is not None:
    docPr.set('descr', 'Alt text here')
```

### Table Header Markup (python-docx)
```python
table = doc.add_table(rows=2, cols=3)
# Mark first row as header
header_cells = table.rows[0].cells
for cell in header_cells:
    tcPr = cell._element.get_or_add_tcPr()
    tcHeader = OxmlElement('w:tblHeader')
    tcPr.append(tcHeader)
```

---

## Sources
- https://python-docx.readthedocs.io/en/latest/ — Official docs
- https://pandoc.org/MANUAL.html — Pandoc reference guide
- https://www.w3.org/WAI/WCAG21/quickref/ — WCAG 2.1 requirements
- https://github.com/python-openxml/python-docx — Issue tracker; 368+ open issues

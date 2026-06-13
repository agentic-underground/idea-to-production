# DOCX Handler Knowledge Wall

Raw material for the agent-author building the `.docx document production` value-handler.
Synthesised from three haiku research files; contradictions resolved inline; thin spots flagged.

---

## Prime Directives (non-negotiable)

1. **Never produce a DOCX from scratch when a reference template is available.** Always accept a `--reference-doc` / caller-supplied `.docx` template and extract only its styles, not its content.
2. **Every image in the output MUST carry non-empty alt text.** Neither pandoc nor python-docx exposes this natively — the handler MUST apply the oxml workaround (see Idioms). Accessibility is not optional.
3. **Table header rows MUST be semantically marked** (`<w:tblHeader/>` in `<w:trPr>`). Neither pandoc nor python-docx does this automatically.
4. **Validate the ZIP before declaring success.** A DOCX is a ZIP; a truncated or malformed archive silently fails in some consumers. Run `zipfile.ZipFile.testzip()` as the first post-write check.
5. **Cross-reference all style IDs.** Every `<w:pStyle>` and `<w:rStyle>` in `word/document.xml` must exist in `word/styles.xml`. Dangling references cause Word to silently reformat or warn on open.
6. **Set document metadata explicitly.** Title, author, and creation date must appear in `docProps/core.xml`. Default is filename — unacceptable for production documents.
7. **Resolve all relative image paths before conversion.** Missing media files produce broken-image placeholders that cannot be repaired post-hoc without re-running the pipeline.

---

## Canonical Tooling & Pinned Versions

| Tool | Pinned version | Role | Notes |
|---|---|---|---|
| **pandoc** | 3.10 (June 2025 stable) | Markdown → DOCX conversion, reference-doc templating | Primary conversion path |
| **python-docx** | 0.8.11+ | Fine-grained programmatic generation; post-processing pandoc output | No native alt-text API — use oxml layer |
| **lxml** | latest | Direct OOXML XML manipulation | Required transitive dep for python-docx oxml access |
| **openxml-audit** | 0.7.5+ (PyPI) | Automated structural + schema validation; ships `assert_valid_docx()` pytest helper | Python port of MS Open XML SDK validator |
| **Office-o-tron** | 0.8.8 (Java JAR) | Canonical OOXML + ODF schema validation; use for CI gate | `java -jar officeotron-0.8.8.jar doc.docx` |
| **oletools** | latest | Programmatic inspection of ZIP internals, XML structure counts | Good for custom assertion scripts |
| **docx-parser-converter** | latest (PyPI) | Parses document.xml + styles.xml to Pydantic models; resolves inheritance | Useful for style-inheritance cycle detection |

**Contradiction note:** research-02 lists pandoc minimum as "2.19+" while research-01 pins "v3.10 as of June 2025 stable". Use 3.10 as the floor; 2.19 is obsolete guidance.

**Thin spot:** `openxml-audit` version 0.7.5 is cited but its PyPI release history was not independently verified. Treat as best-available; pin and lock in requirements.txt.

---

## Idioms

### Pandoc: Extract and apply a reference template
```bash
# Extract pandoc's built-in reference.docx — edit styles in Word, never edit content
pandoc -o custom-reference.docx --print-default-data-file reference.docx

# Convert markdown with custom template
pandoc input.md \
  --reference-doc custom-reference.docx \
  --metadata-file meta.yaml \
  -o output.docx
```

### Pandoc: Minimal metadata file
```yaml
# meta.yaml
title: "Document Title"
author: "Author Name"
date: "2026-06-13"
```

### python-docx: Set alt text on an image (oxml workaround)
```python
from docx import Document
from lxml import etree

doc = Document()
pic = doc.add_picture('image.png')
# The inline element is the parent of the drawing
inline = pic._element.getparent()
docPr = inline.find(
    './/{http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing}docPr'
)
if docPr is not None:
    docPr.set('descr', 'Descriptive alt text here')
```

**Note:** research-02 uses an incorrect namespace for `docPr` (`drawingml/2006/main`). The correct namespace is `drawingml/2006/wordprocessingDrawing`. Use the corrected form above.

### python-docx: Mark table header row
```python
from docx.oxml import OxmlElement

table = doc.add_table(rows=2, cols=3)
for cell in table.rows[0].cells:
    tcPr = cell._element.get_or_add_tcPr()
    tcHeader = OxmlElement('w:tblHeader')
    tcPr.append(tcHeader)
```

### python-docx: Set core metadata
```python
doc.core_properties.title   = "Document Title"
doc.core_properties.author  = "Author Name"
doc.core_properties.created = datetime.utcnow()
```

### Validation: ZIP integrity + required parts
```python
import zipfile
from lxml import etree

REQUIRED_PARTS = [
    '[Content_Types].xml',
    'word/document.xml',
    'word/styles.xml',
    'word/_rels/document.xml.rels',
    'docProps/core.xml',
    'docProps/app.xml',
]

with zipfile.ZipFile('output.docx') as zf:
    assert zf.testzip() is None, "ZIP archive is corrupt"
    names = set(zf.namelist())
    for part in REQUIRED_PARTS:
        assert part in names, f"Missing required part: {part}"
```

### Validation: Cross-reference style IDs
```python
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

with zipfile.ZipFile('output.docx') as zf:
    styles_xml = etree.fromstring(zf.read('word/styles.xml'))
    doc_xml    = etree.fromstring(zf.read('word/document.xml'))

style_ids = {s.get(f'{{{W}}}styleId') for s in styles_xml.findall(f'.//{{{W}}}style')}

for pStyle in doc_xml.findall(f'.//{{{W}}}pStyle'):
    sid = pStyle.get(f'{{{W}}}val')
    assert sid in style_ids, f"Dangling style reference: {sid}"
```

### Validation: Alt text completeness
```python
WPD = 'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing'

for docPr in doc_xml.findall(f'.//{{{WPD}}}docPr'):
    descr = docPr.get('descr', '')
    assert descr.strip(), f"Image id={docPr.get('id')} missing alt text"
```

---

## Anti-Patterns / Failure Modes

| Failure | Root cause | Detection | Fix |
|---|---|---|---|
| Corrupt ZIP | Truncated write, filesystem error | `zf.testzip() is not None` | Re-run pipeline; check disk space |
| Dangling style reference | Style deleted from reference.docx after document built | Style ID cross-reference check | Rebuild reference.docx or restore style |
| Missing alt text | Neither pandoc nor python-docx sets it automatically | XPath `//wp:docPr[@descr='']` | Apply oxml workaround post-generation |
| Table headers not semantic | API-level tables never get `<w:tblHeader>` | Inspect first row `<w:trPr>` | Apply oxml workaround per table |
| Lost metadata | YAML front matter malformed or `--metadata-file` not passed | Check `docProps/core.xml` for `<dc:title>` | Pass explicit `--metadata-file`; validate CoreProperties |
| Broken image relationships | rId in document.xml has no entry in _rels | Cross-reference rId sets | Ensure images copied before conversion; use absolute paths |
| Missing image media | _rels points to word/media/imageN.ext that does not exist | Check `word/media/*` in namelist | Embed images before pandoc call; check relative path resolution |
| Style inheritance cycle | Circular `<w:basedOn>` in styles.xml | DFS cycle detection on parent map | Use docx-parser-converter to detect; rebuild styles.xml |
| Column width loss | Pandoc sets all tables to full page width | Visual inspection | Post-process with python-docx `column.width` assignment |
| Headers/footers per-section | Pandoc applies global header/footer from reference.docx only | Visual inspection | Use python-docx sections API for per-section control |
| Skipped heading levels | Content author jumps H1→H3 | Parse heading outline, assert sequential | Lint source markdown before conversion |
| Font not available on target | Custom font embedded but not licensed for embedding | Inspect `word/fonts/` or open on clean system | Use system-safe fonts or embed with license; warn agent |

---

## Environment Detection Snippet

Detects which tools are available and selects the appropriate conversion path:

```python
import shutil, subprocess, sys

def detect_docx_env() -> dict:
    env = {}

    # pandoc
    pandoc = shutil.which('pandoc')
    if pandoc:
        result = subprocess.run([pandoc, '--version'], capture_output=True, text=True)
        version_line = result.stdout.splitlines()[0] if result.stdout else ''
        env['pandoc'] = version_line  # e.g. "pandoc 3.10"
    else:
        env['pandoc'] = None

    # python-docx
    try:
        import docx
        env['python_docx'] = docx.__version__
    except ImportError:
        env['python_docx'] = None

    # lxml
    try:
        import lxml.etree
        env['lxml'] = lxml.etree.LXML_VERSION
    except ImportError:
        env['lxml'] = None

    # openxml-audit
    try:
        import openxml_audit
        env['openxml_audit'] = getattr(openxml_audit, '__version__', 'installed')
    except ImportError:
        env['openxml_audit'] = None

    # Java (for Office-o-tron)
    java = shutil.which('java')
    if java:
        result = subprocess.run([java, '-version'], capture_output=True, text=True)
        env['java'] = result.stderr.splitlines()[0] if result.stderr else 'present'
    else:
        env['java'] = None

    return env

# Decision logic
def select_conversion_path(env: dict) -> str:
    if env['pandoc']:
        return 'pandoc'           # preferred for markdown input
    if env['python_docx'] and env['lxml']:
        return 'python_docx'      # fallback for programmatic generation
    raise RuntimeError(f"No DOCX tooling available: {env}")
```

**Path selection rule:**
- Markdown/RST/HTML source → **pandoc** (reference-doc templating is best-in-class)
- Data-driven / API-driven / dynamic assembly → **python-docx** (programmatic control)
- Accessibility post-processing always → **python-docx oxml** (regardless of generation path)

---

## Test / Validation Strategy

### Tier 1 — Structural (always run, fast)
1. `zipfile.ZipFile.testzip()` — ZIP integrity
2. Required parts checklist — all six parts present
3. Style ID cross-reference — no dangling `<w:pStyle>` / `<w:rStyle>`
4. Relationship cross-reference — no dangling `r:embed` / `r:link` rIds
5. Image media existence — all rId targets exist in `word/media/`

### Tier 2 — Semantic / Accessibility (always run)
6. Alt text completeness — all `<wp:docPr>` have non-empty `descr`
7. Table header rows — first `<w:tr>` of every `<w:tbl>` has `<w:tblHeader/>`
8. Heading hierarchy — parse outline, assert no level skips
9. Metadata presence — `<dc:title>`, `<dc:creator>`, `<dcterms:created>` in core.xml

### Tier 3 — Schema (CI gate, slower)
10. `openxml-audit assert_valid_docx()` — full Open XML SDK schema pass
11. Office-o-tron JAR — canonical OOXML schema validation (requires Java)

### Pytest skeleton
```python
from openxml_audit import assert_valid_docx
import zipfile
from lxml import etree

OUTPUT = "output.docx"

def test_zip_valid():
    with zipfile.ZipFile(OUTPUT) as zf:
        assert zf.testzip() is None

def test_required_parts():
    required = ['[Content_Types].xml', 'word/document.xml', 'word/styles.xml',
                'word/_rels/document.xml.rels', 'docProps/core.xml', 'docProps/app.xml']
    with zipfile.ZipFile(OUTPUT) as zf:
        names = set(zf.namelist())
        for p in required:
            assert p in names, f"Missing: {p}"

def test_schema_valid():
    assert_valid_docx(OUTPUT)

def test_alt_text():
    WPD = 'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing'
    with zipfile.ZipFile(OUTPUT) as zf:
        doc = etree.fromstring(zf.read('word/document.xml'))
    for docPr in doc.findall(f'.//{{{WPD}}}docPr'):
        assert docPr.get('descr', '').strip(), \
            f"Image id={docPr.get('id')} missing alt text"

def test_heading_hierarchy():
    W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
    with zipfile.ZipFile(OUTPUT) as zf:
        doc = etree.fromstring(zf.read('word/document.xml'))
    levels = []
    for pStyle in doc.findall(f'.//{{{W}}}pStyle'):
        val = pStyle.get(f'{{{W}}}val', '')
        if val.startswith('Heading') and val[7:].isdigit():
            levels.append(int(val[7:]))
    for i in range(1, len(levels)):
        assert levels[i] <= levels[i-1] + 1, \
            f"Heading level skip: {levels[i-1]} → {levels[i]}"
```

---

## Thin Spots (flagged for follow-up research)

1. **openxml-audit version confidence**: PyPI release history not independently confirmed. Verify 0.7.5 is current before pinning.
2. **Pandoc per-table column widths**: No idiom exists for setting column widths via pandoc alone. Post-processing with python-docx is the only known path, but the exact API for reading pandoc-output column count and assigning widths was not covered in research.
3. **Per-section headers/footers via pandoc**: Research confirms pandoc only supports global headers/footers from reference.docx. The python-docx sections API was not detailed — thin.
4. **Style inheritance cycle detection at scale**: The DFS approach was mentioned but no code was provided. The `docx-parser-converter` Pydantic model approach is referenced but not demonstrated.
5. **Font embedding and licensing**: Mentioned as a failure mode; no detection or mitigation code provided.
6. **Track Changes in output**: Research confirms pandoc reads TC from input docx but does NOT write TC in output. If the handler needs to produce TC-annotated diffs, a separate mechanism is required — not researched.
7. **office-o-tron JAR distribution**: The JAR must be bundled or fetched at CI setup time. No canonical download URL or hash was provided in research.

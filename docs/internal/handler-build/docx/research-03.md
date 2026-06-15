# Research 03: Deterministic .docx Validation

## Validation Tools & Canonical Versions

- **openxml-audit** (PyPI: `openxml-audit` 0.7.5+) — Python port of Microsoft Open XML SDK validation; provides package structure, schema, semantic, properties, and format-specific checks (DOCX/XLSX/PPTX); ships pytest plugin with `assert_valid_docx()` and zero-config assertions.
  - Source: [PyPI openxml-audit](https://pypi.org/project/openxml-audit/)
- **Office-o-tron** (v0.8.8, Java) — LibreOffice's canonical OOXML validator; CLI: `java -jar officeotron-0.8.8.jar document.docx`; validates both OOXML and ODF formats.
  - Source: [LibreOffice Dev Blog Jan 2026](https://dev.blog.documentfoundation.org/2026/01/22/validating-odf-and-ooxml-files/)
- **oletools** (Python) — Iterates XML internals; tests document type detection, XML structure completeness, element counts; good for programmatic inspection of `[Content_Types].xml`, `word/document.xml`, styles.xml, relationships.
  - Source: [GitHub decalage2/oletools tests](https://github.com/decalage2/oletools/blob/master/tests/ooxml/test_basic.py)
- **docx-parser-converter** (PyPI) — Extracts document.xml, styles.xml, numbering.xml; parses to Pydantic models; applies style inheritance rules.
  - Source: [PyPI docx-parser-converter](https://pypi.org/project/docx-parser-converter/)

## OOXML Structure Checklist (ZIP + XML Internals)

- **ZIP Integrity**: Verify magic bytes `PK\x03\x04` (first 4 bytes); unzip without errors; confirm archive is not corrupted.
- **Required Parts**: Assert presence of:
  - `[Content_Types].xml` — defines MIME types for all internal parts
  - `word/document.xml` — main document body with `<w:document>`, `<w:body>` elements
  - `word/styles.xml` — style definitions; `<w:styles>` container with `<w:style>` elements per style ID
  - `word/_rels/document.xml.rels` — relationships; link document.xml to images, headers, footers, themes
  - `docProps/core.xml` — metadata (title, author, created, modified)
  - `docProps/app.xml` — app-specific metadata (word count, page count)
- **Heading Outline**: Parse `word/document.xml` and verify:
  - `<w:pStyle>` attributes reference valid style IDs from styles.xml
  - Heading levels are sequential (no skip from h2→h4)
  - Outline levels match hierarchy: `<w:pStyle w:val="Heading1" w:outlineLvl="0"/>`
- **Table Structure**: Verify `<w:tbl>` elements contain:
  - `<w:tr>` (rows) with `<w:tc>` (cells)
  - Each cell has `<w:p>` (paragraph) or content
  - No orphaned `<w:tbl>` tags outside body or in corrupted state
- **Alt Text**: Inspect `word/document.xml` for images; check:
  - `<wp:docPr>` elements have `descr` attribute (alt text)
  - Empty descr (decorative images) must be intentional, not accidental omission
  - Related: blip image references in `<a:blip>` must point to valid media files
- **Style References**: Cross-reference all `<w:pStyle>` and `<w:rStyle>` IDs against styles.xml:
  - Every style ID used in document.xml must exist in styles.xml
  - No dangling references; if style is deleted, rebuild document or fallback to default

## Common Failure Modes & Detection

1. **Broken Style References** — style ID in document.xml not found in styles.xml
   - Detection: Parse both files, create style ID set, iterate document paragraphs/runs, assert all IDs in set
   - Symptom: Word opens file but marks errors; displays fallback formatting
   - Test: `assert style_id in styles_dict for all uses`

2. **Missing Alt Text** — images lack `<wp:docPr descr="...">` or have empty descr
   - Detection: XPath query for `//w:drawing/wp:inline/wp:docPr` and `//w:drawing/wp:anchor/wp:docPr`, assert `@descr` is non-empty and meaningful
   - Symptom: Accessibility violations; screen readers cannot describe images
   - Test: `assert docPr.get('descr') and len(docPr.get('descr')) > 0`

3. **Corrupt ZIP** — archive checksum fails, zip headers malformed, or truncated file
   - Detection: `zipfile.ZipFile(path).testzip()` returns None if valid, else list of bad files
   - Symptom: Cannot open in Word; `BadZipFile` exception on read
   - Test: `import zipfile; zf = zipfile.ZipFile(path); assert zf.testzip() is None`

4. **Lost Metadata** — missing or truncated docProps/core.xml or app.xml
   - Detection: Open ZIP, check both files exist; parse XML and verify required elements (created, modified dates, title)
   - Symptom: Document properties dialog shows empty/default values
   - Test: `assert 'docProps/core.xml' in zf.namelist(); parse XML, assert <dc:created> exists`

5. **Broken Relationships** — image/header/footer rId in document.xml has no match in _rels/document.xml.rels
   - Detection: Extract all `<Relationship Id="rId*"` from _rels, create set; scan document.xml for `r:embed="rId*"` and `r:link="rId*"`, assert all exist
   - Symptom: Images missing, headers/footers don't render, Word prompts recovery
   - Test: `assert rid in relationships_dict for all referenced rIds`

6. **Missing Image Files** — _rels references media/image1.png but word/media/ lacks the file
   - Detection: Extract image rIds from relationships; verify corresponding image files exist in word/media/ with correct format
   - Symptom: Word shows broken image placeholder; cannot export to PDF
   - Test: `assert f"word/media/{image_filename}" in zf.namelist()`

7. **Style Inheritance Loops** — style A inherits from B, B inherits from A (circular dependency)
   - Detection: Build parent map from styles.xml; perform DFS from each style, assert no cycles
   - Symptom: Word hangs or crashes during rendering
   - Test: `assert not has_cycle(parent_map, root_styles)`

## Testing Best Practices

- **Unit Test Pattern** (Python + pytest + openxml-audit):
  ```python
  from openxml_audit import assert_valid_docx
  
  def test_docx_structure():
      assert_valid_docx("output.docx")
  ```

- **Detailed Inspection Pattern** (python-docx or zipfile + XML):
  ```python
  import zipfile
  from lxml import etree
  
  with zipfile.ZipFile("output.docx") as zf:
      # Validate ZIP
      assert zf.testzip() is None, "ZIP corrupt"
      
      # Validate required parts
      assert "[Content_Types].xml" in zf.namelist()
      assert "word/document.xml" in zf.namelist()
      
      # Parse and validate structure
      doc_xml = etree.fromstring(zf.read("word/document.xml"))
      styles_xml = etree.fromstring(zf.read("word/styles.xml"))
      
      # Cross-reference styles
      style_ids = set(s.get("{http://schemas.openxmlformats.org/wordprocessingml/2006/main}val") 
                       for s in styles_xml.xpath("//w:style"))
      
      for p_style in doc_xml.xpath("//w:pStyle"):
          style_id = p_style.get("{http://schemas.openxmlformats.org/wordprocessingml/2006/main}val")
          assert style_id in style_ids, f"Missing style: {style_id}"
  ```

- **Metadata Validation** (docProps files):
  ```python
  with zipfile.ZipFile("output.docx") as zf:
      core_xml = etree.fromstring(zf.read("docProps/core.xml"))
      created = core_xml.find("{http://purl.org/dc/elements/1.1/}created")
      assert created is not None and created.text, "Missing creation date"
  ```

## Sources

- [openxml-audit PyPI](https://pypi.org/project/openxml-audit/)
- [LibreOffice Office-o-tron Validation](https://dev.blog.documentfoundation.org/2026/01/22/validating-odf-and-ooxml-files/)
- [oletools OOXML Tests](https://github.com/decalage2/oletools/blob/master/tests/ooxml/test_basic.py)
- [DOCX Structure: XML Under the Hood](https://blog.fileformat.com/en/word-processing/docx-under-the-hood-why-xml-still-powers-modern-word-documents/)
- [Microsoft Office Document Corruption Testing](https://www.robweir.com/blog/2010/02/office-document-corruption.html)
- [OOXML Hacking: Style Management](https://www.brandwares.com/bestpractices/2015/12/xml-hacking-managing-styles/)

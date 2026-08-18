---
name: witify-docx
description: Generate a Witify-branded Word (.docx) document — dark cover page, Aptos typography, logo header, paginated footer. Use when the user wants a Word document, report, or client deliverable with Witify branding.
---

# Witify Word documents

Generate a polished .docx from the proven template in `template/`: full-page dark cover (forest `#1C2B30`, light logo, red accent, tone-on-tone W watermark), Aptos everywhere, black text, gray W icon in the header, `Witify Technologies · witify.io` + page number in the footer, 0.75in margins.

## Process

1. Copy the whole `template/` folder into the scratchpad (`cp -r <skill_dir>/template <scratchpad>/<doc-name>`). Never edit the skill's own copy.
2. Fill the `CONFIG` block in `build_docx.py`: cover title (`\n` for line breaks), subtitle, meta line, output path.
3. Replace the `CONTENT` section with the document's real content. The template's example demonstrates every helper: `doc.add_heading` (levels 1–2), `doc.add_paragraph`, `bullet()`, `styled_table()` (cells accept `(main, gray sub-line)` tuples), `code_block()`, and `add_run` with `B` / `N` / `CODE_INLINE` for mixed-style runs. Number Heading 1 titles manually ("1. …", "2. …").
4. Run `python3 build_docx.py` (deps: `pip install python-docx pymupdf`). The cover is drawn and rasterized by pymupdf — no browser needed. Aptos renders when Word's bundled fonts are present, else Helvetica.
5. Verify every page visually before declaring done (needs LibreOffice with its Writer module):
   ```bash
   SOFFICE=$(command -v soffice || echo "/Applications/LibreOffice.app/Contents/MacOS/soffice")
   "$SOFFICE" --headless --convert-to pdf --outdir . "<out>.docx"
   python3 -c "import pymupdf; d=pymupdf.open('<out>.pdf'); [p.get_pixmap(dpi=140).save(f'page{i}.png') for i,p in enumerate(d,1)]"
   ```
   Read each page image. Fix and re-run until layout holds: no stray blank page, tables and code blocks unsplit, footer page numbers right-aligned.

## House style

- Text is automatic (black) everywhere; the brand carries color, the type does not.
- No em dashes in client-facing copy — use colons, semicolons, or parentheses.
- Cover text is baked into the cover image; to change it, edit `CONFIG` and re-run rather than editing in Word.
- LibreOffice previews substitute Aptos with a serif — expected; Word renders Aptos.
- The `w:rFonts` theme-attribute strip and the `w:color val="auto"` override in `style_font` are what defeat Word's theme fonts and heading blues; keep them when adapting styles.

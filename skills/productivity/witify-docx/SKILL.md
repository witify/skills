---
name: witify-docx
description: Generate a Witify-branded Word (.docx) document — dark cover page, Helvetica text with Archivo bold headings, logo header, paginated footer. Use when the user wants a Word document, report, or client deliverable with Witify branding.
---

# Witify Word documents

The brand lives in `template/` (`witify-template.docx` plus the bundled `fonts/`): full-page dark cover (soft grained teal gradient around `#1D373D`, light logo, red accent, tone-on-tone W watermark) with live text: version line, title, subtitle, prepared-for / prepared-by block; Helvetica for text (bundled with macOS, Arial on Windows), Archivo bold for headings and the cover title, black text, a thin teal band across the top of every content page, gray W icon in the header, `Witify Technologies · witify.io` + page number in the footer, 0.75in margins. You never style anything: you open the template and write content with its named styles.

## Process

1. Before touching any file, propose the cover values in a Markdown table and ask the user to confirm or correct them in one reply. Infer every value you can from the request and the source material; write `N/A` for anything you truly cannot infer (typically Client). The table is the whole message, plus one line asking for confirmation (and, when needed, the install pointer described below). Never start building before the reply.

   | Champ | Valeur |
   |---|---|
   | Titre | Exigences serveur |
   | Sous-titre | Hébergement Azure de l'application Laravel |
   | Version | 1.0 |
   | Client | N/A |
   | Date | 10 septembre 2026 |
   | Préparé par | Patrick Vigeant |
   | Table des matières | non |
   | Diagrammes | non |

   Defaults: Version `1.0`, Date today, Préparé par `Patrick Vigeant`, Table des matières `non`, Diagrammes `non`. Propose Diagrammes `oui` when the source material describes an architecture, a flow, or a sequence, or when the user asks for diagrams. Diagrams are drawn by the third-party `diagram-design` plugin; when you propose `oui` and it is not installed (Claude Code: `~/.claude/plugins/installed_plugins.json` contains `diagram-design@diagram-design`; Codex: `~/.codex/config.toml` has a `[plugins."diagram-design@diagram-design"]` table), the same confirmation message ends with one extra line pointing the user to the "Recommended Companions" section of the repo README for the install commands (both harnesses are covered). Never install it yourself.
2. Copy `template/` into the scratchpad (`cp -r <skill_dir>/template <scratchpad>/<doc-name>`). Never edit the skill's own copy.
3. Fill the `CONFIG` block in `build_docx.py` with the confirmed values: `TITLE` (`\n` for line breaks), `SUBTITLE`, `VERSION`, `CLIENT`, `DATE` (`None` = today in French), `AUTHOR`, `TOC` (`True` adds a "Table des matières" page after the cover), `OUT_DIR`. The output is named `<title> - v<version>.docx`.
4. Replace the `CONTENT` section with the document's real content. The example shows every helper: `doc.add_heading` (levels 1–3), `para()`, `bullet()`, `table()` (cells accept `(main, gray sub-line)` tuples), `code()`. `para()` and `bullet()` take parts: strings, `(text, "b")` for bold, `(text, "code")` for inline code. Number Heading 1 titles yourself ("1. …", "2. …"). For each diagram, produce it with diagram-design (it triggers on its own), export it to PNG at scale 2 into the doc folder with that plugin's `export-diagram` command (needs `pip install playwright && playwright install chromium`, plus network access for its Google Fonts), then insert it with `figure("name.png", "Figure 1 : …")`. Number figures yourself.
5. Run `python3 build_docx.py` (dep: `pip install python-docx`). The script installs the bundled Archivo Bold into the user's font folder when it is missing and prints what it installed; if it did, tell the user to restart Word if it was open, since Word only picks up new fonts on launch.
6. Verify every page visually before declaring done (needs LibreOffice with its Writer module):
   ```bash
   SOFFICE=$(command -v soffice || echo "/Applications/LibreOffice.app/Contents/MacOS/soffice")
   "$SOFFICE" --headless --convert-to pdf --outdir . "<out>.docx"
   find . -name "page*.png" -delete && python3 -c "import pymupdf; d=pymupdf.open('<out>.pdf'); [p.get_pixmap(dpi=140).save(f'page{i}.png') for i,p in enumerate(d,1)]"
   ```
   Read each page image. Fix and re-run until layout holds: no stray blank page, tables and code blocks unsplit, figures on the same page as their caption and no wider than the text, footer page numbers right-aligned. `table()` already keeps a table on one page and adds spacing after it; you only need `para(..., keep=True)` on a short intro paragraph that must stay with its table. With `TOC = True`, LibreOffice does not compute the TOC field: the render shows the "Table des matières" title over the placeholder line, which is expected; the TOC fills in when the user opens the file in Word and accepts the field update. That title uses the `Title` style, not Heading 1, so the TOC does not list itself.

## House style

- Text is automatic (black) everywhere; the brand carries color, the type does not.
- No em dashes in client-facing copy — use colons, semicolons, or parentheses.
- Only use the template's styles (`Normal`, `Heading 1–3`, `List Bullet`, `List Number`, `Code`, `Code Inline`, `Table Cell`, `Table Sub`, and the three `Cover …` styles). Do not set fonts, sizes, or colors on runs; that is how documents drift from the brand.
- The cover text is real Word text, so a reviewer can fix a typo in Word. A brand change (logo, colors, layout) goes through the template, regenerated by the maintainer script in `.agents/witify-docx/`.
- Diagrams follow the Witify brand on their own: the build script installs the committed profile (`template/diagram-profile/witify.md`) into `~/.diagram-design/profiles/` and writes the `.diagram-design` marker in the doc folder, which diagram-design resolves before drawing. Brand changes to figures go through that committed file; never embed an SVG, `figure()` takes a PNG.
- LibreOffice previews substitute Helvetica and Archivo with metric-compatible or serif fallbacks when they are not installed — expected; Word renders the real fonts.

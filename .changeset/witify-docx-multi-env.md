---
"witify-skills": minor
---

`witify-docx` now runs anywhere Python does. The cover page is drawn and rasterized by `pymupdf` (which also renders the SVG logo assets) instead of being screenshotted by headless Chrome, so the browser dependency and every hardcoded macOS path are gone; the only requirements are `python-docx` and `pymupdf`. The default output lands in the working directory rather than `~/Desktop`, and the verification step resolves `soffice` from PATH before falling back to the macOS LibreOffice app path.

---
"witify-skills": minor
---

`witify-docx` now runs outside macOS. The build script auto-discovers a Chrome-family browser (PATH, macOS app locations, Playwright installs, with a `CHROME_PATH` override) instead of hardcoding the macOS Chrome path, and retries the cover render with `--no-sandbox` for root/container environments. The cover is now printed to PDF and rasterized with `pymupdf` rather than screenshotted, because headless-screenshot viewports vary by platform and Chrome version and cropped the page's bottom edge on Linux. The default output lands in the working directory rather than `~/Desktop`, the cover prefers a locally installed Aptos before Word's bundled fonts, and the verification step resolves `soffice` from PATH before falling back to the macOS LibreOffice app path.

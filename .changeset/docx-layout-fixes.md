---
"witify-skills": patch
---

`witify-docx` template layout fixes. The thin teal band at the top of content pages is now a header-anchored shape instead of a page border, so it renders edge to edge in LibreOffice and Word PDF exports instead of stopping at the side margins. List items get 4pt of space after each item (the `contextualSpacing` inherited from python-docx's stock template suppressed it). Heading 1 to 3 spacing before and after grows by 20%. The footer moves from 0.75in to 0.4in from the page bottom, so it no longer touches the last body line on a full page.

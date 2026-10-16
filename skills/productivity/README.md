# Productivity

General workflow tools, not code-specific.

## Model-invoked

Model- or user-reachable (rich trigger phrasing so the model can reach for them).

- **[loom](./loom/SKILL.md)** — Analyze a Loom video in detail: transcript with speakers, chapters, and actual frames inspected via ffmpeg. Fires whenever a loom.com link shows up in a task, grill, or conversation and its content matters.
- **[witify-docx](./witify-docx/SKILL.md)** — Generate a Witify-branded Word document: dark cover page, Helvetica text with Archivo bold headings, logo header, paginated footer. Fires when a deliverable needs to ship as a branded .docx.
- **[witify-writing-style](./witify-writing-style/SKILL.md)** — Witify's writing rules for client-facing French copy: no dashes or semicolons, one idea per sentence, Québec number and amount formats, vouvoiement, preferred French terms, and a final grep check. It is the single source of those rules, so every document skill invokes it rather than carrying its own. Fires when writing or editing any text a client will read, and whenever another skill generates a document.
- **[figma-brief](./figma-brief/SKILL.md)** — Write a concise brief (a prompt) for generating interface mockups with an AI design tool such as Figma Make: business purpose per screen, fr-CA vocabulary, one primary action, the business rules that shape the UI, and how the screens link. Labels, not data; intent, not pixels. Fires when screens are being described so a tool can render them.

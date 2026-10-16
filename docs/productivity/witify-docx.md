Quickstart:

```bash
npx skills add witify/skills --skill=witify-docx
```

```bash
npx skills update witify-docx
```

[Source](https://github.com/witify/skills/tree/main/skills/productivity/witify-docx)

## What it does

`witify-docx` turns content into a Witify-branded Word document: a full-page dark cover with the title, subtitle, version and prepared-for block as live Word text, Helvetica body text with Archivo bold headings, a thin teal band and the W icon on every content page, and a paginated footer. The brand lives in a committed template, `witify-template.docx`, and the build script only writes content through that template's named styles. It never sets a font, a size or a colour on a run; that is how documents drift from the brand, and the skill refuses to drift.

It also never starts building before you have confirmed the cover: the first thing it does is propose every cover value in one table and wait for your reply.

## When to reach for it

Type `/witify-docx`, or the agent reaches for it automatically when you ask for a Word document, a report, or a client deliverable with Witify branding.

Reach for it when the deliverable is a `.docx` a client or a partner will open: server requirements, an audit, a technical note, a handover. For the text inside it, [witify-writing-style](./witify-writing-style.md) applies; the skill invokes it on its own before writing a single string.

## Prerequisites

Python with `python-docx` for the build, and LibreOffice for the verification pass (it renders the document to PDF, then one PNG per page, so the agent can read every page before declaring the document done). Diagrams are optional and come from the third-party `diagram-design` plugin listed under "Recommended Companions" in the repo README; its PNG export needs Playwright once. The build script installs the bundled Archivo Bold font and the Witify diagram profile into your user folders when they are missing.

## The template is the brand

The leading idea is a **template, not a stylesheet**. Everything the brand decides (cover layout, type, band, header icon, footer) is baked into `witify-template.docx` by a maintainer script, and a day-to-day document only ever opens that template and adds headings, paragraphs, bullets, tables, code blocks and figures with the helpers the build script exposes. A brand change goes through `brand/` and the template, never through a document.

## It's working if

- The first message is a cover table (Titre, Sous-titre, Version, Client, Date, Préparé par, Table des matières, Diagrammes) and nothing is built until you answer.
- The output is named `<title> - v<version>.docx` and every page was rendered and read before the agent said it was done.
- No run in the build script carries a font, a size or a colour.

## Where it fits

A reach-for-it-anytime standalone: it ends whichever flow produced the content, it does not sit inside one. Its neighbour is [witify-writing-style](./witify-writing-style.md), because every string the document carries follows those rules. The private `witify/skills-admin` skills (quotes, agreements) build on the same template.

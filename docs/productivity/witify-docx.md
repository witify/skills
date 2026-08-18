Quickstart:

```bash
npx skills add witify/skills --skill=witify-docx
```

```bash
npx skills update witify-docx
```

[Source](https://github.com/witify/skills/tree/main/skills/productivity/witify-docx)

## What it does

Generates a polished, Witify-branded Word document from a proven template: a full-page dark cover (forest ground, light logo, red accent, tone-on-tone W watermark), Aptos typography throughout, the gray W icon in every header, and a `Witify Technologies · witify.io` footer with right-aligned page numbers. The agent never styles a document from scratch — it copies the template, fills in a config block and a content section, and the brand decisions (and the Word quirks they defeat) come along for free.

## When to reach for it

Type `/witify-docx`, or the agent reaches for it automatically when a deliverable needs to ship as a Word document with Witify branding — a client-facing requirements doc, a proposal, a report.

## Prerequisites

macOS with `python-docx` installed and Google Chrome (renders the cover). Microsoft Word installed locally makes the cover render in genuine Aptos; without it the cover falls back to Helvetica. Verification needs LibreOffice and `pymupdf`.

## The template is the brand

The skill's discipline is **template, not taste**: every document starts as a copy of `template/` — a working generator script, the cover HTML, and vendored logo assets — so two documents produced months apart look like they came from the same shop. The script also encodes the non-obvious Word mechanics learned the hard way: theme-font attributes that silently override explicit fonts, heading styles that stay blue unless forced to automatic, table rows that split across pages, and footer tab stops that ignore the page edge.

The loop ends with a **visual verification pass**: the docx is converted to PDF, every page rendered to an image, and each one inspected before the document is declared done.

## It's working if

- The document opens in Word with Aptos everywhere, including headings — no Calibri, no theme blue.
- The cover is a full-bleed dark page matching the Witify site's palette, with the title baked into the image.
- Content pages carry the gray W icon top-right and a right-aligned page number starting at 1 after the cover.
- The agent showed rendered page images before calling it done.

## Where it fits

A reach-for-it-anytime standalone for shipping client-facing deliverables. Content usually comes from elsewhere — a spec, a validated artifact, a conversation — and this skill gives it its final branded form. See [ask-witify](../engineering/ask-witify.md) for the map of the whole set.

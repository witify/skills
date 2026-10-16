# Witify brand

The single source of truth for the Witify brand in this repo: colors, typography, logos, and the diagram-design profile. Every skill that renders something branded draws from here, never from values retyped in its own files.

## Colors

| Role | Hex | Use |
|---|---|---|
| teal | `#1D373D` | Cover page, top band, table rules, dark surfaces. The brand's ground color. |
| red | `#FF4746` | The one accent: cover mark, focal element in a figure. One or two per page, never more. |
| grey | `#5E6A6E` | Secondary text, sub-lines in tables, header icon tone. |
| light-grey | `#AEBDC2` | Cover version and subtitle on teal, muted labels. Too faint for text on white. |
| hairline | `#D0D5D3` | Thin table borders, rules. |
| surface | `#F3F4F2` | Code block and table header shading, page plane behind cards. |
| white / black | `#FFFFFF` / `#000000` | Text is black on white and white on teal; the brand carries color, the type does not. |
| cover-dark / cover-teal | `#0B2A31` / `#1C5A6A` | The two poles of the cover gradient around teal. |

Machine-readable copy: [`tokens.json`](./tokens.json). Scripts read that file; humans read this one. Keep the two equal.

## Typography

- **Text**: Helvetica (ships with macOS), Arial on Windows.
- **Headings, cover title, figure titles, hero numbers**: Archivo Bold. Vendored in [`fonts/`](./fonts/) under the SIL Open Font License, unchanged from Google Fonts.
- **Code**: Consolas in documents, Geist Mono in diagrams.

## Logos

[`logos/`](./logos/): `logo-light.svg` (wordmark for dark grounds), `logo-black.svg` (the wordmark in solid black, for white grounds: the quote header), `witify-icon-tonal.svg` (the W mark, used as a tone-on-tone watermark), `witify-icon-black50.png` (the W mark at 50% black, for headers on white).

## Diagram profile

[`diagram-profile/witify.md`](./diagram-profile/witify.md) is the diagram-design profile: it maps the colors above to that plugin's semantic roles (paper, ink, accent, link) and sets Archivo and Helvetica as its faces. It is a **derived mapping, not a second source**: diagram-design requires a profile to be the full body of its own `style-guide.md` (hence its length and the sections unrelated to Witify, which the plugin would otherwise backfill with its defaults), and it reads only that file, so the hex values are retyped there in the plugin's vocabulary. Change a color in `tokens.json` and this README first, then update the profile by hand; `scripts/sync-brand.sh --check` fails when a token is missing from the profile. The docx build script installs it to `~/.diagram-design/profiles/witify.md`; any folder with a `.diagram-design` marker containing `profile: witify` then draws on brand.

## Where copies live and how they stay equal

The plugin only ships skill folders, and `witify-docx` copies its `template/` into a scratchpad before building, so the assets a skill needs at run time are committed inside it as **generated copies**:

| Source here | Copy |
|---|---|
| `fonts/*` | `skills/productivity/witify-docx/template/fonts/` |
| `diagram-profile/witify.md` | `skills/productivity/witify-docx/template/diagram-profile/witify.md` |
| `tokens.json`, `logos/*` | baked into `skills/productivity/witify-docx/template/witify-template.docx` by `.agents/witify-docx/make_template.py` |

The private `witify/skills-admin` repo (quotes, agreements, other business documents) builds on the same brand: its own sync script copies the fonts and the docx template out of a checkout of this repo, and its quote template script imports `.agents/witify-docx/make_template.py` from that checkout. It carries no brand source of its own, so a brand change made here reaches it on its next sync.

Edit only the source. Then run `scripts/sync-brand.sh` to refresh the copies (and both `make_template.py` scripts when a color, font, or logo changed), and commit both. CI runs `scripts/sync-brand.sh --check` on every push and fails when a copy has drifted from its source or a token in `tokens.json` is missing from the diagram profile.

---
"witify-skills": minor
---

`witify-docx` can now carry diagrams drawn by the third-party [diagram-design](https://github.com/cathrynlavery/diagram-design) plugin. The confirmation table opens with a new "Diagrammes" row (default `non`); when diagrams are wanted and the plugin is missing, the skill points to the README's new "Recommended Companions" entry, which gives the Claude Code and Codex install commands, and never installs anything itself. A `figure()` helper in the build script inserts a PNG with a numbered caption and refuses SVG.

The skill ships a Witify brand profile for diagram-design (`template/diagram-profile/witify.md`: white paper, black ink, red accent, teal strong rules and links, Archivo titles, Helvetica labels). The build script installs it into `~/.diagram-design/profiles/` and writes the `.diagram-design` marker in the document folder, so figures come out in the document's palette without any setup.

`witify-doctor` level 0 gains check 0.5: the diagram-design companion plugin installed and enabled on every harness present, Playwright and Chromium ready for its PNG export, and the Witify profile in place. Any of these missing is `Attention`, never `Blocked`.

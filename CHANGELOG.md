# witify-skills

## 1.10.0

### Minor Changes

- [`ea58195`](https://github.com/witify/skills/commit/ea5819583db675ae14312e3d7f9e08b792be7230) Thanks [@francoislevesque](https://github.com/francoislevesque)! - The skill set now also ships as a native Codex plugin. Codex ≥ 0.147 accepts `skills` as an array of paths, so `.codex-plugin/plugin.json` lists exactly the three promoted buckets — install with `codex plugin marketplace add witify/skills` then `codex plugin add witify-skills@witify`. The release flow keeps its version in sync alongside the Claude manifest.

### Patch Changes

- [`ea58195`](https://github.com/witify/skills/commit/ea5819583db675ae14312e3d7f9e08b792be7230) Thanks [@francoislevesque](https://github.com/francoislevesque)! - The Claude Code plugin is now the documented default install path. The README leads with the plugin (one install, auto-updating on release) and repositions skills.sh and Laravel Boost as in-project fallbacks for non-Claude harnesses or projects that deliberately fork a skill.

## 1.9.0

### Minor Changes

- [`1a9481f`](https://github.com/witify/skills/commit/1a9481f1b923ae19dcc622e1f7d9dfa73e87ca40) Thanks [@francoislevesque](https://github.com/francoislevesque)! - New `witify-docx` skill (productivity): generate a Witify-branded Word document from a proven template — full-page dark cover with the brand's forest ground and tone-on-tone W watermark, Aptos typography throughout, gray W icon in the header, and a paginated footer. The template encodes the hard-won Word mechanics (theme-font overrides, heading colors, unsplittable table rows, footer tab stops) and ends with a visual verification pass over every rendered page.

## 1.8.0

### Minor Changes

- [`f10dc22`](https://github.com/witify/skills/commit/f10dc223c979e80edb0c9b57d6f72cb98112d5e5) Thanks [@francoislevesque](https://github.com/francoislevesque)! - New **loom** skill (productivity, model-invoked): analyze a Loom video in detail without watching it — transcript with speaker names and timestamps, chapter list, and actual frames inspected via ffmpeg. It fires whenever a loom.com link shows up in a task, grill, or conversation and the video's content matters. The transcript is the map, frames are the evidence: it reads the transcript first, then seeks ffmpeg directly into Loom's signed mp4 over HTTP range requests, so one frame anywhere in a 90-minute recording costs ~2 seconds instead of a full download. Cross-platform (linux, macOS, Windows git-bash) with only curl + ffmpeg required; handles password-protected videos and falls back to yt-dlp for the rare HLS-only ones.

## 1.7.0

### Minor Changes

- [`62f02b5`](https://github.com/witify/skills/commit/62f02b50ebc2fdf421b36bb0002ed0d9f95e39f7) Thanks [@francoislevesque](https://github.com/francoislevesque)! - `to-tickets` and `to-spec` now capture the AFK-agent publishing rules learned from a real run against firstmate:

  - **Label move**: when a source spec carries `ready-for-agent`, splitting it into independently grabbable tickets moves the label down onto those tickets — a childless spec with that label is itself grabbable as one giant unit of work.
  - **Writing for the AFK agent**: an implement session sees only its ticket's description plus its direct parent's, with no tracker access — cross-cutting decisions go in the parent description, every ticket stays self-contained, and a single-PR parent's title doubles as the PR title.

  `to-spec` now states that the `ready-for-agent` label it applies makes the spec the unit an AFK agent implements whole, and points at `/to-tickets` as the pass that moves the label down when Split PR mode is chosen.

- [`2efbfe4`](https://github.com/witify/skills/commit/2efbfe42b05eb32ed2aaaa9d522dc5386543fcf0) Thanks [@francoislevesque](https://github.com/francoislevesque)! - New `migration/` bucket for one-way moves that run once per project, starting with **migrate-deploy-branches**: it takes a project's frontend build off the server, adding a GitHub Actions workflow that builds the assets and force-pushes source + build to `deploy` / `deploy-dev`, then walks you through repointing Forge at those branches and stripping npm out of the deploy script. It enumerates the artifacts to commit by building rather than guessing (a PWA's `sw.js` is the one that gets missed), and swaps the deploy script's `git pull` for a fetch-and-reset, without which a force-pushed deploy branch breaks every deploy.

### Patch Changes

- [`229f189`](https://github.com/witify/skills/commit/229f1894b7f3494e269ebb6410258c138762ef0b) Thanks [@francoislevesque](https://github.com/francoislevesque)! - `sprintify-ui` now documents BaseSelect's built-in empty option and the `<option :value="null">` trap: Vue strips the `value` attribute for null bindings, so the option's text content becomes its submitted value and backend validation rejects it. The fix is labeling the built-in empty option via the `placeholder` prop.

- [`546e3f7`](https://github.com/witify/skills/commit/546e3f79f60a5ed1635e092b75aa081d5e4c3e44) Thanks [@github-actions[bot]](https://github.com/github-actions%5Bbot%5D)! - Sync vendored skills from their upstream repos.

- [`729a506`](https://github.com/witify/skills/commit/729a5065b81c36da0fd78afd5f5734235c7926ce) Thanks [@github-actions[bot]](https://github.com/github-actions%5Bbot%5D)! - Sync vendored skills from their upstream repos.

## 1.6.2

### Patch Changes

- [`3ddbdb8`](https://github.com/witify/skills/commit/3ddbdb84fbd0d325fa8c638e797263ca332d9958) Thanks [@francoislevesque](https://github.com/francoislevesque)! - The maintainer-only `upstream-sync` skill is no longer a skill at all: it now lives as a plain process doc at `.agents/upstream-sync/`, documented in the README's new "Syncing with Upstream" section. Skill installers (Laravel Boost's `boost:add-skill`, skills.sh) discover skills by scanning the repo for files named `SKILL.md`, so removing the marker file — rather than relying on per-installer exclusion flags — is what guarantees internal tooling never ships.

## 1.6.1

### Patch Changes

- [`92ab244`](https://github.com/witify/skills/commit/92ab24495936418be62f1c82fc49484b6f49f906) Thanks [@francoislevesque](https://github.com/francoislevesque)! - Stop the repo-internal `upstream-sync` dev skill from being installed by skill installers. The README's Laravel Boost instructions now use bucket-scoped paths (`witify/skills/skills/engineering` and `witify/skills/skills/productivity`) — Boost's `boost:add-skill` matches every `SKILL.md` in a repo with no exclusion mechanism, so the previous bare `witify/skills` form also installed `.claude/skills/upstream-sync` and unfinished `in-progress/` drafts. For skills.sh, `upstream-sync` is now marked `metadata.internal: true`, which hides it from discovery.

- [`c3bd146`](https://github.com/witify/skills/commit/c3bd1460c1f8490e9c0d5e3c2af21fd703a7dad9) Thanks [@francoislevesque](https://github.com/francoislevesque)! - README: replace the "Why These Skills Exist" essay with a "Making Changes & Releasing" section documenting the changeset-driven release flow.

## 1.6.0

### Minor Changes

- [`4c80813`](https://github.com/witify/skills/commit/4c8081311a044fbb6ffccd97e08dde81b8d84ea8) Thanks [@francoislevesque](https://github.com/francoislevesque)! - Formalize repo maintenance flows:

  - New repo-local **`/upstream-sync`** skill (`.claude/skills/upstream-sync/`) that pulls updates from the upstream mattpocock/skills repo. Its `STATE.md` records the sync point (last-synced upstream commit), the name/bucket mappings, and the adaptation ledger of deliberate local divergences — ledger files are hand-merged, everything else is copied verbatim.
  - Repo-local skills are exposed to Codex through a `.agents/skills` symlink to `.claude/skills`.
  - `CLAUDE.md` now documents the changeset-per-change convention and the release flow (`CHANGELOG.md` is generated, never hand-edited).

## 1.5.0

### Minor Changes

- [#551](https://github.com/mattpocock/skills/pull/551) [`697d4ce`](https://github.com/witify/skills/commit/697d4ce9742da558fd1ba6697c8e9775e2e302dd) Thanks [@mattpocock](https://github.com/mattpocock)! - Add Codex metadata alongside each skill's Claude Code frontmatter so the set works in both harnesses without generated copies.

  - Add an `agents/openai.yaml` beside every `SKILL.md` with Codex UI metadata (`interface.display_name`, `interface.short_description`).
  - Mark every user-invoked skill with `policy.allow_implicit_invocation: false`, the Codex analog of `disable-model-invocation: true`, so Codex excludes it from implicit invocation while explicit `$skill` invocation still works.
  - Document the dual-harness invocation model in `.agents/invocation.md`, `CLAUDE.md`, and the promoted-bucket READMEs.
  - Add `AGENTS.md` as a symlink to `CLAUDE.md` so Codex reads the same repo instructions.

- [#488](https://github.com/mattpocock/skills/pull/488) [`cdec9f6`](https://github.com/witify/skills/commit/cdec9f6eb24dbfe606e3ad9b3eb457ba09210b85) Thanks [@mattpocock](https://github.com/mattpocock)! - Reword how the **`prototype`** skill handles its artifacts around a single idea: **the prototype is a primary source**. Rather than being deleted once it's answered its question, the prototype is captured as runnable evidence on a throwaway branch (`prototype/<name>`) out of main, with a context pointer to it left on the implementation issue — so the main branch keeps only the validated decision while the exploration stays findable. The answer (verdict + question) is still captured durably in an issue/ADR/commit.

- [#536](https://github.com/mattpocock/skills/pull/536) [`42a5b70`](https://github.com/witify/skills/commit/42a5b70fcacc7baff1977b13f3919fb2f63af14e) Thanks [@mattpocock](https://github.com/mattpocock)! - Ship the skill set as a native **Claude Code plugin**. The repo is now its own single-plugin marketplace, so you can subscribe to the promoted skills as a managed, read-only bundle instead of copying editable files:

  ```
  /plugin marketplace add witify/skills
  /plugin install witify-skills@witify
  ```

  `.claude-plugin/plugin.json` gains full marketplace metadata (version, description, author, license, keywords) and a sibling `.claude-plugin/marketplace.json` lists the plugin. `skills.sh` remains the universal installer (and the path for Codex and other harnesses today); a native Codex plugin is deferred — see `.agents/adr/0002-ship-as-a-claude-code-plugin.md` for why.

- [`cefc49a`](https://github.com/witify/skills/commit/cefc49a278d2f90f266e4fd721c99b46107355b5) Thanks [@francoislevesque](https://github.com/francoislevesque)! - Sync with upstream mattpocock/skills and promote two skills:

  - `grilling` now interviews in **rounds**: each round asks the whole frontier of the design tree (every question whose prerequisites are settled), with facts delegated to sub-agents instead of asked. `grill-me`, `grill-with-docs`, `triage`, and `loop-me` inherit the new cadence.
  - `prototype`'s logic branch now builds a **single shareable HTML file** — free-play buttons plus tabbed guided walkthroughs — instead of a terminal app, so non-developers can drive the state model.
  - `writing-great-skills` is renamed to **`writing-for-agents`** and widened to cover anything an agent reads (skills, `AGENTS.md` / `CLAUDE.md`, pointed-at docs). It is now model-invoked; skill-specific mechanics moved to a linked `SKILL-MECHANICS.md`.
  - **`wizard`** is promoted to `engineering/` (model-invoked): the agent generates an interactive bash wizard when it hits steps only a human can perform — infra provisioning, credentials, CI secrets, one-off migrations.
  - **`to-questionnaire`** is promoted to `productivity/`: turn a decision blocked on someone else's knowledge into a Markdown questionnaire for them to fill in.
  - New in-progress skill **`wait-what`**: make the agent re-pitch a message that didn't land, in ASD-STE100 Simplified Technical English and the project's ubiquitous language.
  - `batch-grill-me` is removed — its rounds/frontier behaviour is now `grilling`'s default.

- [#538](https://github.com/mattpocock/skills/pull/538) [`2602257`](https://github.com/witify/skills/commit/260225724133c4a204489599f04642aa089259a0) Thanks [@mattpocock](https://github.com/mattpocock)! - Wayfinder now burns research tickets down with subagents instead of leaving them parked for a separately-launched session.

  Research stays a real ticket type — it's a genuine shared blocker that downstream decisions hang on, and that dependency is exactly what the frontier's blocking edges exist to render. What changes is how it's resolved: because research is AFK, charting doesn't stop and read it. After creating the tickets, the charting session fires a `/research` subagent for each research ticket to burn it down in parallel, capturing the findings on a throwaway `research/<name>` branch with a context pointer. Research tickets are the one exception to _one ticket per session_.

- [#533](https://github.com/mattpocock/skills/pull/533) [`45afd80`](https://github.com/witify/skills/commit/45afd8074a8b7de5fe073845d080fa9dd6c429fa) Thanks [@mattpocock](https://github.com/mattpocock)! - Add a YAGNI scoping filter to the **`improve-codebase-architecture`** skill's Explore step. Instead of scanning the whole repo evenly, it now scopes to where change is actually landing: if you name a direction it takes it, otherwise it reads the last ~20 commit messages to bias exploration toward actively-developed paths. A deepening opportunity in code nobody touches is a refactor you'll never cash in — the leverage only pays off where you keep editing — so the report stops tidying dormant corners of the repo.

### Patch Changes

- [#535](https://github.com/mattpocock/skills/pull/535) [`e74fee8`](https://github.com/witify/skills/commit/e74fee89feb6025a6a74f6282feb7d33b1b6e578) Thanks [@mattpocock](https://github.com/mattpocock)! - Make `/ask-witify` clued-up about `/wayfinder` — the heaviest, most cognitively demanding flow.

  The router now sharpens the two routing mistakes people most often make with wayfinder:

  - **Over-reaching for it.** It's slower and denser than a single grill, so it's flagged as the heaviest flow and reserved for the idea that genuinely won't fit one session — a well-scoped feature belongs on `/grill-with-docs`, not here.
  - **Losing the way at the handoff.** When the map clears, wayfinder hands off, it doesn't build: merge onto the main flow at `/to-spec` (which collapses the map's linked decisions into a buildable plan) rather than looping the map straight into `/implement`. Straight-to-`/implement` is only for efforts that turned out genuinely small.

- [#502](https://github.com/mattpocock/skills/pull/502) [`44eed54`](https://github.com/witify/skills/commit/44eed545186ffd0263e8004867750b80cfddd215) Thanks [@mattpocock](https://github.com/mattpocock)! - Make `/setup-witify-skills` friendlier and align the local-markdown tracker with the current spec.

  - **Triage labels** are now asked about only when the `triage` skill is installed, and then as a single recommended-yes question ("keep the default triage labels?") instead of an override interrogation. When `triage` isn't installed, the section — and `docs/agents/triage-labels.md` — are skipped.
  - **External PRs as a request surface** is no longer a setup question. The GitHub/GitLab templates still carry the flag, defaulted off; a user can flip it in `docs/agents/issue-tracker.md` later.
  - **Domain docs** default to single-context without asking; multi-context is only offered when the repo shows monorepo signals.
  - **Local-markdown tickets** are now one file per ticket under `.scratch/<feature>/issues/<NN>-<slug>.md` — never a single combined `tickets.md`. `/to-tickets` and the local issue-tracker template now agree, and the spec file is `spec.md` (not `PRD.md`) to match `/to-spec`.

  Docs pages for `setup-witify-skills` and `to-tickets` re-synced.

- [#532](https://github.com/mattpocock/skills/pull/532) [`170ad48`](https://github.com/witify/skills/commit/170ad48655825783d0193e850e31a9aac957bb95) Thanks [@mattpocock](https://github.com/mattpocock)! - Reword **`grilling`** for general use. Its description and body no longer scope the interview to a software plan: "this plan" → "this", "enact the plan" → "act on it", and "exploring the codebase" → "exploring the environment". The technique is unchanged; it now reads as a stress-test of any plan, decision, or idea.

- [#534](https://github.com/mattpocock/skills/pull/534) [`7d694b7`](https://github.com/witify/skills/commit/7d694b7ae981ca221a8f759b15273fe7b5dc393e) Thanks [@mattpocock](https://github.com/mattpocock)! - Name the `/wayfinder` unit a **decision ticket**.

  People kept reading a wayfinder ticket as an ordinary _implementation_ ticket — a slice of a build to execute — when wayfinder uses them as **decision tickets**: questions whose resolution is a decision. The skill description and its opening line now introduce "decision ticket" (and say what makes it one), and the `ask-witify` / engineering README wayfinder blurbs and the docs page match — while "ticket" stays the everyday word once the term is established. `CONTEXT.md` records **Decision ticket** as a domain term so the "avoid: ticket" guidance no longer contradicts wayfinder's deliberate use of the word.

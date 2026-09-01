# Report format

The diagnosis is one self-contained HTML file in the OS temp directory: resolve `$TMPDIR`, falling back to `/tmp` (`%TEMP%` on Windows), and write `<tmpdir>/witify-doctor-<timestamp>.html` so every run gets a fresh file. Open it (`open` on macOS, `xdg-open` on Linux, `start` on Windows) and tell the user the absolute path. Nothing lands in the repo.

The report is for **reading**; every decision is taken in chat afterwards, so it carries no form controls. Tailwind from the CDN, no other dependency.

## Scaffold

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Witify doctor — {{repo name or "machine only"}}</title>
    <script src="https://cdn.tailwindcss.com"></script>
  </head>
  <body class="bg-stone-50 text-slate-900 font-sans">
    <main class="max-w-5xl mx-auto px-6 py-12 space-y-12">
      <header>…</header>
      <section id="level-0">…</section>
      <section id="level-1">…</section>
      <section id="level-2">…</section>
      <section id="level-3">…</section>
      <section id="level-4">…</section>
      <section id="prescription">…</section>
    </main>
  </body>
</html>
```

## Header

Date, machine (hostname), repo name and branch when there is one, sprintify's `dev` commit the comparison ran against. Then the verdict, large: **the project's level** (or "machine only" without a project), with a five-step ladder showing each level as `Healthy`, `Attention` (with its count of open items), or `Blocked` (with what blocks it). A legend of the three badges, then the levels.

## Level section

One `<section>` per level, titled with its number, name, and cost line from the checklist ("Hygiene — no code changes"). Inside, one `<article>` per item, in checklist order:

- **Title** — the item's number and name.
- **Badge** — `Healthy` (emerald), `Attention` (amber), `Blocked` (slate, naming the prerequisite: a lower level, the missing clone, a package major).
- **Evidence** — what was observed, as data: paths and counts for memory stores and personal instruction files (never contents), resolved-or-missing per command, version pairs (project vs sprintify), tables where the item compares lists.
- **Proposed treatment** — one line per choice the chat will ask for, leading with the recommended answer. A level-4 item names the skill it hands off to.

## Tables

- **Guidelines** (2.1) — one row per file: name, status (`upstream-only` / `diverged` / `project-only`), one-line summary of the difference, proposed action (`import` / `merge` / `keep` / `keep — repo's own`). Diverged rows expand to a side-by-side `<pre>` of the two versions, or a unified diff when the file is long; the repo's own additions are highlighted, not the whole file.
- **Tooling** (2.2) — one row per item: name, project value, sprintify value, status.
- **PHPStan rules** (3.2) — one row per rule sprintify has: class name, one-line description of what it enforces (from its error message), status (`present` / `missing` / `not importable — needs /sprintify-sync <area>`), **files to change** as an integer, one sample `path:line`. Project-only rules get their own short table underneath, labelled as the repo's own.
- **CI workflows** (1.5, 2.3, 4.3) — the four sprintify workflows first, one row each: name, purpose, status (`present` / `missing` / `diverged`), the `run:` steps that differ, proposed action — a missing `build-deploy-branch.yml` row carries the Forge repoint note (staging `dev` → `deploy-dev`, production `main` → `deploy`). Project-only workflows follow as the repo's own. Underneath, the 2.3 cross-check as a two-column list: each `after-update-checks.md` command and the workflow that runs it, or `no workflow`.
- **Baseline skills** (4.1) — one row per base-code skill: area, applies / predates, the `/sprintify-sync <area>` that unblocks it.

## Prescription

Close with the decisions the chat is about to ask, grouped by level in order, each with its recommended answer — the user can read the whole prescription before the first question, and see where this session's treatment will stop.

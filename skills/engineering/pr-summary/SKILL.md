---
name: pr-summary
description: "Brief the reviewer of a GitHub PR: what the PR changes and why, the features to validate by hand with a 🔴🟡🟢 priority, a side-by-side before/after video of every visual change, and the impacts to flag (migrations, env, config, breaking changes). Posted at the top of the PR description."
disable-model-invocation: true
---

# PR summary

Write the briefing a reviewer reads before opening the code, and post it at the top of the PR description. The briefing is short and scannable: bullets, not paragraphs. It tells the reviewer what this PR changes and why, what to validate by hand and which of those checks matter most, what the change looks like before and after, and what the PR touches that a reviewer must not miss. It **shows rather than argues**: a feature to validate is a path to click, a visual change is a video of the same path on both sides, a priority is a reason stated in a few words. Everything else about the code (concepts, decisions, where to start reading) stays out: a reviewer who wants it asks the agent.

GitHub only, via the `gh` CLI.

## 1. Locate the PR

- **No argument** — infer from the current branch: `gh pr view --json number,state,baseRefName,headRefName,url,title,body`. If the branch has no PR, stop and say so: the briefing is posted on a PR, and there is nothing to post on.
- **Argument (PR number or URL)** — check the working tree has no modified or staged file (`git status --porcelain` shows only `??` lines, if any) and stop otherwise, so uncommitted work never crosses branches. Then announce the switch and `gh pr checkout <number>`.

Remember the branch the run started on: step 4 ends by going back to it.

Stop if the PR is closed or merged. Record the merge-base of the base and head branches (`git merge-base origin/<base> HEAD`): the **before** state lives there.

## 2. Read the whole PR

Three sources, all three read before writing a line:

- **The project** — `README`, the agent instructions (`CLAUDE.md`, `AGENTS.md`, `.ai/guidelines/`), any domain doc or glossary, the business rules. They give the words the briefing uses and the ask the PR answers.
- **The change** — `gh pr diff`, the commit messages, the PR's title and existing body. Read every changed file in full, not just the hunks, and the tests with the code: whether a feature has a test that exercises it decides its colour in step 6.
- **The ticket** — when the branch name, the PR body, or a commit names a tracker id and the tracker's MCP tools are available (ClickUp `clickup_get_task` and `clickup_get_task_comments`; Linear `get_issue` and `list_comments`), fetch it: it holds the *why* and what was asked, against which the PR is compared. When the tools are not available, go on without it and say so in the report. The ticket is context here, not the work list, so its absence never stops the run.

Done when every changed file is accounted for in exactly one of: a feature to validate, an impact, or plumbing with no reviewer-facing consequence.

## 3. Find the visual changes

From the changed files, list what a user can see differently: pages, components, templates, styles, user-facing strings, routes. For each, find **where it is visible**: the route, the page, the state needed to reach it (which record, which role, which filter). A change inside a component that renders identically (a refactor, a renamed prop) is not visual.

The result is a list of screens, each with its URL, the state to set up, **what changed on it in one sentence** (it is written under the video), **the element that carries the change** (the list foot, the renamed tab, the new chips: it gets a frame in the video; a new screen has none), and the **path** to record: three to six actions from a page that exists on both sides of the PR (the module's index, the reports page) to the changed state, ending with the changed element in view, so the before and the after replay the same clicks. Keep at most six: beyond that, pick the screens that carry the change rather than the ones that merely inherit it. No screens means the briefing says so (`Aucun changement visuel.`) and steps 4 and 5 are skipped.

## 4. Record before and after

Three preconditions:

- **A running app.** A Laravel project served by Herd is already reachable at `https://<folder>.test` (when Chrome shows a privacy error on it, `http://` serves the same app); otherwise launch it with the `/run` skill when the harness offers it, or the command the project documents. Frontend assets must follow the checkout (`npm run dev` running, or a build after each switch).
- **Claude in Chrome.** Its `gif_creator` records the path as an animated GIF, and the extension is the only way a file reaches the PR without a human. When the `mcp__claude-in-chrome__*` tools are not available, skip steps 4 and 5, write `Aucune capture : Claude in Chrome non disponible.` under the Avant / après heading, say so in the report, and ship the rest of the briefing. When several browsers are connected, `list_connected_browsers` and let the user pick the one where the app loads. When the app shows its login page, sign in with the test user the project seeds for local use (its seeder or README names it), never with a credential the browser autofilled: the local database may hold imported data where the README's root user does not exist, and the project's test-user seeder adds the account without touching anything else. When typing into the form does not register, fill it with `javascript_tool` (set each input's value through the native setter, dispatch `input`, click the submit button). The session can drop mid-run, for instance when the extension reconnects: a login page in a recording means signing in again and recording that screen over.
- **No modified or staged file in the tree**, so the checkouts below are safe. Already guaranteed by step 1 when a PR number was given; check it now otherwise, and stop if it isn't.

Record in this order:

1. **Before**, on the merge-base: `git switch --detach <merge-base>`, rebuild the assets, then one recording per screen.
2. **After**, on the PR head: `gh pr checkout <number>`, rebuild, run the PR's migrations if it adds any (`php artisan migrate`), then the same recordings.

The order matters because migrations only go one way in this skill: a *before* captured after the PR's migrations ran is not a before, and a rollback can destroy data. A new screen is recorded on the before side too, with the same path: the index without its entry, or the blank page at its URL, is what the reviewer compares against. A local database already migrated past the PR (a later commit dropped a column the PR still reads) makes an after screen error out: record it as it is, say why under the video, and say so in the report rather than debugging the PR.

Every recording is made in the same window (`resize_window` to 1440×900 first), same URL, same state. **Recording** a screen: `gif_creator` `start_recording`, a one-second `wait`, a screenshot (the first frame), the path from step 3 driven with `navigate` and `computer` (every action and screenshot becomes a frame, so `wait` for the data to load and take a screenshot after each state worth seeing), a last screenshot, `stop_recording`, then `export` with `download: true`, `filename: "<screen>-avant.gif"` (or `-apres.gif`) and `options: {"showWatermark": false, "showProgressBar": false, "showActionLabels": false}`. The file lands in Chrome's download folder (`~/Downloads`). When the page ignores `computer` clicks and scrolls (it happens: the click lands, nothing moves), drive the path with `javascript_tool` instead (`element.click()`, `scrollTop = scrollHeight`) and keep the screenshots: the recorder only needs the states. On the after side, right after the last screenshot, measure the changed element with `javascript_tool` (`JSON.stringify(element.getBoundingClientRect())`, the element found by its text or role): keep its `x,y,width,height` and `window.innerWidth`, measured together: the merge script scales the rectangle from CSS pixels to the recording's pixels, which are usually fewer.

Once both sides exist, turn each pair into one video with the skill's script, which needs ffmpeg (`brew install ffmpeg`) and Pillow (`python3 -m pip install --user Pillow`):

```bash
python3 <skill folder>/scripts/merge-videos.py <screen>-avant.gif <screen>-apres.gif <screen>-avant-apres.mp4 \
  --caption "<what changed, one sentence>" --highlight <x,y,w,h of the changed element> --viewport-width <innerWidth>
```

The result is an mp4, « Avant » on the left and « Après » on the right, each state held at least 1.2 s with a half-second dissolve to the next, the shorter side holding its last state, the sentence written in a strip under the video and an amber frame around the changed element on the final « Après » state: a few hundred kilobytes, played inline by GitHub with a scrubber. `--highlight` is omitted for a new screen; `--caption` never is. When ffmpeg is missing and cannot be installed, fall back to `scripts/merge-gifs.py` with the same arguments and a `.gif` output (Pillow only): same layout, no dissolve, and the file plays as an image.

A recording is dropped for one screen only when it fails there (the recorder errors, the export never lands, the merge fails): take a `computer` screenshot with `save_to_disk` of the final state on each side instead, and that screen gets a two-column table of the two stills under `Non enregistré : <why>`.

Copy each file into a folder of the session's scratchpad as `<screen>-avant-apres.mp4` (or `<screen>-avant.jpg` and `<screen>-apres.jpg` for the stills): the upload tool only accepts files from the session's own folders, and the file name is how step 5 tells the uploads apart. Never commit them.

Then go back to the branch the run started on and rebuild the assets, so the local app serves what the user had before.

Done when the tree is back on the starting branch with no modified or staged file, and every screen from step 3 has its video (or its two stills and a reason).

## 5. Upload the files

The GitHub API cannot upload files; the PR's edit form can. In Claude in Chrome, open the PR page, open the description's options menu, click **Edit**, locate the edit form's file input with `find` (the hidden `type="file"` input of the first comment's form, not the one of the new-comment form at the bottom), and `file_upload` the videos and any stills into it, under 10 MB per call (split into two calls past that). When `find` only surfaces the new-comment form's input, give the edit form's input an `aria-label` with `javascript_tool` (`textarea.form.querySelector('input[type=file]')`) and find it by that label. Once the uploads finish, GitHub appends to the textarea one `<img … alt="<file name>" src="https://github.com/user-attachments/assets/…" />` tag per image, and for a video a bare `https://github.com/user-attachments/assets/<id>` line with no file name, sometimes at the top of the text rather than at the end. Read the textarea with `javascript_tool` and keep the alt-to-src pairs; the video URLs come in upload order, and since the file name is not in the text, confirm each one by downloading it (`curl -sL -H "Authorization: token $(gh auth token)" <url>`) and comparing its checksum with the local file. The briefing writes each video as `<video src="<url>" controls></video>`: a bare URL posted through `gh` renders as a link, the tag renders as a player with the file name above it. Then close the tab with `tabs_close_mcp` without saving or cancelling: clicking **Cancel** on an edited textarea raises a native discard prompt that freezes the tab for the extension, while closing the tab from the tool works even then. The description is written in step 7, through `gh`, never saved from the browser.

Done when every file from step 4 has its `user-attachments` URL, each video's confirmed by checksum.

## 6. Write the briefing

Always written in simple French, whatever the language of the PR's existing description, its commits, or the conversation: the reviewers read French, and the section headings above are fixed. Code identifiers, routes, and quoted UI strings stay as they are. Bullets everywhere, one line each where possible, no paragraph longer than two sentences: the reviewer scans it in two minutes. Facts only: a claim the PR, the repo, or the ticket does not support is left out, never guessed.

```markdown
<!-- pr-summary:start -->
_Une ligne sur le produit, pour qui ne le connaît pas (nom, ce qu'il fait, pile)._

## 🎯 Ce que la PR change
- Le besoin ou la demande, avec le ticket s'il existe.
- Une puce par chose que la PR fait, 3 à 5 puces.

## ✅ À valider
🔴 à vérifier absolument · 🟡 mérite un œil · 🟢 couvert par les tests, à sauter si pressé
- [ ] 🔴 **Fonctionnalité** (`/route`) : où aller, quoi faire, ce qu'on doit voir. Pourquoi rouge, en quelques mots.
- [ ] 🟡 **Fonctionnalité** : … Pourquoi jaune.
- [ ] 🟢 **Fonctionnalité** : …

## 🎬 Avant / après
Chaque vidéo rejoue le même parcours sur la base (à gauche, « Avant »)
et sur la tête de la PR (à droite, « Après »), avec un fondu entre chaque état.
La phrase sous la vidéo dit ce qui change ; sur l'état final « Après »,
un cadre orange entoure l'élément changé (un écran nouveau n'en a pas).

**Nom de l'écran** — le parcours en une ligne : d'où on part, ce qu'on clique,
ce qu'on doit voir.
<video src="https://github.com/user-attachments/assets/<id>" controls></video>

(Ou, pour un écran sans vidéo : « Non enregistré : <raison> » puis
| Avant | Après | avec les deux captures. Ou « Aucun changement visuel. »
à la place de la section entière.)

## ⚠️ Impacts
- **Cassant** : routes, réponses d'API, clés de traduction ou fichiers retirés ou renommés.
- **Migration** : tables et colonnes, données à reprendre.
- **Config / .env** : variables et clés nouvelles, leur valeur par défaut.
- **Permissions**, **jobs**, **dépendances ajoutées**, **module partagé** touché.
Une ligne par impact, rien d'autre ; omettre les lignes qui ne s'appliquent pas.
« Aucun impact. » quand il n'y en a pas.
<!-- pr-summary:end -->
```

The colour of a check is its priority, and most checks are green:

- 🔴 — the reviewer must look: the feature differs from what was asked (ticket, business rules, PR title), or the reading found a likely defect, or the author took a decision the ask did not cover and it changes behaviour.
- 🟡 — worth a look: a judgment call (design, wording, taste), a feature with no test that exercises it, something the author chose on their own, or something the agent is not sure behaves as intended.
- 🟢 — covered by a test and matching the ask: listed so the reviewer can tick it, skipped without risk.

Red and yellow come first, each with its reason in a few words. A decision read in a commit message or the ticket becomes a yellow or red check, never a note elsewhere. Project words are used as the project uses them; a concept the reviewer might not know is explained in the check that needs it, in a parenthesis, not in a glossary.

## 7. Post it

The briefing lives between the two markers at the top of the PR description; whatever the description already held stays below, intact, under a `---` rule. Re-running the skill replaces the block between the markers and touches nothing else, except the ticks: a check the reviewer already ticked (`[x]`) stays ticked when the same check is written again.

Read the current body (`gh pr view --json body`), assemble the new one, write it to a temporary file, then `gh pr edit <number> --body-file <file>`. Read the body back: the markers are present once, the existing content is still there, and every video URL from step 5 appears in it.

## 8. Report

- The PR link and which sections were written, with the count of red, yellow and green checks.
- Each screen recorded, with its video posted.
- What was skipped and why: ticket not read, Claude in Chrome not available, app not reachable, screens not recorded, before states unreachable.
- The branch the tree was left on, and the test account used to sign in if one was created.

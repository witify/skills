Quickstart:

```bash
npx skills add witify/skills --skill=wizard
```

```bash
npx skills update wizard
```

[Source](https://github.com/witify/skills/tree/main/skills/engineering/wizard)

## What it does

`wizard` generates an interactive bash script that walks a human, step by step, through a manual procedure — wiring up third-party services, running a one-off migration, moving a project from state A to state B. It opens each URL, says what to click and copy, captures what comes back, and writes it into `.env` files and GitHub Actions secrets.

The agent writes the script; it never runs it. You do, on your own machine. So a wizard is not a list of instructions you follow — it is a program that drives the procedure and holds the state, and your part is to click, paste, and press Enter.

## When to reach for it

Type `/wizard`, or the agent reaches for it on its own: when it hits a step only you can take — a key it can't mint, a dashboard it can't click — it builds you a wizard instead of writing the instructions into the chat, where they scroll away.

Reach for it when the next thing blocking you is a trip through a dashboard: a new dev needing six services configured before the app boots, a one-off migration whose switches must flip in a specific order, or the moment you're about to write those steps into a README — an executable version can't rot as quietly. Don't reach for it to *decide* what to build; for that, [grill-with-docs](./grill-with-docs.md) and [to-spec](./to-spec.md) are the tools.

## Prerequisites

None to generate one. The wizard it writes runs on bash, and uses `gh` when a stage sets a GitHub secret or variable. If `gh` is missing or unauthenticated, that stage becomes a warning and the closing summary tells you what to set by hand, instead of failing the run.

## Stages

A **stage** is one focused task on one screen. The script clears the terminal between stages, so nothing you still need scrolls away.

Scoping happens before a line is written. The skill reads the repo instead of asking cold — `.env*`, `docker-compose*`, framework config, and every `secrets.*` / `vars.*` reference in `.github/workflows/` — because each of those is a value the wizard has to produce. It shows you the ordered stage list to confirm, and only then maps each stage to the exact path a human follows ("Dashboard → Developers → API keys → Reveal test key → copy"). Scoping also settles where each captured value lands: `.env` only, GitHub secret or variable, both, or nowhere when the stage is a pure action.

The template ships the whole UX — progress with time remaining, confirmation gates, cross-platform URL opening, hidden entry for secrets, idempotent `.env` upserts, `gh secret` / `gh variable` writes, and a closing summary of everything it had to skip. Everything above the `STAGES` marker is a fixed library, never hand-edited; your part is only scoping the procedure and authoring its stages. The agent verifies statically (`bash -n`, `shellcheck`, a trace that every value lands where scoping said) but never runs it end to end — the first run is yours, and that run is the test.

Secrets never enter the model's context: the script captures them with hidden terminal entry at runtime, straight to `.env` or `gh secret`.

## Ephemeral by default

A one-off migration or personal setup gets saved to a scratch path, run, and deleted. A setup path the next person on the repo will also need gets committed and linked from the README, so they run the script instead of re-asking an agent.

## It's working if

- You're shown an ordered list of stages, and the values each one produces, and asked to confirm — before any script exists.
- Every URL is opened before the value from that page is asked for.
- Secrets are typed blind; nothing sensitive echoes into your scrollback.
- Ctrl-C and re-run picks up where you left off, offering already-saved values as defaults.
- The final screen lists what it wrote, and separately what you have to finish by hand.

## Where it fits

`wizard` is a reach-for-it-anytime standalone, sitting at the line where automation stops and a human has to click. Its nearest neighbour is [setup-witify-skills](./setup-witify-skills.md), because both exist to get a repo into a working state — that one configures this skill set, while `wizard` generates a setup path for everything else. It also pairs with [implement](./implement.md): when a build lands a feature that needs credentials or a manual cutover, a wizard is how the human half gets done. When you're unsure which skill fits the moment, [ask-witify](./ask-witify.md) routes you.

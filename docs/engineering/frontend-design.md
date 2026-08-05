Quickstart:

```bash
npx skills add witify/skills --skill=frontend-design
```

```bash
npx skills update frontend-design
```

[Source](https://github.com/witify/skills/tree/main/skills/engineering/frontend-design)

## What it does

`frontend-design` guides the agent's visual choices when building new UI or reshaping an existing screen: aesthetic direction, palette, typography pairing, layout, and motion. It frames the work as a design lead whose client has already rejected templated proposals, so every design must make deliberate, opinionated choices and take one justified aesthetic risk — the skill exists to kill the **templated default**, the screen that could belong to any product.

It is a verbatim copy of Anthropic's `frontend-design` skill, vendored from [claude-plugins-official](https://github.com/anthropics/claude-plugins-official) and re-synced with `scripts/sync-vendored-skills.sh` — the content is upstream's, only the packaging is ours.

## When to reach for it

Type `/frontend-design`, or the agent reaches for it automatically when the work is visual — a new page, a landing screen, a UI that needs an identity rather than just correct behaviour.

Reach for it when a screen *works* but looks generic. For the correctness patterns of Vue code — reactivity, forms, validation, responsiveness — use [frontend-development](./frontend-development.md) instead; for what a `Base*` component accepts, [sprintify-ui](./sprintify-ui.md).

## Distinctive, not templated

The skill's whole argument is that defaults aggregate into anonymity: the big-number hero, numbered 01/02/03 markers on content that isn't a sequence, the same font pair as every other project. It pushes the agent to ground design choices in the subject's own world — its materials, instruments, vernacular — and to run a brainstorm → explore → plan → critique → build → critique-again loop instead of emitting the first layout that compiles.

## Where it fits

`frontend-design` is a **reach-for-it-anytime standalone** — a vocabulary layer under the building skills whenever the work is visual: [prototype](./prototype.md) picks it up while sketching UI variations, [implement](./implement.md) while building screens. Its closest sibling is [frontend-development](./frontend-development.md), which owns how the frontend code is *built* where this owns how it *looks*. When you're unsure which skill or flow fits, [ask-witify](./ask-witify.md) routes you.

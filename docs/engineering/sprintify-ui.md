Quickstart:

```bash
npx skills add witify/skills --skill=sprintify-ui
```

```bash
npx skills update sprintify-ui
```

[Source](https://github.com/witify/skills/tree/main/skills/engineering/sprintify-ui)

## What it does

`sprintify-ui` is the agent's map of the [sprintify-ui](https://www.npmjs.com/package/sprintify-ui) component library: a catalog of every `Base*` component grouped by job — forms, relationships, actions, data display, layout, modals, media, feedback — plus the props, events, slots and exposed methods for the ones you reach for most, and the shared TypeScript types (`ActionItem`, `RowAction`, `Breadcrumb`, `DataTableQuery`).

It is a **catalog, not a rulebook**. It answers *what exists and what it accepts*, never *when or why to use it* — the conventions that govern Vue and Tailwind code live in [frontend-development](./frontend-development.md), and the two are written to not repeat each other. That split is what keeps the catalog safe to regenerate as the library moves.

## When to reach for it

Type `/sprintify-ui`, or the agent reaches for it automatically the moment a Vue template mentions any `Base*` component.

Reach for it directly when the **API** is the question — which prop drives server-side fetching, what a slot hands you, whether the component exposes `focus()`. When the question is *which component or pattern is right* — a form that keeps stale values, a layout that breaks on a phone, a native `title` that should be a tooltip — use [frontend-development](./frontend-development.md) instead.

## Prerequisites

Only useful in a project that depends on the `sprintify-ui` package. Elsewhere it is dead weight — every component it names is absent.

## Catalog first, live docs second

The catalog is a **snapshot**, and it says so: it was last synced against v0.12.1, and the installed version is whatever `package.json` pins. So it names two escape hatches for when the snapshot is thin or stale:

- `https://ui.sprintify.app/llm/{ComponentName}.txt` — per-component props, events and slots, fetched on demand. The index is at `/llm.txt`, the shared types at `/llm/types.txt`.
- `node_modules/sprintify-ui/dist/types/` — the authoritative export list and prop types for the version actually installed.

The catalog exists so the agent knows *a component for this exists and roughly what it does* without a round trip; the escape hatches exist so it never invents a prop. Guessing an API is the one failure mode this skill is built to kill.

## Where it fits

`sprintify-ui` is a **reach-for-it-anytime standalone reference**, one layer below the building skills: [implement](./implement.md), [tdd](./tdd.md) and [prototype](./prototype.md) pull it in whenever they touch a Vue template. Its closest neighbour is [frontend-development](./frontend-development.md), because the two divide one job — that skill holds the rules, this one holds the API, and each points at the other rather than duplicating it. When you're unsure which skill or flow fits, [ask-witify](./ask-witify.md) routes you.

Quickstart:

```bash
npx skills add witify/skills --skill=frontend-development
```

```bash
npx skills update frontend-development
```

[Source](https://github.com/witify/skills/tree/main/skills/engineering/frontend-development)

## What it does

`frontend-development` holds the patterns the agent applies while building Vue 3 + Tailwind interfaces: reading props after an emit with `nextTick`, sub-form components that emit cloned copies instead of mutating props, form resets from a `DEFAULT_FORM` constant, surfacing validation errors no field displays, and responsive layout.

It is patterns, not a process — there is nothing to run and no steps to follow; the agent applies whichever rules touch the code it is writing.

## When to reach for it

Type `/frontend-development`, or the agent reaches for it automatically when the work touches Vue components, frontend forms, or interactive UI.

Reach for it directly when you want a screen reviewed against the patterns — a form that keeps stale values, an error users never see, a layout that breaks on a phone. To explore what a UI *should look like* rather than build it correctly, use [prototype](./prototype.md) instead.

## Orphan validation errors

The other pattern worth naming: field components only display errors whose key matches their name, so array-level, wildcard, and nested error keys from the backend are **orphans** — invisible to the user unless deliberately surfaced. The skill has the agent check every error key a request can produce against the form's rendered fields and give each orphan a home: an alert, a prefix match, or a visual cue.

## Where it fits

`frontend-development` is a **reach-for-it-anytime standalone** — a reference layer that runs beneath the building skills whenever the work is frontend: [implement](./implement.md) and [tdd](./tdd.md) pick it up while writing Vue code, [prototype](./prototype.md) while sketching UI variations. When you're unsure which skill or flow fits, [ask-witify](./ask-witify.md) routes you.

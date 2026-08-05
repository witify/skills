Quickstart:

```bash
npx skills add witify/skills --skill=writing-for-agents
```

```bash
npx skills update writing-for-agents
```

[Source](https://github.com/witify/skills/tree/main/skills/productivity/writing-for-agents)

## What it does

`writing-for-agents` is the reference you write against whenever a document's reader is an agent — a skill, an `AGENTS.md` / `CLAUDE.md`, a doc reached by a pointer. The packaging differs but the writing does not: the same levers make each one predictable, meaning the agent takes the same *process* every run, not the same output.

It used to be called `writing-great-skills`; the rename tracks its widened scope — skills are now one branch of it, with the skill-specific mechanics (frontmatter, invocation choice, router skills) disclosed to a linked `SKILL-MECHANICS.md`.

## When to reach for it

Type `/writing-for-agents`, or the agent reaches for it automatically when creating or editing a skill, or modifying an `AGENTS.md` or `CLAUDE.md`.

Reach for it for *anything your agents read*: authoring a new skill, editing an existing one, shaping a repo's agent instructions, or diagnosing why a document misfires. For a project-local coding rule that belongs in that repo's own agent context, use [create-guideline](../engineering/create-guideline.md) instead.

## The two loads

The concept the whole reference turns on is a pair of budgets every document and pointer spends:

- **Context load** — the cost of always-loaded material on the agent's window: an `AGENTS.md` line, a skill description, anything sitting in context every turn whether or not it fires.
- **Cognitive load** — the cost on the human: which documents exist and when to reach for each. Not a cost to minimise — it is the price of human agency; spend it where human judgement matters.

Once you're thinking in these two loads, most authoring decisions — split or don't, inline or disclose, model- or user-invoked — become the same trade made in different places.

## The other levers

The rest of the reference is the toolkit for spending those loads well:

- **Context pointers** — the reference in context that names out-of-context material and encodes when to reach it. The pointer's *wording*, not its target, decides how reliably the agent gets there.
- **Information hierarchy** — the ladder from in-file step, to in-file reference, to disclosed reference behind a pointer. **Progressive disclosure** is the move down that ladder so the top stays legible; **co-location** decides what sits beside a piece once it lands.
- **Leading words** — a compact concept already in the model's pretraining (_tight_, _red_, _tracer bullet_) that the agent thinks with while running the document.
- **Pruning** — single source of truth, relevance, and the no-op test applied sentence by sentence, against **sediment** and **sprawl**.

## On Laravel Boost projects

When the repo uses [Laravel Boost](https://laravel.com/docs/boost), the reference carries one extra rule: the editable source of a skill is `.ai/skills/<name>/SKILL.md`, republished with `php artisan boost:update` — the generated agent files (`CLAUDE.md`, `AGENTS.md`, the per-agent skill copies) are never edited directly, and agent instructions go in `.ai/guidelines/`.

## Where it fits

This is a reach-for-it-anytime standalone reference — the meta-skill you consult while building the rest of the set, not a step in a chain. Its neighbour is [create-guideline](../engineering/create-guideline.md), because that skill writes the project-local rules this one teaches you to word; when you're unsure which skill or flow fits a task, [ask-witify](../engineering/ask-witify.md) routes you over the whole set.

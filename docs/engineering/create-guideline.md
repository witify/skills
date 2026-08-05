Quickstart:

```bash
npx skills add witify/skills --skill=create-guideline
```

```bash
npx skills update create-guideline
```

[Source](https://github.com/witify/skills/tree/main/skills/engineering/create-guideline)

## What it does

`create-guideline` writes or updates a coding rule in a project's `.ai/guidelines/` directory (the Laravel Boost convention) and syncs it with `php artisan boost:update`. Guidelines are injected into LLM context on every session, so the skill optimizes for **token economy**: lead with the rule, bullets over paragraphs, a code example only when the rule alone isn't enough.

## When to reach for it

Type `/create-guideline`, or the agent reaches for it when you ask to "add a rule for…" or mention `.ai/guidelines/`.

Reach for it when the rule is project-local and belongs in that repo's own agent context. For a reusable skill in *this* repo instead, use [writing-for-agents](../productivity/writing-for-agents.md).

## Prerequisites

A project with a `.ai/guidelines/` directory — every sprintify-derived project has one. Without it, the skill asks where rules live rather than creating the directory uninvited.

## Where it fits

`create-guideline` is a **reach-for-it-anytime standalone** in the sprintify-baseline family — the way a lesson learned mid-session becomes a durable rule for the next one. When you're unsure which skill fits, [ask-witify](./ask-witify.md) routes you.

Quickstart:

```bash
npx skills add witify/skills --skill=larastan
```

```bash
npx skills update larastan
```

[Source](https://github.com/witify/skills/tree/main/skills/engineering/larastan)

## What it does

`larastan` is the PHPStan/Larastan cheat sheet for Laravel type-level work: the exact **generics** for relationships (`BelongsTo<User, $this>`), factories, custom query builders, collections, and `Attribute` accessors, plus the pitfalls (`whereHas` builder narrowing, `@var` overuse, scope methods that must return `static` with `@return $this`). It fixes to the project's configured strictness, not an ideal one — it reads `phpstan.neon` for the level, baseline, and custom rules first, and only recommends the Laravel 11 `HasBuilder`/`HasCollection` traits where the framework version allows them.

## When to reach for it

Type `/larastan`, or the agent reaches for it automatically when fixing PHPStan errors or writing generic PHPDoc annotations on models, builders, factories, or collections.

## Prerequisites

A Laravel project with `larastan/larastan` and a `phpstan.neon`.

## Where it fits

`larastan` is a **reach-for-it-anytime standalone** in the sprintify-baseline family — the reference the building skills lean on whenever static analysis complains. When you're unsure which skill fits, [ask-witify](./ask-witify.md) routes you.

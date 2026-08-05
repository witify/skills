Quickstart:

```bash
npx skills add witify/skills --skill=translations
```

```bash
npx skills update translations
```

[Source](https://github.com/witify/skills/tree/main/skills/engineering/translations)

## What it does

`translations` decides where every translation key lives in a sprintify-derived project and how it's written: PHP files for Laravel-only messages (`response.php` for everything user-facing, `validation.php` only for field rules), JSON files for keys shared between Vue and Laravel, module lang files under their `modules.{slug}.*` namespace, and `{arg}` interpolation in shared JSON because Vue can't read Laravel's `:arg`. The flat-JSON discipline — every shared key a literal flat dot-joined string, never a nested object — applies only where the project enforces it; on older forks the skill matches the existing style of the file instead of retrofitting.

## When to reach for it

Type `/translations`, or the agent reaches for it automatically when adding, moving, or deleting translation keys, editing `lang/` files, or throwing translated business-rule errors.

## Prerequisites

A sprintify-derived Laravel + Vue project with the shared `lang/` layout.

## Where it fits

`translations` is a **reach-for-it-anytime standalone** in the sprintify-baseline family — a reference layer under nearly everything, since every user-facing string built by the other skills ends up as a key it places. [audits](./audits.md) and [notification-development](./notification-development.md) both route their keys through it, and [frontend-development](./frontend-development.md)'s every-string-is-a-key rule lands here. When you're unsure which skill fits, [ask-witify](./ask-witify.md) routes you.

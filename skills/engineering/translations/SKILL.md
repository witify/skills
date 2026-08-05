---
name: translations
description: Translation file conventions, key placement (PHP vs JSON), cleanup rules, interpolation syntax, and shared Vue/Laravel JSON files. Activates when adding, moving, or deleting translation keys, editing lang files, using __() or $t(), throwing BusinessRuleException with messages, or working with i18n.
---

# Translations

## Applicability (check first)

- If the project ships its own `.ai/skills/translations/`, defer to that copy.
- The **file placement** table and the **`response.php` rules** apply to every sprintify-derived project.
- The **flat-JSON rules** apply only where the project enforces them: look for a `check-flat-lang` lint script or `flatJson: true` in the vue-i18n setup. On older forks without either, follow the existing key style of the file you're editing (often nested or free-form) and don't retrofit flatness.

## When to Activate

- When adding, editing, moving, or deleting translation keys.
- When editing any file under `lang/`, `modules/*/lang/`.
- When code uses `__()`, `$t()`, `trans()`, or `@lang`.
- When throwing `BusinessRuleException` or `abort()` with a translated message.
- When translating strings between English and French.

## Scope

- In scope: key placement (PHP vs JSON), file cleanup, interpolation syntax, domain terminology EN/FR.
- Out of scope: general Laravel translation mechanics.

## Translation File Locations

| Location                                              | Accessible from | Key prefix                           |
| ----------------------------------------------------- | --------------- | ------------------------------------ |
| `lang/en.json` / `lang/fr.json`                       | Vue + Laravel   | _(free-form, e.g. `admin.*`)_        |
| `lang/en/*.php` / `lang/fr/*.php`                     | Laravel only    | `filename.key`                       |
| `modules/*/lang/en.json` / `modules/*/lang/fr.json`   | Vue + Laravel   | `modules.{module_snake}.` (required) |
| `modules/*/lang/en/*.php` / `modules/*/lang/fr/*.php` | Laravel only    | `{module_name}::filename.key`        |

## JSON Translation Files Must Be Flat (where enforced)

On current sprintify, JSON lang files (central and module) must use **flat top-level keys only** — no nested objects. Laravel's JSON translator only resolves flat top-level keys, and `vue-i18n` is configured with `flatJson: true` so dotted lookups (`$t('admin.users.title')`) resolve against literal flat keys (`"admin.users.title": "..."`).

```json
// WRONG — Laravel's __() silently fails on nested objects
{ "admin": { "users": { "title": "Users" } } }

// CORRECT — flat dot-joined keys, reachable from both Vue and Laravel
{ "admin.users.title": "Users" }
```

The `check-flat-lang.js` lint (run by `npm run lint`) enforces three invariants:

1. **Flat keys** — every value in a `lang/*.json` must be a string, never a nested object.
2. **Module namespace** — every key in `modules/{Module}/lang/{locale}.json` must start with `modules.{module_snake}.` (e.g. `modules.account.*`, `modules.notification_preview.*`).
3. **No cross-file collisions** — a given key may appear in only one JSON file per locale (vue-i18n merges last-wins by glob order, which is silent and brittle).

When adding a key that logically belongs to a module, put it in that module's `lang/{locale}.json` under `modules.{slug}.*` rather than the central file.

On older forks without the lint or `flatJson`, match the existing style of the file instead — mixing flat and nested keys in one file is worse than either convention.

## Which PHP File to Use

- `response.php` — all user-facing messages: business rule errors, confirmation dialogs, success messages.
- `validation.php` `custom` section — form field validation messages only (e.g. `same_work_order`, `circular_dependency`).
- Never create per-model lang files (e.g. `production_task.php`). All model-specific messages belong in `response.php` under a nested model key:

```php
'production_task' => [
    'cannot_delete_in_current_status' => '...',
    'delete_confirmation_title' => '...',
],
```

- `BusinessRuleException` and `abort()` must use `response.*` keys, never `validation.custom.*`:

```php
throw new BusinessRuleException(__('response.production_task.cannot_update_in_current_status'));
```

## Keep Translation Files Clean

- When moving a key's usage from backend to frontend (e.g., `response.php` → `en.json`), delete the key from `response.php` once no PHP code references it.
- When moving a key's usage from frontend to backend (e.g., `en.json` → `response.php`), delete the key from `en.json` once no Vue code references it.
- Before deleting a key, grep both PHP and Vue/TS files to confirm it has no remaining usages.

## Interpolation Arguments in JSON Files

Laravel uses `:arg` syntax, Vue uses `{arg}` syntax. Since `.json` files are shared between Vue and Laravel, **always use Vue's `{arg}` syntax** in JSON translation files. Laravel's `__()` helper understands both formats, but Vue's `$t()` only understands `{arg}`.

```json
// WRONG — breaks in Vue
"welcome_user": "Welcome :name"

// CORRECT — works in both Vue and Laravel
"welcome_user": "Welcome {name}"
```

In `.php` translation files (Laravel only), use Laravel's `:arg` syntax as usual.

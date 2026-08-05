---
name: audits
description: Use the Audit module to record model audit trails — staging API (withAuditComment, withAuditValues, withAuditEvent, recordAudit, addCustomAudit), readable labels, retention, and the display layer. Activates when working with the Auditable trait, audit events, notes/comments on audits, or audit history UI.
---

# Audits

## Applicability (check first)

This skill describes the current sprintify baseline; projects forked from an older sprintify may lack parts of it. Check opportunistically — a file peek or one grep, not a full audit:

- If the project ships its own `.ai/skills/audits/`, defer to that copy — it matches the project's actual code.
- **Staging API present** (`withAuditComment` exists in the project's `Auditable` trait): apply the full skill.
- **Older Audit module** (a `modules/Audit/` or `src/Support/Audit/` without the staging API): apply only the principles that survive — blacklist with `$auditExclude`, secrets always excluded, readable values, one user action = one audit — through whatever API the trait actually exposes. Skip the staging recipes.
- **No Audit module at all**: skip this skill, say so, and don't scaffold the module uninvited.

## When to Activate

- Activate when a model's changes must be tracked or displayed as an audit trail / history timeline.
- Activate when code references `Modules\Audit\Traits\Auditable`, `AuditableInterface`, `withAuditComment`, `withAuditValues`, `withAuditEvent`, `recordAudit`, `addCustomAudit`, `GetModelAuditsAction`, `ModelAudits.vue`, or `ModelAuditsValue.vue`.
- Activate when adding semantic audit events (status transitions), audit notes, relation-change auditing, or changing audit retention (`audit:prune`).

## Scope

- In scope: making a model auditable, recording audits (standard, merged, semantic, note-only, custom), readable labels, audit display, retention, audit tests.
- Out of scope: the owen-it/laravel-auditing package internals, activity logging unrelated to Eloquent models.

## Core Principles

1. **One user action = one audit row.** Column changes, relation changes, and the note must land in a SINGLE audit. Never record separate audits for columns and relations, and never duplicate the note across rows.
2. **Blacklist, never whitelist.** Always exclude columns from auditing with `$auditExclude` (blacklist). Never use `$auditInclude` (whitelist): a whitelist silently stops auditing columns added later, and forgetting to audit a new column is worse than auditing one too many.
3. **Readable values.** Raw foreign keys are stripped at display time; declare `auditBelongsToRelations()` so changes show as labels (`status: Draft → Scoping`), and store relation diffs as human-readable strings.
4. **Stage, then fire.** All audit metadata is staged one-shot on the model and consumed by the NEXT audit — whether a standard save or an explicit `recordAudit()` fires it.
5. **The module is shared across projects.** Everything under `modules/Audit/` must stay domain-independent: no domain class references, no app-specific behavior, fixture-based tests only. Domain-specific audit code (event consts, `$auditExclude` lists, domain tests) belongs on the models and in `tests/Feature/`.

## Making a Model Auditable

1. Use `Modules\Audit\Traits\Auditable` (never `OwenIt\Auditing\Auditable` directly) and implement `Modules\Audit\Interfaces\AuditableInterface`.
2. Declare semantic event names as `const AUDIT_EVENT_*` on the model — never magic strings, and never on an Action.
3. Declare `auditBelongsToRelations()` for every audited belongsTo: `['status' => 'label', 'preparedBy' => 'full_name']` (or a Closure). The trait injects the resolved label next to the raw foreign key at write time, and `getAuditHidden()` strips the raw key at display time.
4. Optionally declare `protected array $auditHidden` for extra keys the display layer must strip, and `auditHasManyRelations()` to merge children's created/deleted audits into the parent's trail.
5. To skip columns, use `protected $auditExclude = [...]` — see Core Principles: never `$auditInclude`. **Every secret** (password, tokens, credentials, verification codes) must be listed in `$auditExclude` or its value lands in the audits table — `$hidden` only protects audits while `audit.strict` is on, so never rely on it alone. See `User::$auditExclude`.
6. To display the trail, drop `ModelAudits.vue` on the model's page (see Display Layer) and add the translation keys.

## Staging API (one-shot, consumed by the next audit)

| Method | Purpose |
| --- | --- |
| `withAuditComment(?string)` | Free-text note persisted on the audit row's `comment` column. |
| `withAuditValues(array $old, array $new)` | Extra old/new values merged into the audit payload (e.g. relation diffs computed outside the model). |
| `withAuditEvent(string)` | Renames the next standard audit to a semantic event; the audit keeps the standard pipeline (dirty columns, exclusions, labels). |
| `recordAudit(string $event)` | Fires an audit NOW from the staged data. Escape hatch for the two cases `save()` cannot carry (see below) — never use it in a save flow. Identical non-empty payloads are skipped (duplicate guard, key order ignored recursively) and the staged data discarded. |
| `addCustomAudit(string $event, array $old = [], array $new = [])` | Sugar over `withAuditValues($old, $new)->recordAudit($event)` for call sites with nothing else to stage. Same guards, same `recordAudit()` rules. |

Staged data never leaks: each audit cycle consumes it. Staged VALUES are guaranteed: if a save emits no standard audit (nothing dirty), the trait's saved hook records them itself. A staged comment or event alone stays pending for the next audit (a comment never forces a row), as does everything staged through a `withoutAuditing()` save.

### `save()` vs `recordAudit()`

`save()` is the default: stage, save, done — the trait guarantees the audit. `recordAudit()` exists ONLY for the two audits no save can carry:

1. **Value-less events** (`noted`): the saved hook deliberately ignores comment-only staging, so an audit that says "nothing changed" must be recorded explicitly.
2. **No-save audits**: recording something about a model that is not being saved (e.g. its child rows were recalculated). Never call a no-op `save()` just to trigger the hook — that abuses a persistence call for an audit side effect and risks flushing unrelated dirty state.

If a `recordAudit()` call sits next to a `save()` on the same model, it is a smell: stage the data on the save instead.

## Recipes

**Save with a note** — the note rides the standard `updated` audit:

```php
$model->withAuditComment($note)->save();
```

**Columns + relations in one audit** — snapshot readable relation values before/after the syncs, diff, stage, save. The trait guarantees the staged values are recorded even when no column is dirty (its saved hook records them under the staged event, or `updated` by default):

```php
$model->withAuditValues($oldRelationValues, $newRelationValues)->withAuditComment($note)->save();
```

**Semantic transition** — a standard save renamed; every attribute filled with the transition is audited too, with labels:

```php
$model->fill(['status_id' => $newStatusId]);
$model->withAuditEvent(Model::AUDIT_EVENT_APPROVED)->withAuditComment($note)->save();
```

**Note-only audit** (nothing changed) — `noted` is value-less by design, allowed by `audit.allowed_empty_values`:

```php
$model->withAuditComment($note)->recordAudit(Model::AUDIT_EVENT_NOTED);
```

**Snapshot audit without a save** (e.g. recalculated child rows):

```php
$model->withAuditValues($oldSnapshots, $newSnapshots)->withAuditComment($comment)->recordAudit(self::AUDIT_EVENT);
```

**Custom audit without a save, nothing else to stage** — same as above, as one call (readable keys, never `*_id`):

```php
$model->addCustomAudit(Model::AUDIT_EVENT_UPDATED, oldValues: ['tags' => $oldTags], newValues: ['tags' => $newTags]);
```

## Display Layer

- Backend: `Modules\Audit\Actions\GetModelAuditsAction` paginates a model's audits (plus declared has-many children), stripping `getAuditHidden()` keys and every raw `*_id` key. Served by `api.audits.index` through `Modules\Audit\Resources\AuditResource`, which trims the audit's user to `id`, `full_name` and `avatar_url`.
- Frontend: `_modules_/Audit/vue/components/ModelAudits.vue` renders the timeline — pass `:model-type="model.resource_data.model_type"` and `:model-id="model.id"` (optionally `:event` to filter, `:label-width` for the field column). It shows an actor + sentence summary per row (`audit_action_*` translation keys), an avatar on `created`, the note under a comment block, and each value through `ModelAuditsValue.vue` (badges, yes/no booleans, JSON reader for objects). It exposes `fetch()` — call it through a `ref` to refresh the timeline after a save.
- The endpoint payload is typed by `resources/js/models/Audit.ts` (`Audit`, `AuditUser`) — extend it when the payload changes.
- **Never store raw `*_id` keys in custom audit values** — the display layer strips every `*_id` key, so the change would be invisible. Store readable labels instead.
- Event names and value keys are translated with `$t()` on the frontend: every new semantic event needs an `audit_action_{event}` JSON translation key (falls back to `audit_action_generic`), and every relation key stored in audit values needs its own key (see the `translations` skill). String VALUES are only translated when the key exists (`$te()` guard): free text renders as-is.

## Configuration

- New intentionally value-less events must be added to `audit.allowed_empty_values` in `config/audit.php`, otherwise the auditor discards them.
- Retention: `audit:prune` (scheduled weekly) deletes audits older than `audit.prune_after_months`.
- Tests must enable console auditing in `setUp()`: `config(['audit.console' => true]);`.
- Models instantiated during app bootstrap (e.g. `User`) boot BEFORE that `setUp()` override, so the vendor's boot-time gate skips their audit observer: tests for those models must also register it — `User::observe(AuditableObserver::class);`.

## Static Analysis

Current sprintify ships two PHPStan rules that validate the relation config on every `AuditableInterface` model: `auditBelongsToRelations()` keys must be `BelongsTo` methods, and `auditHasManyRelations()` values must be has-many relations whose related model is auditable (`phpstan/Rules/Audit*.php`). Older forks may not have them — don't rely on the rules catching mistakes there.

## Key Classes

- `Modules\Audit\Traits\Auditable` — the trait every auditable model uses; staging API + label injection.
- `Modules\Audit\Interfaces\AuditableInterface` — contract implemented by auditable models.
- `Modules\Audit\Actions\GetModelAuditsAction` — display-side query and value stripping.
- `Modules\Audit\Models\Audit` — the audit Eloquent model (module-internal; `user()` resolves the configured auth model).
- `Modules\Audit\QueryBuilders\AuditQueryBuilder` — audit queries (`prunable()`).
- `Modules\Audit\Resources\AuditResource` — endpoint serialization, trimmed user.
- `Modules\Audit\Commands\AuditPrune` — `audit:prune`, retention enforcement.
- `Modules\Audit\Snapshots\UserSnapshotResolver` — persists an acting-user snapshot on every audit row.

## Testing the Module

Module tests are domain-independent: they run on fixture tables and models under `modules/Audit/Tests/Fixtures/` (`AuditFixtureParent` & co., created by `InteractsWithAuditFixtures`). Extend the fixtures — never couple module tests to domain models. Domain-specific audit behavior (e.g. `User` exclusions) is tested in `tests/Feature/`.

## Reference Examples

Search the project for equivalents — these are the shapes to look for, not guaranteed paths:

- An upsert Action that merges columns + relations + note into one audit, with the no-dirty-columns fallback.
- A status-transition Action using `withAuditEvent()` for a semantic event.
- A snapshot audit without a save (recalculation-style `recordAudit()`).
- A model with event consts and `auditBelongsToRelations()`.
- `User::$auditExclude` for sensitive columns.
- `modules/Audit/Tests/AuditableTraitTest.php` — behavior of the staging API, `addCustomAudit()`, duplicate guard, and empty-values handling.

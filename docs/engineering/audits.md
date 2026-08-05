Quickstart:

```bash
npx skills add witify/skills --skill=audits
```

```bash
npx skills update audits
```

[Source](https://github.com/witify/skills/tree/main/skills/engineering/audits)

## What it does

`audits` is the reference for recording model audit trails with the sprintify Audit module: making a model auditable, the one-shot **staging API** (`withAuditComment`, `withAuditValues`, `withAuditEvent`, `recordAudit`, `addCustomAudit`), readable labels instead of raw foreign keys, retention, and the `ModelAudits.vue` timeline. It checks the base code before applying itself — on a project forked from an older sprintify it applies only the principles that survive (blacklist with `$auditExclude`, secrets always excluded, one user action = one audit row), and with no Audit module at all it skips and says so rather than scaffolding one.

## When to reach for it

Type `/audits`, or the agent reaches for it automatically when a model's changes must be tracked or displayed as a history timeline, or when code touches the `Auditable` trait, audit events, or audit notes.

## Prerequisites

A sprintify-derived Laravel project. The full skill needs the Audit module with its staging API; older forks get the principles-only fallback.

## One action, one row

The idea the whole skill defends: a single user action — columns changed, relations synced, a note typed — must land in a **single audit row**, staged on the model and consumed by the next save. The recipes exist so nobody records separate audits for columns and relations, or calls `recordAudit()` where a `save()` already carries the data.

## Where it fits

`audits` is a **reach-for-it-anytime standalone** in the sprintify-baseline family — a reference layer picked up while building features that touch tracked models. Audit events and value keys need translation keys, so it leans on [translations](./translations.md). When you're unsure which skill fits, [ask-witify](./ask-witify.md) routes you.

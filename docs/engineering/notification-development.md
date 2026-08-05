Quickstart:

```bash
npx skills add witify/skills --skill=notification-development
```

```bash
npx skills update notification-development
```

[Source](https://github.com/witify/skills/tree/main/skills/engineering/notification-development)

## What it does

`notification-development` is the reference for **Herald**, sprintify's notification layer: each notification declares its channels, content, previews, and user-facing settings once in a `HeraldOptions` object — `via()`, `toMail()`, and `toDatabase()` are never overridden, because the trait and options own delivery. It covers builder-based editable content, null-safe variables for previews, per-channel user toggles, and registration in the `Notifications` enum. The skill is all-or-nothing: it verifies Herald exists first, and on a project that predates it, it skips entirely and writes plain Laravel notifications instead — it never ports the module uninvited.

## When to reach for it

Type `/notification-development`, or the agent reaches for it automatically when creating or changing notifications, channels, previews, or notification settings.

## Prerequisites

A sprintify-derived Laravel project recent enough to ship Herald (`modules/NotificationPreview/Herald/`). Absent that, the skill stands down.

## Where it fits

`notification-development` is a **reach-for-it-anytime standalone** in the sprintify-baseline family. Jobs that send notifications are [jobs-development](./jobs-development.md)'s territory; notification strings follow [translations](./translations.md). When you're unsure which skill fits, [ask-witify](./ask-witify.md) routes you.

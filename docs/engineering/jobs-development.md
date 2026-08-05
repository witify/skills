Quickstart:

```bash
npx skills add witify/skills --skill=jobs-development
```

```bash
npx skills update jobs-development
```

[Source](https://github.com/witify/skills/tree/main/skills/engineering/jobs-development)

## What it does

`jobs-development` holds the conventions for queued Laravel jobs on Redis + Horizon: the job as a thin orchestrator delegating to an Action, IDs and scalars only in the constructor, explicit timeouts, `ShouldBeUnique` where concurrency must be prevented, and exceptions left to bubble up to Sentry. It never assumes queue names — queue names and supervisor timeouts vary with a fork's age, so it reads the project's own `config/horizon.php` and routes each job to the queue whose timeout fits its worst case.

## When to reach for it

Type `/jobs-development`, or the agent reaches for it automatically when creating, editing, or dispatching a `ShouldQueue` class, or configuring queues and Horizon supervisors.

## Prerequisites

A sprintify-derived Laravel project running Redis + Horizon.

## Idempotence first

The non-negotiable the checklist is built around: jobs get retried, so **running twice must not double-send, double-create, or corrupt state**. The pattern is to flip the guard flag *before* the side effect, and to prove it with a feature test that runs the job twice and asserts the side effect happened once.

## Where it fits

`jobs-development` is a **reach-for-it-anytime standalone** in the sprintify-baseline family, picked up whenever built features need background work. Notifications a job sends are [notification-development](./notification-development.md)'s territory; the business logic itself belongs in an Action, not the job. When you're unsure which skill fits, [ask-witify](./ask-witify.md) routes you.

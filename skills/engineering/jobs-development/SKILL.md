---
name: jobs-development
description: Conventions for writing Laravel jobs on Redis + Horizon — idempotence, ShouldBeUnique, timeouts, after_commit, queue selection by duration, and error handling. Activates when creating, editing, or dispatching jobs.
---

# Jobs Development (Redis + Horizon)

## Applicability (check first)

- If the project ships its own `.ai/skills/jobs-development/`, defer to that copy.
- The core rules (idempotence, thin jobs, timeouts, `retry_after > timeout`) apply to every project running Redis + Horizon.
- **Queue names and supervisors vary by project age.** Current sprintify has `default` / `long` / `extra-long`; older forks have other sets (e.g. `default` / `parallel` / `long`). Always read `config/horizon.php` and `config/queue.php` to learn the project's actual queues before routing a job — never assume a queue name from this skill exists.
- `after_commit` may not be set on older forks: **verify it** on the connection instead of assuming; if it's off, flag it to the user (or dispatch with `->afterCommit()` explicitly).

## When to Activate

- Activate when creating, editing, or dispatching a queued job (any class implementing `ShouldQueue`).
- Activate when code uses `dispatch()`, `Bus::`, `->onQueue(...)`, `ShouldBeUnique`, or `ShouldBeUniqueUntilProcessing`.
- Activate when configuring `config/queue.php`, `config/horizon.php`, or adding a new Horizon supervisor.
- Activate when the user mentions jobs, queues, workers, Horizon, retries, or timeouts.

## Scope

- In scope: job class structure, idempotence, uniqueness, timeouts, retries, queue selection, Horizon supervisor config, tags, error handling.
- Out of scope: Herald notifications (use the `notification-development` skill), business logic itself (belongs in Actions), Pulse monitoring.

## Workflow

1. Create the job under `src/Domain/{Domain}/Jobs/` (or `modules/{Module}/Jobs/`) with `php artisan make:job` and fix the namespace if needed.
2. Make the job a thin orchestrator — delegate logic to a `\Support\Action\Action` class in the matching domain.
3. Pass only **IDs and scalars** through the constructor (no Actions, big arrays, collections, or DTOs). Eloquent models are OK via `SerializesModels`.
4. Add **idempotence**: check a `processed_at` / flag / operation id before doing the work, and set it before triggering the side effect.
5. If the job must not run concurrently, implement `ShouldBeUnique` (or `ShouldBeUniqueUntilProcessing`) with a meaningful `uniqueId()` and a sensible `$uniqueFor`.
6. Set `public int $timeout` and `public bool $failOnTimeout = true` on every job.
7. Pick the queue by **expected max duration**: read `config/horizon.php` to see which queues exist and what timeout each supervisor allows, then route via `->onQueue('...')` to the queue whose timeout fits the job's worst case. In current sprintify that's `default` (60s), `long` (≤2h, `redis-long` connection), `extra-long` (≤12h, `redis-extra-long` connection) — but use the project's actual set.
8. Add Horizon `tags()` for traceability (`customer:{id}`, feature name, etc.).
9. Let exceptions bubble up — Sentry catches them through Horizon. Only implement `failed(Throwable $e)` for genuinely additional logic.
10. Verify `retry_after` in `config/queue.php` is **strictly greater** than the largest `$timeout` of any job on that queue.
11. Verify the connection has `'after_commit' => true` in `config/queue.php`; if it doesn't (older fork), flag it and use `->afterCommit()` on the dispatch.
12. Write a feature test that dispatches the job (or calls `handle()` directly) and asserts the side effect happens once even when run twice.

## Key Rules

- **Idempotence is mandatory.** Jobs can be retried; running twice must not double-send, double-create, or corrupt state.
- **No business logic in the job.** The job orchestrates; the Action does the work.
- **No complex objects in the constructor.** Serialized payload goes to Redis — keep it tiny.
- **`after_commit` should always be on.** Never disable it; on projects where it's missing, dispatch with `->afterCommit()`.
- **`retry_after > max(timeout)`** for every queue. See https://laravel.com/docs/12.x/queues#job-expiration.
- **Don't catch to swallow.** Let exceptions fail the job so Horizon + Sentry see them.
- **Long jobs never run on `default`.** Pick the queue whose supervisor timeout fits the job's worst case — from the project's own `config/horizon.php`, never invented.

## Job Skeleton

```php
namespace Domain\Demo\Jobs;

use Domain\Demo\Actions\SyncCustomerAction;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldBeUnique;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class SyncCustomerJob implements ShouldQueue, ShouldBeUnique
{
    use Dispatchable;
    use InteractsWithQueue;
    use Queueable;
    use SerializesModels;

    public int $timeout = 45;

    public bool $failOnTimeout = true;

    public int $tries = 1;

    public int $uniqueFor = 3600;

    public function __construct(public int $customerId)
    {
        $this->onQueue('default');
    }

    public function uniqueId(): string
    {
        return (string) $this->customerId;
    }

    public function handle(SyncCustomerAction $action): void
    {
        $action->execute($this->customerId);
    }

    /**
     * @return array<int, string>
     */
    public function tags(): array
    {
        return [
            'customer:'.$this->customerId,
            'sync',
        ];
    }
}
```

## Idempotence Pattern

```php
public function handle(): void
{
    if ($this->user->onboarding_notification_sent) {
        return;
    }

    // Flip the flag BEFORE the side effect so a retry after a partial failure
    // does not re-send the notification.
    $this->user->onboarding_notification_sent = true;
    $this->user->save();

    $this->user->notify(new OnboardingNotification);
}
```

## Long-Running Jobs

Route to the project's long-duration queue (in current sprintify: `long` for ≤2h, `extra-long` for ≤12h). The matching supervisors and connections already exist in `config/horizon.php` and `config/queue.php` — use those, do not invent new queue names. If the project has no queue whose timeout fits the job, raise it with the user instead of silently overloading `default`.

```php
public int $timeout = 1800; // 30 min — must stay below the queue's supervisor timeout

public bool $failOnTimeout = true;

public int $tries = 1;

public function __construct(public int $userId)
{
    $this->onQueue('long');
}
```

## Checklist

- [ ] Idempotent — safe to run twice.
- [ ] No business logic in the job; delegated to an Action.
- [ ] `ShouldBeUnique` (or `ShouldBeUniqueUntilProcessing`) when concurrency must be prevented.
- [ ] Constructor takes only IDs / scalars (or models via `SerializesModels`).
- [ ] `$timeout` set explicitly.
- [ ] `$failOnTimeout = true`.
- [ ] `retry_after` in `config/queue.php` > max timeout on that queue.
- [ ] `after_commit => true` on the connection (or `->afterCommit()` on the dispatch).
- [ ] Queue chosen from the project's `config/horizon.php` based on max duration.
- [ ] `tags()` added for Horizon traceability.
- [ ] Exceptions allowed to bubble up to Sentry; `failed()` only when truly needed.
- [ ] Feature test asserting the side effect runs once even when retried.

## Reference Files

- `config/queue.php` — the project's connections, each with its own `retry_after` (and, on current sprintify, `after_commit`).
- `config/horizon.php` — the project's supervisors: which queues exist and each one's timeout. Read it, don't assume.
- `src/App/Providers/HorizonServiceProvider.php` — Horizon authorization gate.

Quickstart:

```bash
npx skills add witify/skills --skill=confirm-request
```

```bash
npx skills update confirm-request
```

[Source](https://github.com/witify/skills/tree/main/skills/engineering/confirm-request)

## What it does

`confirm-request` adds "are you sure?" dialogs — optionally password-protected — before sensitive endpoint actions, using sprintify's `confirmRequest()` flow: the backend answers HTTP 428 with a **server-enforced** flow/token pair, and an axios interceptor shows the dialog and replays the request with no frontend code at all. The confirmation cannot be skipped client-side. The skill is all-or-nothing: it verifies both halves of the flow exist (the `ConfirmRequest` backend class and the `http.ts` interceptor), and on a project that predates them it skips entirely and builds an ordinary explicit dialog instead — it never ports the module uninvited.

## When to reach for it

Type `/confirm-request`, or the agent reaches for it automatically when an endpoint needs a confirmation or password re-check before a destructive action, or when code shows 428 responses, `confirmation_required`, or `X-Confirmation-*` headers.

## Prerequisites

A sprintify-derived Laravel project recent enough to ship the confirmation flow (`Support\Http\Confirmation\` plus the interceptor). Absent that, the skill stands down.

## Where it fits

`confirm-request` is a **reach-for-it-anytime standalone** in the sprintify-baseline family. [authorization](./authorization.md) is the neighbour on the same boundary — authorization decides *whether* a user may act, confirm-request double-checks that they *mean it*. When you're unsure which skill fits, [ask-witify](./ask-witify.md) routes you.

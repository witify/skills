---
name: confirm-request
description: Add confirmation dialogs (optionally password-protected) before sensitive endpoint actions using confirmRequest() and the automatic frontend replay. Activates when working with confirmRequest, confirmation_required, X-Confirmation headers, or "are you sure" / password-confirmation flows.
---

# Confirm Request

## Applicability (check first)

This skill depends entirely on the confirmation flow shipped in sprintify's base code. Check opportunistically:

- If the project ships its own `.ai/skills/confirm-request/`, defer to that copy.
- Verify **both halves** exist: `src/Support/Http/Confirmation/ConfirmRequest.php` (backend) and a `confirmRequest` interceptor in `resources/js/services/http.ts` (frontend replay).
- If either is missing (the project forked before this flow existed): **skip this skill entirely**, tell the user the project predates `confirmRequest()`, and build the confirmation as an ordinary explicit frontend dialog instead. Don't port the module uninvited.

## When to Activate

- An endpoint needs an "are you sure?" confirmation or a password re-check before a destructive or sensitive action (email change, TFA changes, logging out other sessions, deletions with side effects).
- You see `$this->confirmRequest(...)`, `ConfirmationHttpException`, `code: 'confirmation_required'`, HTTP 428 responses, or `X-Confirmation-*` headers.

## Scope

- In scope: backend usage of `confirmRequest()`, its HTTP contract, and how to test it.
- Out of scope: generic sprintify-ui dialogs (`useDialogsStore`), authorization (policies — see the `authorization` skill).

## How It Works

1. The controller calls `$this->confirmRequest(...)` **before** performing the side effect.
2. First request: throws `ConfirmationHttpException` → HTTP **428** `{ code: 'confirmation_required', confirmation: { flow, token, title, message, errorMessage, confirmText, cancelText, requiresPassword } }`. Never reported to Sentry.
3. The confirmation is **server-enforced**: `flow` is a fingerprint of user + method + path + normalized payload, and `token` is a random value stored in the session (10-minute TTL). The replay must send `X-Confirmation-Flow` and `X-Confirmation-Token` matching the session state — a client cannot skip the dialog, and changing the payload between dialog and replay invalidates the confirmation.
4. Frontend: **no code needed.** The `confirmRequest` axios interceptor (`resources/js/services/http.ts`) shows a sprintify-ui dialog (password input when `requiresPassword`) and replays the same request with the flow/token headers, accumulating tokens for multi-step confirmations. The calling code transparently receives the replayed response; on cancel the original promise rejects.
5. Replayed request: `confirmRequest()` returns `true` — or, when `requiresPassword`, verifies `X-Confirmation-Password` against the authenticated user (`Hash::check`, rate-limited to 3 attempts per URL) and returns the plaintext password (e.g. for `Auth::logoutOtherDevices($password)`).
6. An endpoint may call `confirmRequest()` several times for chained confirmations — each call is a separate step with its own token, and the frontend re-prompts per step.
7. The `ClearConfirmationFlow` middleware (web group) deletes the flow from the session after any non-428 response, so confirmations are single-use.

## Workflow

1. In a controller extending `Support\Controller\Controller`, call `confirmRequest()` before the action:

```php
$this->confirmRequest(
    requiresPassword: true, // omit for a simple yes/no dialog
);
```

2. Pass translated strings for custom `title` / `message` / `confirmText` / `cancelText`; defaults come from `response.confirmation.*` (or the password-confirmation keys when `requiresPassword`).
3. Capture the return value only when you need the confirmed password: `$password = $this->confirmRequest(requiresPassword: true);`
4. Nothing to change on the frontend as long as the call goes through the shared `http` service.
5. Test with the `Tests\TestCase` helpers:
   - `requestWithConfirmation(fn (array $headers) => $this->postJson($url, $payload, $headers), password: $password)` — loops the 428 dance and returns the final response.
   - `confirmationHeadersFromResponse($response, $headers, $password)` — manual control over a single step (e.g. to test a wrong password → expect 428 with `confirmation.errorMessage`).
   - Confirmation is session-backed, so requests must go through the `web` middleware group.

## Key Classes

- `Support\Controller\Controller::confirmRequest()` — controller entry point.
- `Support\Http\Confirmation\ConfirmRequest` — flow/token issuance, session state, password verification, rate limiting.
- `Support\Http\Confirmation\ConfirmationHttpException` — renders the 428 `confirmation_required` payload.
- `Support\Http\Middlewares\ClearConfirmationFlow` — clears the flow after completed requests (web group).
- `resources/js/services/http.ts` (`confirmRequest` interceptor) — dialog + automatic replay with token accumulation.

## Reference Examples

Search the project for existing `confirmRequest()` call sites; typical ones:

- Simple confirmation: `modules/Account/Controllers/AccountTfaEmailController.php`.
- Using the returned password: `modules/Account/Controllers/AccountUserLoginController.php` (`logoutOtherSessions`).
- Test patterns (two-phase, wrong password, forged headers): `modules/Account/Tests/AccountTfaControllerTest.php`.

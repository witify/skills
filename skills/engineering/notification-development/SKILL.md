---
name: notification-development
description: Create, migrate, and manage Herald notifications from the witify/notifications package, including explicit mail/database channels, NotificationMessageBuilder content, previews, translations, tests, per-channel user settings, and Herald::register() registration.
---

# Notification Development (Herald)

Herald ships in the Composer package `witify/notifications`. Its README is the reference for installation, contracts, and the full API: read `vendor/witify/notifications/README.md` (or https://github.com/witify/notifications) before writing a notification. This skill only adds the project-side workflow.

## Applicability (check first)

- If the project ships its own `.ai/skills/notification-development/`, defer to that copy.
- Herald is installed when `vendor/witify/notifications/` exists. Namespaces are `Witify\Notifications\Herald\*`.
- A project not yet migrated still carries the module under `modules/NotificationPreview/Herald/` with the `Modules\NotificationPreview\Herald\*` namespaces and a `Modules\Notification\Notifications` enum. Follow the same workflow with those names, and do not copy the package into `modules/`.
- If neither exists (the project forked before Herald): **skip this skill entirely**, tell the user the project predates Herald, and write plain Laravel notifications (`via()`, `toMail()`, `toDatabase()`) following the project's existing notification classes. Don't port Herald uninvited.

Never edit `vendor/witify/`. A change to Herald itself goes in a pull request to the `witify/packages` monorepo (`packages/notifications`), then a Composer update in the project.

## Workflow

1. Extend `Illuminate\Notifications\Notification` (or an existing Laravel notification base), implement `HeraldNotification`, and use `HeraldNotificationTrait`.
2. Define `public static function herald(): HeraldOptions`.
3. Set translated `->title()`, `->description()`, and the matching domain `->group()`.
4. Choose settings:
    - Use `->toggleable(true)` for notifications users may enable per channel.
    - Use `->toggleable(false)` for required, system, or internal notifications.
    - Use `->customizable(true)` when admins may edit the channel content.
    - Ask the user when either choice is unclear.
5. Add a `->variables()` closure that handles `$notification === null`; previews and default-message generation call it without a real notification.
6. Declare each supported channel explicitly with `->mail(...)` and/or `->database(...)`.
7. Prefer `NotificationMessageBuilder` for customizable or previewable default content.
8. Add `->previews(...)`. Returning an empty array makes Herald generate a default preview from null-safe variables and builder closures.
9. Add `notifications.*` translations to `lang/en/notifications.php` and `lang/fr/notifications.php`; use the equivalent module PHP files for namespaced module keys.
10. Register the class in `Herald::register([...])` of `AppServiceProvider`, under a descriptive snake_case key. The key names the notification in the stored user settings: never rename it once deployed.
11. Add focused tests for supported channels, rendered variables, default/custom content, previews, and registration.

## Channel Rules

- Derive support from `HeraldOptions`: `->mail(...)` enables mail and `->database(...)` enables in-app delivery.
- Do not override `via()`, `toMail()`, or `toDatabase()`; the trait and options own delivery.
- Do not infer database support with `method_exists()`.
- Expose user switches only for `supported_channels`.
- Store user preferences as `[{ key, channels: { mail, database } }]`.
- Intersect supported channels with user-enabled channels in `GetUserNotificationsAction`.
- Send database notifications only to a persisted `HeraldUser` or a `HeraldNotifiable` containing a user.
- Use `url` for absolute links and `path` for internal application routes.
- Include `model(...)` when the database notification concerns an Eloquent model.
- Do not use the removed `configurable()` or `defaultNotificationMessages()` APIs.

## Variables and Content

Builder templates resolve `:variable` and nested `:model.attribute` placeholders. `first_name`, `full_name`, `email`, `company_name` and `me` (the sender) are always available.

Escape untrusted variable content before returning it because customized database content is rendered as HTML:

```php
return [
    'email' => e($data['email']),
    'message' => nl2br(e($data['message'])),
];
```

Use the builder when defaults need to remain editable. In these closures, annotate the contract as the concrete notification before reading its model property:

```php
HeraldOptions::make(self::class)
    ->title(__('notifications.scope.name.title'))
    ->description(__('notifications.scope.name.description'))
    ->group(__('notifications.groups.orders'))
    ->toggleable(true)
    ->customizable(true)
    ->variables(function (?HeraldNotification $notification, HeraldNotifiable $notifiable): array {
        /** @var self|null $notification */
        $model = $notification?->model;
        $path = $model instanceof \Witify\Support\Model\IsResource
            ? $model->getResourceAdminTo()
            : null;

        return [
            'model' => [
                'title' => $model?->title ?? 'TEST',
            ],
            'url' => $path ? url($path) : url('/admin'),
            'path' => $path,
        ];
    })
    ->mail(function () {
        return NotificationMessageBuilder::mail()
            ->subject(__('notifications.scope.name.subject'))
            ->message(__('notifications.scope.name.message'))
            ->action(__('notifications.scope.name.action'), ':url');
    })
    ->database(function (?HeraldNotification $notification) {
        /** @var self|null $notification */

        return NotificationMessageBuilder::database()
            ->message(__('notifications.scope.name.database_message'))
            ->model($notification?->model)
            ->url(':url')
            ->path(':path');
    })
    ->previews(fn (): array => []);
```

Direct `MailMessage` returns remain valid for required mail-only notifications that are not customizable.

Use `getResourceAdminTo()` only for models implementing `Witify\Support\Model\IsResource`; otherwise build a real named route and internal path for that domain.

Supporting a channel and allowing users to toggle it are separate choices. Declare both channels when required, then ask whether `toggleable` should be enabled when the request does not say.

## Key Classes

- `Illuminate\Notifications\Notification`: Laravel notification base class.
- `Witify\Notifications\Herald\Herald`: registry (`register()`), timezone and locale resolvers.
- `Witify\Notifications\Herald\HeraldUser`: contract the application user model implements.
- `Witify\Notifications\Herald\HeraldNotification`: Herald contract.
- `Witify\Notifications\Herald\HeraldNotificationTrait`: queueing, channel delivery, sender capture, and previews.
- `Witify\Notifications\Herald\HeraldOptions`: metadata, channel support, content, previews, throttling, and scheduling.
- `Witify\Notifications\Herald\NotificationMessageBuilder`: mail/database subject, message, action, model, URL, and path.
- `Witify\Notifications\Herald\NotificationPreview`: named concrete preview.
- `Witify\Notifications\Actions\GetUserNotificationsAction`: supported and enabled user channels.

Use `modules/Auth/Notifications/ResetPasswordNotification.php` of the project as the required mail-only reference. Use the `BuilderHeraldNotification` fixture in `vendor/witify/notifications/tests/Fixtures/` and the "Writing a notification" section of the package README as the customizable mail/database reference.

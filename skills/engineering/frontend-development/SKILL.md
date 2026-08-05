---
name: frontend-development
description: Vue 3 + Tailwind frontend patterns — reactivity after emits, sub-form communication, form resets, orphan validation errors, responsiveness — plus sprintify app conventions (shared backend data, settings store, resource_data, tabulation tables). Use when building or modifying Vue components, frontend forms, interactive UI, or making a screen fit a phone.
---

# Frontend Development

Patterns for building Vue 3 + Tailwind interfaces. This skill is all reference — apply every rule that touches the code you're writing.

## Conventions

- Type props and emits explicitly.
- Reuse before creating: check the project's UI kit and existing stores before writing a new component or store, and prefer the kit's components (button, field, badge…) over raw HTML elements. When the project depends on `sprintify-ui`, run `/sprintify-ui` for the component catalog and props rather than guessing an API.
- Every user-facing string is a translation key, present in every locale file the project ships. Check whether a key already exists before adding one.

### Never use the `title` attribute

`title` is invisible on touch devices, cannot be styled, and appears only after a browser-controlled delay. Use the kit's tooltip instead — never the attribute:

```vue
<!-- WRONG — native tooltip -->
<BaseButton :title="$t('users.edit')" icon="pencil" />

<!-- CORRECT — the component already takes a tooltip -->
<BaseButton :tooltip="$t('users.edit')" icon="pencil" />
```

Reach for `BaseTooltip` only when the element has no tooltip prop of its own. It renders a `div`, which breaks inline flow and flex alignment — pass `as="span"` when wrapping inline content:

```vue
<p>
    {{ $t("invoices.total") }}
    <BaseTooltip :text="$t('invoices.total_hint')" as="span">
        <BaseIcon icon="lucide:info" />
    </BaseTooltip>
</p>
```

## Reactivity

### Read props after an emit with `nextTick`

Props do not update synchronously after an emit — the parent must process the new value first. Any follow-up that reads the updated prop goes in `nextTick`:

```ts
// WRONG — props.modelValue is still the old value
emit("update:modelValue", updated);
ensureOneEmptyItem();

// CORRECT — wait for the parent to update props
emit("update:modelValue", updated);
nextTick(() => ensureOneEmptyItem());
```

For dynamic lists where users fill rows one by one, that follow-up is typically a guard that keeps one empty row available — call it after each selection (inside `nextTick`) and once on mount via `watch(…, { immediate: true })`.

## Forms

### Sub-forms emit copies

A sub-form component edits its parent's data, so `v-model` on the prop would mutate the parent's state directly. Bind `:model-value`, and on change emit a cloned, modified copy:

```vue
<BaseInput
    :model-value="modelValue[i].quantity"
    @update:model-value="onUpdate('quantity', i, $event)"
/>
```

```ts
function onUpdate(field: string, index: number, value: unknown) {
    const updated = cloneDeep(props.modelValue);
    updated[index] = { ...updated[index], [field]: value };
    emit("update:modelValue", updated);
}
```

### Reset from a `DEFAULT_FORM` constant

When a form resets (modal re-open, route change), build fresh copies from a constant with `cloneDeep`, so nested objects never share references:

```ts
const DEFAULT_FORM = {
    name: null as string | null,
    options: {} as Record<number, string>,
};

const form = ref(cloneDeep(DEFAULT_FORM));

watch(
    () => props.model,
    () => {
        form.value = cloneDeep(DEFAULT_FORM);
        if (props.model) form.value = fillFields(form.value, props.model);
    },
    { immediate: true },
);
```

### Surface orphan validation errors

Field components display only the errors whose key matches their `name`. Backend error keys that no rendered field matches — array-level (`lines`), wildcard (`ids.*`), nested (`lines.*.resource_id`) — are invisible to the user. When adding or reviewing validation, check every error key the backend can produce against the form's fields, and surface the orphans:

- **Text errors** — an alert component near the relevant section.
- **Wildcard/nested keys** — match by prefix:

```ts
function firstErrorByPrefix(errors: Record<string, string[]>, prefix: string): string | null {
    const key = Object.keys(errors).find((k) => k.startsWith(prefix));
    return key ? (errors[key]?.[0] ?? null) : null;
}
```

- **Non-text elements** (avatar groups, icons) — a red background or border cue on the element.

## Responsive layout

### Mobile-first: unprefixed classes are the phone layout

Unprefixed utilities apply at every width; breakpoint prefixes (`sm:`, `md:`, `lg:`…) apply from that width **up**. So write the phone layout with unprefixed classes and widen from there — never write the desktop layout first and patch it down with `max-*` variants:

```html
<!-- WRONG — desktop as the default, patched down -->
<div class="flex gap-8 max-md:flex-col max-md:gap-4">

<!-- CORRECT — phone as the default, widened up -->
<div class="flex flex-col gap-4 md:flex-row md:gap-8">
```

### One breakpoint per layout shift

Most layouts have exactly one structural change: stacked on phones, side-by-side on wider screens. Pick the single breakpoint where the content actually breaks (usually `md:` or `lg:`) and put the whole shift there. Classes spread across `sm:`, `md:`, `lg:`, and `xl:` on one element are a smell — the in-between states are rarely designed, only accidental.

### Prefer fluid layouts over breakpoints

Breakpoints are for structural changes. For sizing, let the layout flex so it works at every width instead of a few tested ones:

- Card/tile grids: `grid grid-cols-[repeat(auto-fill,minmax(16rem,1fr))]` — column count adapts with no breakpoint at all.
- Rows of variable-count items (tags, filters, actions): `flex flex-wrap gap-2`.
- Content width: `w-full max-w-*` on the container, never a fixed `w-[…px]`.

### Contain overflow — the page never scrolls horizontally

- Anything intrinsically wide (tables, code blocks, wide charts) scrolls inside its own wrapper: `<div class="overflow-x-auto">…</div>`. Horizontal scroll on the page body is always a bug.
- A flex or grid child refuses to shrink below its content width, so `truncate` on it silently does nothing and long text blows the row out. Add `min-w-0`:

```html
<!-- WRONG — truncate has no effect, long names push the button off-screen -->
<div class="flex items-center gap-2">
    <span class="truncate">{{ item.name }}</span>
    <BaseButton />
</div>

<!-- CORRECT — the child may shrink, so truncate can act -->
<div class="flex items-center gap-2">
    <span class="min-w-0 truncate">{{ item.name }}</span>
    <BaseButton class="shrink-0" />
</div>
```

### Reflow one tree; don't fork the DOM per breakpoint

Prefer making a single element reflow (`flex-col md:flex-row`, responsive grid columns) over rendering two copies toggled with `hidden md:block` — duplicated trees drift apart as the screen evolves. Forking is only justified when the *structure* genuinely differs (a data table on desktop, cards on mobile); then keep both branches reading from the same computed data so only the markup is duplicated, never the logic.

## Tailwind

### Class names are static strings

Tailwind scans source files for complete class names at build time, so an interpolated name like `` `bg-${color}-500` `` never appears in the source and gets purged from the bundle. For dynamic colors, use a component that resolves the color internally (a `:color` prop) or bind an inline style:

```vue
<!-- WRONG — purged, never reaches the CSS bundle -->
<span :class="`bg-${row.color}-500`" />

<!-- CORRECT — inline style binding -->
<span :style="{ backgroundColor: colorFor(row.color) }" />
```

## Sprintify-derived projects

Everything above applies to any Vue 3 + Tailwind codebase. The patterns below depend on sprintify's base code — apply them on sprintify-derived projects, and verify the feature exists (a grep, not an audit) before relying on it; older forks may lack pieces. If the project ships its own `.ai/skills/frontend-development/`, defer to that copy.

### Conventions

- **Route helpers**: `$laravelRoute()` in `<template>`, `window.route()` in `<script>`. Never `window.route()` in templates.
- **Auto-imports**: `unplugin-auto-import` makes `computed`, `useI18n`, and `useHead` available without importing them — don't add manual imports.
- **`BaseButton` over raw `<button>`**, always. Never combine `<button>` + `<BaseIcon>` — use `BaseButton` with its `icon` prop.

### Shared backend data (`window.Laravel`)

Never hardcode arrays or option lists in Vue that already exist as constants on backend models. Share them via `ShareDataToClient` and consume through `window.Laravel`:

1. Add the constant to the model's `getSharedData()` method (Sushi models register in `ShareDataToClient` the same way).
2. Add the property to the model's type in `resources/js/window.d.ts`.
3. Read it in Vue: `window.Laravel.models.<model>.<key>`.

```php
// Model
public static function getSharedData(): array
{
    return [
        'icon' => static::getResourceIcon(),
        'colors' => static::COLORS,
    ];
}
```

```ts
// Vue
const colors = window.Laravel.models.tag.colors;
```

### User preferences: server-side settings, not localStorage

Never persist user preferences (panel open/closed state, view modes, saved filters) in `localStorage` — they're stuck in one browser and lost on a clear. Use `useSettingsStore()` (`resources/js/stores/settings.ts`): its `get`/`set` persist server-side on the user's `settings` JSON column through the `api.account.settings.*` endpoints, so preferences sync across devices. Define each key once in the store's `USER_SETTINGS_KEYS` const instead of scattering magic strings:

```ts
const settingsStore = useSettingsStore();

// Read a setting (with optional default)
const panelOpen = ref(settingsStore.get("my_feature_panel_open", true) !== false);

// Write a setting (async, persisted server-side)
watch(panelOpen, (v) => settingsStore.set("my_feature_panel_open", v));
```

On an older fork without the store (no `stores/settings.ts`), port it from the sprintify base — the store plus its account settings controller, routes, and the `settings` array cast on `User` — rather than reaching for `localStorage`.

### Eager loading via `include`

QueryBuilders define `allowedIncludes()` via Spatie Query Builder. Pass `include` as a query param to load relations on demand instead of always loading them — each consumer requests only what it needs:

```vue
:url="$laravelRoute('api.admin.items.index', { include: ['latestManufacturableBom'] })"
```

### Navigation via `resource_data`

When a model implements `IsResource` on the backend, its API response includes a `resource_data` object with navigation/display metadata. Use it instead of building URLs or titles manually:

```ts
// WRONG — hardcoded path
rowTo: (row: CollectionItem) => "boms/" + row.id,

// CORRECT — use resource_data
rowTo: (row: CollectionItem) => row.resource_data.admin_to,
```

### Percentage / coefficient inputs

For values stored as decimals where 1 = 100% (e.g. `speed_coefficient`, `profit_margin`), use `BaseInputPercent` instead of `BaseInput type="number"` — it handles the decimal-to-percentage conversion (model value 1 displays as 100%):

```vue
<BaseInputPercent v-model="form.speed_coefficient" :min="0" :max="200" class="w-full" />
```

### Tables: `tabulation` classes

The `sprintify-ui` table plugin styles plain `<table>` elements. Use `tabulation` for base styling (collapsed borders, bottom border, rounded corners, slate header background, bold headers), plus modifiers:

| Class           | Padding          | Font size |
| --------------- | ---------------- | --------- |
| `tabulation-xs` | `0.25rem 0.5rem` | `xs`      |
| `tabulation-sm` | `0.25rem 0.5rem` | `sm`      |
| `tabulation-md` | `0.5rem 0.75rem` | `sm`      |
| (default)       | `0.75rem 0.5rem` | inherited |
| `tabulation-lg` | `0.75rem 1rem`   | `base`    |
| `tabulation-xl` | `1rem 1.25rem`   | `lg`      |

| Class                | Effect                                                         |
| -------------------- | -------------------------------------------------------------- |
| `tabulation-flush`   | Removes left padding on first cell, right padding on last cell |
| `tabulation-nowrap`  | `white-space: nowrap` on all `th` and `td`                     |
| `tabulation-striped` | Alternating slate-100 row background                           |
| `tabulation-grid`    | Full border on every cell (not just bottom)                    |

The plugin also provides `tr:`, `th:`, and `td:` Tailwind variants that target descendant cells — apply them on the `<table>` (or a wrapper) to style all cells uniformly:

```html
<table class="tabulation tabulation-sm tabulation-nowrap td:text-right th:font-semibold">
    ...
</table>
```

### Dynamic colors: `getColorConfig`

The static-class-names rule above still applies; on sprintify projects the escape hatch is `getColorConfig(color)` from `sprintify-ui`, which returns `backgroundColor`, `textColor`, `borderColor`, and `color` values for inline `:style` bindings — or a component that resolves the color internally (`BaseBadge` with `:color`):

```ts
import { getColorConfig } from "sprintify-ui";

const style = computed(() => ({
    backgroundColor: getColorConfig(props.color).backgroundColor,
}));
```

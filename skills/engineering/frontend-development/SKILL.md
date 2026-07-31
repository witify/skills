---
name: frontend-development
description: Vue 3 + Tailwind frontend patterns — reactivity after emits, sub-form communication, form resets, orphan validation errors, responsiveness. Use when building or modifying Vue components, frontend forms, interactive UI, or making a screen fit a phone.
---

# Frontend Development

Patterns for building Vue 3 + Tailwind interfaces. This skill is all reference — apply every rule that touches the code you're writing.

## Conventions

- Type props and emits explicitly.
- Reuse before creating: check the project's UI kit and existing stores before writing a new component or store, and prefer the kit's components (button, field, badge…) over raw HTML elements.
- Every user-facing string is a translation key, present in every locale file the project ships. Check whether a key already exists before adding one.

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

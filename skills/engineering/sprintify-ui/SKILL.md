---
name: sprintify-ui
description: Sprintify UI component library (v0.12) reference for all Base* components — props, events, slots, and usage patterns. Activates when using, creating, or modifying any Base* component in Vue templates.
---

# Sprintify UI Component Library

## When to Activate

- Using any `Base*` component in Vue templates (BaseInput, BaseDataTable, BaseForm, BaseAutocomplete, etc.)
- Creating new pages, forms, tables, or modals that use sprintify-ui components
- Debugging component props, events, or slots
- Looking up available components for a UI pattern

## Scope

- In scope: all `Base*` components from sprintify-ui, their props, events, slots, exposed methods, and TypeScript types. **What exists and what it accepts.**
- Out of scope: Tailwind styling, Vue reactivity patterns, form conventions, and the rules about *which* component to reach for (`title` vs `BaseTooltip`, mobile-first classes, sub-forms emitting copies). **When and why** is the `/frontend-development` skill — run it for the rules, this one for the API.

## Documentation Reference

Per-component docs are available at `https://ui.sprintify.app/llm/{ComponentName}.txt`. Use `WebFetch` to retrieve detailed props/events/slots for any component not covered below.

- Full component index: `https://ui.sprintify.app/llm.txt`
- Type reference: `https://ui.sprintify.app/llm/types.txt`
- The installed version is in `package.json`; the authoritative export list and per-component props live in `node_modules/sprintify-ui/dist/types/`. This catalog was last synced against v0.12.1.

## Component Catalog

### Forms & Input

| Component                | Purpose                                                         |
| ------------------------ | --------------------------------------------------------------- |
| `BaseForm`               | Form wrapper with URL submission, error handling, loading state |
| `BaseField`              | Field wrapper with label, description, help, error display      |
| `BaseInput`              | Text/number input with icons, prefix/suffix, mask support       |
| `BaseInputPercent`       | Percentage input (model value 1 = displays 100%)                |
| `BaseTextarea`           | Multi-line text input                                           |
| `BaseTextareaAutoresize` | Auto-growing textarea                                           |
| `BasePassword`           | Password input with visibility toggle                           |
| `BaseSelect`             | Native select dropdown                                          |
| `BaseAutocomplete`       | Filterable dropdown with keyboard navigation                    |
| `BaseAutocompleteFetch`  | Autocomplete with server-side fetching via `url` prop           |
| `BaseRadioGroup`         | Radio button group                                              |
| `BaseSwitch`             | Toggle switch                                                   |
| `BaseDatePicker`         | Date/time picker (single, multiple, range, time modes)          |
| `BaseTimePicker`         | Time-only picker                                                |
| `BaseRichText`           | Rich text editor (CKEditor or TipTap driver)                    |
| `BaseFieldI18n`          | Multi-locale field wrapper                                      |
| `BaseInputLabel`         | Standalone input label                                          |
| `BaseColor`              | Color picker                                                    |
| `BaseIconPicker`         | Icon selector                                                   |
| `BaseAddressForm`        | Complete address form (address, city, region, country, postal)  |
| `BaseCharacterCounter`   | Character counter for text inputs                               |
| `BaseDateSelect`         | Date selection via dropdown                                     |

### Relationships (Select with model binding)

| Component                  | Purpose                                                            |
| -------------------------- | ------------------------------------------------------------------ |
| `BaseBelongsTo`            | Single-select from local options (like autocomplete for belongsTo) |
| `BaseBelongsToFetch`       | Single-select with server-side fetch via `url`                     |
| `BaseHasMany`              | Multi-select from local options                                    |
| `BaseHasManyFetch`         | Multi-select with server-side fetch via `url`                      |
| `BaseTagAutocomplete`      | Tag-style multi-select from local options                          |
| `BaseTagAutocompleteFetch` | Tag-style multi-select with server-side fetch                      |

### Buttons & Actions

| Component                  | Purpose                                              |
| -------------------------- | ---------------------------------------------------- |
| `BaseButton`               | Button with icon, loading, tooltip, routing support  |
| `BaseButtonGroup`          | Group of buttons                                     |
| `BaseActionButtons`        | Action button bar                                    |
| `BaseActionItem`           | Single action item (label, icon, color, sub-actions) |
| `BaseDropdown`             | Generic dropdown (button + dropdown slots)           |
| `BaseDropdownAutocomplete` | Dropdown with built-in autocomplete search           |
| `BaseMenu` / `BaseMenuItem` | Action menu with items (label, description, icon)   |

### Data Display

| Component                                                            | Purpose                                                                                             |
| -------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| `BaseDataTable`                                                      | Full-featured data table (search, sort, filter, pagination, row actions, checkable, virtual scroll) |
| `BaseDataIterator`                                                   | Flexible data iterator with section support                                                         |
| `BaseTable`                                                          | Low-level HTML table wrapper                                                                        |
| `BaseTableHead` / `BaseTableBody` / `BaseTableRow` / `BaseTableCell` / `BaseTableHeader` / `BaseTableColumn` | Table sub-components                                                                                |
| `BaseDescriptionList`                                                | Key-value description list                                                                          |
| `BaseDescriptionListItem`                                            | Single description list entry                                                                       |
| `BaseTimeline` / `BaseTimelineItem`                                  | Timeline display                                                                                    |
| `BaseGantt`                                                          | Gantt chart with rows, items, relationships                                                         |
| `BaseStatistic`                                                      | Single statistic display                                                                            |
| `BaseJsonReader`                                                     | JSON data viewer                                                                                    |
| `BaseBadge`                                                          | Badge with color, icon, contrast, size                                                              |
| `BaseBoolean`                                                        | Boolean value display (check/cross)                                                                 |
| `BaseEmptyState`                                                     | Empty state placeholder                                                                             |

### Layout & Navigation

| Component                                       | Purpose                                                                   |
| ----------------------------------------------- | ------------------------------------------------------------------------- |
| `BaseHeader`                                    | Page header with title, subtitle, breadcrumbs, attributes, actions, badge |
| `BaseContainer`                                 | Content container                                                         |
| `BaseCard` / `BaseCardRow`                      | Card layout                                                               |
| `BasePanel`                                     | Panel layout                                                              |
| `BaseTabs` / `BaseTabItem`                      | Tab navigation                                                            |
| `BaseStepper` / `BaseStepperItem`               | Multi-step wizard                                                         |
| `BaseCollapse`                                  | Collapsible section                                                       |
| `BaseBreadcrumbs`                               | Breadcrumb navigation                                                     |
| `BaseNavbar` / `BaseNavbarItem`                 | Top navigation bar                                                        |
| `BaseNavbarItemContent` / `BaseNavbarSideItem`  | Navbar item building blocks                                               |
| `BaseSideNavigation` / `BaseSideNavigationItem` | Side navigation                                                           |
| `BaseLayoutSidebar` / `BaseLayoutStacked`       | Page layouts                                                              |
| `BaseLayoutSidebarConfigurable` / `BaseLayoutStackedConfigurable` | Configurable variants of the page layouts               |
| `BaseApp`                                       | Root app wrapper (renders global dialogs and snackbars)                   |
| `BaseAppDialogs` / `BaseAppSnackbars`           | Global dialog / snackbar renderers (used by `BaseApp`)                    |

### Modals & Dialogs

| Component         | Purpose                                                                         |
| ----------------- | ------------------------------------------------------------------------------- |
| `BaseModalCenter` | Centered modal (maxWidth, closeOnOutsideClick, showCloseButton)                 |
| `BaseModalSide`   | Side-sliding modal (align: left/right)                                          |
| `BaseDialog`      | Confirmation dialog (color: info/success/danger/warning, confirm/cancel events) |

### Media & Files

| Component                            | Purpose                                                         |
| ------------------------------------ | --------------------------------------------------------------- |
| `BaseMediaLibrary`                   | Full media library (upload, reorder, crop, gallery/list layout) |
| `BaseFilePicker`                     | File selection with drag-and-drop                               |
| `BaseFileUploader`                   | File upload component                                           |
| `BaseCropper` / `BaseCropperModal`   | Image cropping                                                  |
| `BaseFilePickerCrop`                 | File picker with built-in image cropping                        |
| `BaseMediaPreview`                   | Media file preview                                              |
| `BaseMediaItem`                      | Single media item display                                       |
| `BaseAvatar` / `BaseAvatarGroup`     | User avatar display                                             |

### Feedback & Utility

| Component                 | Purpose                                                        |
| ------------------------- | -------------------------------------------------------------- |
| `BaseAlert`               | Alert box (color: info/success/warning/danger, icon, bordered) |
| `BaseSystemAlert`         | System-wide alert                                              |
| `BaseIcon`                | Iconify icon renderer (`icon` prop)                            |
| `BaseTooltip`             | Tooltip wrapper — the replacement for the `title` attribute    |
| `BaseLoadingCover`        | Loading overlay                                                |
| `BaseSkeleton`            | Loading skeleton placeholder                                   |
| `BaseProgressCircle`      | Circular progress indicator                                    |
| `BasePagination`          | Page navigation (modelValue, lastPage, totalVisible)           |
| `BaseClipboard`           | Copy-to-clipboard                                              |
| `BaseReadMore`            | Expandable text                                                |
| `BaseDraggable`           | Drag-and-drop wrapper                                          |
| `BaseLazy`                | Lazy-loaded content                                            |
| `BaseShortcut`            | Keyboard shortcut display                                      |
| `BaseAssign`              | User assignment component                                      |
| `BaseCounter`             | Animated counter                                               |
| `BaseDisplayRelativeTime` | Relative time display                                          |
| `BaseUniqueCode`          | Segmented code input (`numberOfCharacters` boxes, used for 2FA codes) |

## Key Component Reference

### BaseForm

Submit forms to a URL with automatic error handling and loading state.

**Required props:** `url` (string), `data` (Record<string, any>), `method` (Method: post/put/patch)

**Key optional props:** `format` (DataFormat.json | DataFormat.formData), `autosave`, `showLoadingMask`, `showNotificationOnError`, `showNotificationOnSuccess`, `showLeavePageWarning`, `beforeSubmit`, `successHandler`, `errorHandler`

**Events:** `success`, `error`

**Default slot:** `{ errors, loading, disabled, submit }`

**Exposed:** `submit()`, `clearErrors()`, `errors`, `hasErrors`, `disabled`, `loading`

### BaseDataTable

Full-featured data table with server-side or client-side data.

**Key props:** `url` (string — fetches from API), `items` (CollectionItem[] — client-side), `urlQuery`, `defaultQuery` (DataTableQuery), `searchable`, `checkable`, `detailed`, `toggleable`, `virtualScrolling`, `actions` (ActionItem[]), `rowActions` (RowAction[]), `editButton`/`deleteButton` (boolean), `rowTo`/`rowHref` (functions), `size`, `layout`

**Events:** `delete`, `update:checked-rows`, `fetch`

**Slots:** `default` (columns), `filters`, `detail`, `empty`

**Exposed:** `fetch()`, `fetchWithoutLoading()`, `query`, `data`

### BaseInput

**Key props:** `modelValue`, `type`, `size`, `placeholder`, `required`, `disabled`, `hasError`, `iconLeft`, `iconRight`, `prefix`, `suffix`, `min`, `max`, `step`, `mask`, `preventSubmit`

**Events:** `update:modelValue`, `blur`, `focus`, `click`, `keydown`, `keyup`

**Exposed:** `focus()`, `blur()`, `select()`

### BaseSelect

Native select dropdown.

**Key props:** `modelValue` (string | number | null), `placeholder`, `size`, `required`, `disabled`, `hasError`, `options`/`labelKey`/`valueKey`, `visibleFocus`

**Built-in empty option:** BaseSelect always renders its own first option with value `""`, labeled by `placeholder` (default "Select an option"). When `required` is set, that option is disabled and hidden; otherwise it is selectable and clears the model (`""` on the wire, which Laravel's `ConvertEmptyStringsToNull` turns into `null` before validation).

**Never add `<option :value="null">` in the slot.** Vue removes the `value` attribute when the bound value is `null`, and a native `<option>` without a `value` attribute falls back to its **text content** as its value — the form silently submits the option's label (e.g. `"Not applicable"`) and backend validation fails with "The selected field is invalid". Label the built-in empty option via `placeholder` instead:

```vue
<!-- WRONG — submits the literal string "Not applicable" -->
<BaseSelect v-model="form.wood_property_id">
  <option :value="null">{{ $t("not_applicable") }}</option>
  <option v-for="option in options" :key="option.id" :value="option.id">...</option>
</BaseSelect>

<!-- CORRECT — built-in empty option, clears the model -->
<BaseSelect v-model="form.wood_property_id" :placeholder="$t('not_applicable')">
  <option v-for="option in options" :key="option.id" :value="option.id">...</option>
</BaseSelect>
```

### BaseAutocomplete

**Required props:** `options` (RawOption[]), `labelKey`, `valueKey`

**Key optional props:** `modelValue`, `size`, `placeholder`, `disabled`, `required`, `hasError`, `filter` (function), `dropdownShow` ("focus" | "always"), `showEmptyOption`, `showRemoveButton`, `showModelValue`, `optionColor`, `optionIcon`, `twInput`, `twSelect`

**Events:** `update:modelValue`, `select`, `typing`, `open`, `close`, `clear`, `scrollBottom`

**Slots:** `option`, `empty`, `footer`

**Exposed:** `focus()`, `blur()`, `open()`, `close()`, `setKeywords()`

### BaseAutocompleteFetch

Same as BaseAutocomplete but fetches options from a URL.

**Required props:** `url`, `labelKey`, `valueKey`

**Additional props:** `queryKey` (default: "search")

**Events:** `update:modelValue`, `focus`, `clear`, `typing`, `scrollBottom`

### BaseBelongsTo / BaseBelongsToFetch

Single-select relationship components. Same API as BaseAutocomplete/BaseAutocompleteFetch but using `field` (string or function) instead of `labelKey`/`valueKey`, and `primaryKey` (default: "id") for the value.

**Required props:** `options`/`url`, `field`

### BaseHasMany / BaseHasManyFetch

Multi-select relationship components. Same pattern as BaseBelongsTo but supports array `modelValue` and `max` prop.

**Slots:** `items`, `option`, `empty`, `footer`

### BaseButton

**Key props:** `type` ("submit" | "button" | "reset"), `size`, `color`, `icon`, `iconPosition` ("start" | "end"), `loading`, `disabled`, `to` (RouteLocation), `href`, `tooltip`, `align` ("center" | "between")

**Events:** `click`, `mouseenter`, `mouseleave`, `mouseover`

### BaseTooltip

Wraps the element it describes. Nothing in this library uses the native `title` attribute — `/frontend-development` carries that rule and its rationale.

**Key props:** `text` (string | null), `as` (string, default `"div"` — pass `"span"` when wrapping inline content), `visible` (default true), `interactive` (default false), `delay` (ms, default 0), `dark` (default true), `offset` (px, default 6), `floatingOptions` (UseFloatingOptions — placement and positioning)

**Slots:** `default` (the wrapped element), `tooltip` (markup-rich content, instead of `text`)

### BaseModalCenter

**Key props:** `modelValue` (boolean), `maxWidth` (default: "512px"), `closeOnOutsideClick` (default: true), `showCloseButton` (default: true), `verticalAlign`, `twBackdrop`

**Events:** `update:modelValue`

**Default slot:** `{ close }`

### BaseModalSide

**Key props:** `modelValue` (boolean), `maxWidth` (default: "32rem"), `align` ("right" | "left"), `closeOnOutsideClick`

**Events:** `update:modelValue`

**Default slot:** `{ close }`

### BaseDialog

Confirmation dialog — typically opened programmatically via the `useDialogsStore()` Pinia store.

**Required props:** `color` ("info" | "success" | "danger" | "warning")

**Key props:** `title`, `message`, `confirmText`, `cancelText`, `html`, `input` (boolean | InputConfigProps), `errorMessage`

**Events:** `confirm`, `cancel`

### BaseField

Form field wrapper with label and error display.

**Key props:** `label`, `name`, `size`, `required`, `description`, `help`, `errorType` ("default" | "minimal" | "alert"), `labelClass`

### BaseDatePicker

**Key props:** `modelValue` (string | string[] | null), `mode` ("single" | "multiple" | "range" | "time"), `enableTime`, `noCalendar`, `minDate`, `maxDate`, `disableDates`, `inline`, `showInput`, `showRemoveButton`, `size`

### BaseHeader

**Required props:** `title`

**Key props:** `subtitle`, `breadcrumbs` (Breadcrumb[]), `attributes` (HeaderAttribute[]), `actions` (ActionItem[]), `badge` (BaseBadgeProps), `layout` ("default" | "compact"), `maxActions` (default: 3)

### BaseGantt

**Required props:** `rows` (GanttRow[])

**Key props:** `relationships` (GanttRelationship[]), `sidebarWidth` (default: 150), `rowHeight` (default: 40), `maxHeight`, `includeToday`, `flatten`

**Events:** `click:row`, `click:item`

**Slots:** `sidebarRow`, `sidebarItem`, `row`, `item`

### BaseMediaLibrary

**Key props:** `modelValue` (MediaLibraryPayload), `uploadUrl`, `layout` ("gallery" | "list"), `multiple`, `max`, `min`, `draggable`, `cropper`, `maxSize`, `accept`, `acceptedExtensions`, `currentMedia`, `pickerComponent`

**Events:** `update:modelValue`, `success`, `start`, `end`, `fail`

**Slots:** `default` (state info), `list` (custom list rendering)

## Key Types

```ts
type Size = "xs" | "sm" | "md" | "lg" | "xl";
type ActionColors = "dark" | "light" | "danger" | "success" | "warning" | "primary" | "secondary";

interface ActionItem {
    label?: string;
    description?: string;
    href?: string;
    to?: RouteLocationRaw;
    action?: () => Promise<void> | void;
    icon?: string;
    count?: number;
    color?: ActionColors;
    disabled?: boolean;
    meta?: { line?: boolean; showSubItems?: "always" | "active" | "never"; [key: string]: any };
    actions?: ActionItem[];
}

interface RowAction {
    label: string;
    icon: string;
    action?: (row: CollectionItem) => Promise<void> | void;
    to?: (row: CollectionItem) => RouteLocationRaw;
    href?: (row: CollectionItem) => string;
    disabled?: (row: CollectionItem) => boolean;
}

interface Breadcrumb {
    icon?: string;
    to: RouteLocationRaw;
    label: string;
}
interface HeaderAttribute {
    icon?: string;
    label: string;
    tooltip?: string;
    to?: RouteLocationRaw;
    href?: string;
    action?: () => Promise<void> | void;
}

interface DataTableQuery extends Record<string, any> {
    page?: number;
    sort?: string;
    search?: string;
    filter?: Record<string, any>;
}

enum Method {
    post = "post",
    put = "put",
    patch = "patch",
}
enum DataFormat {
    json = "json",
    formData = "formData",
}

interface StepperItem {
    title: string;
    description?: string | null;
    stepNumber: number;
    status: Status;
}
interface TimelineItem {
    title: string;
    icon: string;
    description?: null | string;
    date?: string | null;
    color?: string | null;
    onEdit?: () => void;
    onDelete?: () => void;
}

interface GanttRow {
    id: number | string;
    name: string;
    meta?: Record<string, unknown>;
    items: GanttItem[];
    height?: number;
}
interface GanttRelationship {
    fromId: number | string;
    toId: number | string;
}

type ToolbarOption =
    | "undo"
    | "redo"
    | "|"
    | "heading"
    | "bold"
    | "italic"
    | "underline"
    | "link"
    | "numberedList"
    | "bulletedList"
    | "code"
    | "codeblock"
    | "insertTable"
    | "fontColor"
    | "fontBackgroundColor"
    | "removeFormat"
    | "insertImage"
    | "mediaEmbed"
    | "findAndReplace";
```

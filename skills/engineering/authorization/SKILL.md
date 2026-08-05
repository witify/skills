---
name: authorization
description: Authorization patterns for policies, gates, nested controllers, and frontend permission checks. Activates when working with policies, Gate components, canDo(), nested resource authorization, or permission-related bugs.
---

# Authorization

## Applicability (check first)

This skill describes the current sprintify baseline; projects forked from an older sprintify may lack the frontend pieces. Check opportunistically:

- If the project ships its own `.ai/skills/authorization/`, defer to that copy.
- The **backend patterns** (policies, nested controllers, `canDo()`) apply to every sprintify-derived project — `Support\Controller\Controller` and `Support\Resource\BaseResource` are part of the base.
- The **frontend `<Gate>` patterns** need `resources/js/components/Gate.vue` / `GateRouterLink.vue`. If they don't exist (older forks), gate visibility with the row-level `resource.can.*` flags that `canDo()` already exposes (`v-if="comment.can.resolve"`) — and don't port the components uninvited.

## When to Activate

- Activate when creating or modifying policies, controllers with authorization, or `<Gate>` / `<GateRouterLink>` usage.
- Activate when a permission bug arises (user can do X but can't see Y).
- Activate when adding a new nested resource endpoint under a parent resource.
- Activate when code references `authorize()`, `authorizeResource()`, `canDo()`, `Gate::allows()`, or the permissions store.

## Scope

- In scope: policy structure, controller authorization, `canDo()` in resources, `<Gate>` and `<GateRouterLink>` in Vue, nested vs standalone authorization patterns.
- Out of scope: role/permission CRUD, Spatie permission package internals, authentication (login/sessions).

## Core Principle: Authorization Follows the Route

Using a generic `Project` (parent) → `Comment` (child) example:

| Route type                                  | Who authorizes                  | Example                                  |
| ------------------------------------------- | ------------------------------- | ---------------------------------------- |
| Standalone (`/comments`)                    | Child policy (`CommentPolicy`)  | Admin moderation page                    |
| Nested (`/projects/{project}/comments`)     | Parent policy (`ProjectPolicy`) | Comments tab on a project page           |
| Row action (resolve/flag a specific comment)| Child policy (model-level)      | Business logic is self-contained         |

When the same model appears in different contexts, the **route** determines which policy gates access. Nested routes use the parent policy for collection-level access; standalone routes use the child policy.

## Patterns

### 1. Standalone Controller — `authorizeResource()` in Constructor

For top-level CRUD endpoints. The child policy handles all authorization automatically.

```php
class CommentController extends Controller
{
    public function __construct()
    {
        $this->authorizeResource(Comment::class, 'comment');
    }
}
```

### 2. Nested Controller — Manual `authorize()` via Parent Policy

For child resources accessed through a parent context. Each method authorizes against the **parent** model's policy.

```php
class ProjectCommentController extends Controller
{
    public function index(Project $project): JsonResponse
    {
        $this->authorize('view', $project); // Can see project → can see its comments
        // ...
    }

    public function store(Request $request, Project $project): JsonResponse
    {
        $this->authorize('writeComments', $project);
        // ...
    }
}
```

**Critical:** nested controllers must have their own `index` method so the frontend never hits a standalone endpoint the user doesn't have access to.

### 3. Parent Policy — Context Methods for Child Resources

Name parent policy methods that gate child resource access with the pattern `{verb}{ChildModel}s`:

```php
// ProjectPolicy
public function writeComments(User $user, Project $project): bool
{
    if (! $this->update($user, $project)) {
        return false;
    }

    return $project->status->allowsComments();
}
```

The parent policy gates **access to the context** (can this user interact with comments through this project?), not the business rules of the child.

### 4. Child Policy — Business Rules for Row-Level Actions

The child policy owns all business logic for actions on its own model (resolve, flag, archive, etc.). It may check parent state, but it is the single source of truth for that action.

```php
// CommentPolicy
public function resolve(User $user, Comment $comment): bool
{
    // Business rules: parent project status, comment age, ownership, etc.
}
```

### 5. `canDo()` in Resources — Row-Level Permissions

Override `canDo()` in the resource to expose custom action permissions per row:

```php
// CommentResource
protected function canDo(): array
{
    return [
        ...parent::canDo(), // update, delete, view
        'resolve' => Gate::allows('resolve', $this->resource),
        'flag' => Gate::allows('flag', $this->resource),
    ];
}
```

Look for a `UserResource::canDo()` override in the project for a real example (`impersonate`, `overwritePassword`, `markEmailAsVerified`, etc.).

### 6. Frontend — One `<Gate>` Check per UI Element

Each `<Gate>` component maps to **exactly one ability on one resource**. If a Vue component needs 2+ policy checks to decide visibility, the backend isn't providing the right authorization surface.

```vue
<!-- Collection-level: gate on the parent -->
<Gate ability="view" :resource="project">
  <CommentsTab />
</Gate>

<!-- Row-level action: gate on the child -->
<Gate ability="resolve" :resource="comment">
  <BaseButton @click="resolveComment(comment)" />
</Gate>
```

Use `<GateRouterLink>` for conditional navigation links:

```vue
<GateRouterLink :resource="item" class="link">{{ item.name }}</GateRouterLink>
```

On older forks without these components, the same one-check-per-element rule applies through `resource.can.*`:

```vue
<BaseButton v-if="comment.can.resolve" @click="resolveComment(comment)" />
```

## Anti-Patterns

| Don't                                                                                        | Do instead                                                                             |
| -------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| Add context parameters to standalone policies (`viewAny(User $user, ?Project $project = null)`) | Create a nested controller with its own `index` that authorizes via parent policy   |
| Read `resource.can.view` in Vue for list visibility                                          | Use `<Gate>` on the parent resource (where the component exists)                       |
| Combine 2+ policy checks in one `<Gate>`                                                     | Fix the backend — the nested controller should provide the right authorization surface |
| Create "super-policies" aggregating checks from multiple models                              | Keep policies focused on their model; use nested controllers to bridge contexts        |
| Duplicate child business logic in the parent policy                                          | Parent policy gates context access only; child policy owns business rules              |

## Key Classes

- `src/Support/Controller/Controller.php` — Base controller with `AuthorizesRequests` trait (`authorize()`, `authorizeResource()`).
- `src/Support/Resource/BaseResource.php` — Base resource with default `canDo()` returning `['view', 'update', 'delete']`.
- `src/App/Providers/AuthServiceProvider.php` — Policy registration (`$policies` array).
- `resources/js/components/Gate.vue` — Frontend conditional rendering based on authorization (current sprintify).
- `resources/js/components/GateRouterLink.vue` — Frontend conditional router link (current sprintify).
- `resources/js/stores/permissions.ts` — Frontend permission state and batched API fetching.

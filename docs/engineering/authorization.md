Quickstart:

```bash
npx skills add witify/skills --skill=authorization
```

```bash
npx skills update authorization
```

[Source](https://github.com/witify/skills/tree/main/skills/engineering/authorization)

## What it does

`authorization` holds the permission patterns for sprintify-derived projects: standalone controllers with `authorizeResource()`, nested controllers that authorize through the **parent** policy, `canDo()` overrides exposing row-level abilities, and one `<Gate>` check per UI element on the frontend. Which policy gates access is never a judgment call — **authorization follows the route**: nested routes authorize through the parent, standalone routes through the child, row actions through the child's own business rules.

## When to reach for it

Type `/authorization`, or the agent reaches for it automatically when creating policies or authorized controllers, adding a nested resource endpoint, or chasing a permission bug ("user can do X but can't see Y").

## Prerequisites

A sprintify-derived Laravel project — the backend patterns ride `Support\Controller\Controller` and `BaseResource::canDo()`, which every fork has. The `<Gate>` components exist only on recent forks; older ones fall back to `resource.can.*` in `v-if`.

## Where it fits

`authorization` is a **reach-for-it-anytime standalone** in the sprintify-baseline family, picked up whenever built features need gating. [confirm-request](./confirm-request.md) is the neighbour on the same boundary — authorization decides *whether* a user may act, confirm-request double-checks that they *mean it*. When you're unsure which skill fits, [ask-witify](./ask-witify.md) routes you.

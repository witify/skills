Quickstart:

```bash
npx skills add witify/skills --skill=grilling
```

```bash
npx skills update grilling
```

[Source](https://github.com/witify/skills/tree/main/skills/productivity/grilling)

## What it does

`grilling` is the relentless interview that stress-tests a plan or design before you build it. It maps the plan as a **design tree** — every decision branches into the decisions that hang off it — and works that tree in **rounds** until you and the agent share the same understanding.

Each round asks the whole **frontier** — every question whose prerequisites are already settled — numbered, each with the agent's own recommended answer. Your answers reshape the tree and unblock the next round; a question that depends on one still open waits for a later round. Any question the codebase can settle it explores instead of asking you, and it won't start enacting the plan until you confirm the shared understanding has been reached.

## When to reach for it

Type `/grilling`, or the agent reaches for it automatically when a task fits — this is the underlying primitive, not a user-only entry point.

Reach for it when a plan or design still has soft spots and you want them surfaced before code is written. In practice you usually invoke it through one of its two wrappers rather than by name: for a plain grilling session use [grill-me](./grill-me.md); to have the session also write ADRs and a glossary as it goes, use [grill-with-docs](../engineering/grill-with-docs.md).

## The decision tree

The mental model is a **design tree**: every plan branches into decisions, and decisions depend on each other. `grilling` works the tree by its **frontier** — the set of questions askable *now* without guessing at answers not yet heard. Everything on the frontier arrives together in one round; everything downstream waits its turn. That keeps the dependency structure intact — an early answer still reshapes what comes next — without the drip-feed of strictly one question at a time. The session is done when the frontier is empty: every branch visited, nothing silently assumed.

## Pulled out on purpose

`grilling` is the **single source of truth** for the interview technique, split out as a model-invoked **primitive** so every skill that needs an interview can reach it instead of reinventing one. [grill-me](./grill-me.md) and [grill-with-docs](../engineering/grill-with-docs.md) are its two user-invoked front doors, but [improve-codebase-architecture](../engineering/improve-codebase-architecture.md) and [triage](../engineering/triage.md) also lean on it to pressure-test their own decisions.

Keeping the technique in one place means you can also reach for it directly when you just want the interview — without the ADR-writing or ticket-shaping that its wrappers add on top.

## Where it fits

`grilling` is the interview **primitive** under the main build chain: [grill-with-docs](../engineering/grill-with-docs.md) runs it to sharpen context before [to-spec](../engineering/to-spec.md) writes the spec. When you're unsure which entry point fits, [ask-witify](../engineering/ask-witify.md) routes you.

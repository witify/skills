Quickstart:

```bash
npx skills add witify/skills --skill=figma-brief
```

```bash
npx skills update figma-brief
```

[Source](https://github.com/witify/skills/tree/main/skills/productivity/figma-brief)

## What it does

`figma-brief` turns the description of an application, a module, or a feature into a brief you paste into an AI design tool such as Figma Make to generate the mockups. The brief is a prompt, and it is written for the most signal per token: it spends its words on what the tool cannot guess (the business purpose of each screen, the fr-CA vocabulary of fields and statuses, the one primary action, the business rules that shape the UI, how the screens link) and none on what the tool already does well (pixels, margins, colours, the look of standard components).

It gives labels, never data rows, and asks the tool to generate its own realistic fr-CA filler from them. It delivers the whole brief in one code block, in French, ready to copy.

## When to reach for it

Type `/figma-brief`, or the agent reaches for it automatically when you ask for a brief Figma, a prompt de maquette, to briefer des écrans, or hand over a description of screens to be designed.

Reach for it when the next step is mockups rather than code. For writing into a Figma file through the Figma MCP, use the Figma plugin's own skills instead; this one produces text for a prompt box.

## Labels, not data

The leading idea is **labels, not data**. A field name, a column name, a status costs a few tokens and tells the tool exactly what the screen is about; a pasted table of rows costs hundreds and tells it less. The same move applies to the visual: **intent, not pixels**. The global conventions (platform, density, locale, recurring components) are stated once at the top and never repeated per screen, which is where most of the brief's length is saved. A Parcours section lists the screens and how they link, so the tool can wire a clickable prototype.

## It's working if

- The brief opens with one Contexte, one set of conventions, one Parcours, then one short section per screen, each with an archetype in its title and exactly one primary action.
- No screen section restates a global convention.
- Missing essentials are written as `(hypothèse)` instead of coming back as questions.

## Where it fits

A reach-for-it-anytime standalone that sits between thinking and building: what a grill, a spec, or a ticket describes becomes mockups before it becomes code. Its neighbours are [grilling](./grilling.md), because a sharpened idea makes a better brief, and [to-spec](../engineering/to-spec.md), because what comes back from Figma is material for the spec, not the spec itself. When you are unsure which skill fits, [ask-witify](../engineering/ask-witify.md) routes over the whole set.

Quickstart:

```bash
npx skills add witify/skills --skill=witify-writing-style
```

```bash
npx skills update witify-writing-style
```

[Source](https://github.com/witify/skills/tree/main/skills/productivity/witify-writing-style)

## What it does

`witify-writing-style` is the single source of Witify's writing rules for client-facing French copy: punctuation (no em dash, no en dash, no semicolon, no comma before « et »), one idea per sentence, Québec formats for numbers, amounts and dates, vouvoiement, the preferred French term over the English one, sentence-case headings, and a final grep check that catches the banned characters before a document is declared done. Every document skill invokes it instead of carrying its own copy of the rules, so a rule changes in one place.

It rules on form, never on facts: an amount, a rate, a duration or a clause comes from the skill that owns it or from you, and anything unconfirmed is written `À évaluer` or `À confirmer`, never invented.

## When to reach for it

Type `/witify-writing-style`, or the agent reaches for it automatically when writing or editing any text a client will read, and whenever another skill generates a document.

Reach for it for a client email, a proposal paragraph, a report section, a slide. For documents an agent reads rather than a client, use [writing-for-agents](./writing-for-agents.md) instead.

## One idea per sentence

The leading rule is **one idea per sentence**, about twenty words. Most of the punctuation rules follow from it: a dash, a semicolon or a comma before « et » is a sentence that has grown a second idea, and the fix is always to split it. Numbers a reader must compare go in a table, prose carries at most one number per sentence.

## It's working if

- The final `grep` for `—`, `–`, `;` and `, et ` finds nothing inside a French string.
- Amounts read `7 865 $`, dates read `15 septembre 2026`, headings are sentence case without a final period.
- Nothing is judged about the people who wrote the code or ran the process, only the code, the process or the plan.

## Where it fits

A vocabulary layer that runs underneath every document skill rather than a step in a flow. Its closest neighbour is [witify-docx](./witify-docx.md), because that skill invokes it before writing any string into a Word document. When you are unsure which skill fits, [ask-witify](../engineering/ask-witify.md) routes over the whole set.

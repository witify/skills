---
name: witify-writing-style
description: Witify's writing rules for client-facing French copy (documents, quotes, agreements, audits, pitch decks): punctuation, numbers and amounts, tone, terminology, and the final check. Use when writing or editing any text a client will read, and whenever another skill generates a document.
---

# Witify writing style

Every client-facing text Witify produces reads the same way: short sentences, plain French, one idea at a time, numbers the reader can check. The rules below are the whole style. A document skill invokes this one and applies it to every string it writes into a template.

## Punctuation

- **No em dash, no en dash.** Neither `—` nor `–` appears in copy. Where a dash would set off a clause, choose one of: a colon to introduce, parentheses for an aside, or a new sentence. A hyphen `-` stays only inside compound words (`mise-à-jour` is wrong, `mise à jour` is right; `Québec-Montréal`, `sur-mesure` as an adjective).
- **No comma before « et ».** `, et` never appears in copy. A comma before « et » means the sentence has grown two ideas: split it into two sentences, or drop the comma when the « et » joins two short items.
- **No semicolon.** A semicolon means two sentences. Split them. In a list of items inside a sentence, use commas, or turn the sentence into bullets.
- **One idea per sentence**, about 20 words. When a sentence needs a second verb to be complete, it is two sentences.
- **Colon** introduces an explanation, a list, or an example. Québec typography: a non-breaking space before the colon (`Défi : Lisibilité`), no space before `?`, `!`, or a closing quote.
- **Quotes** are French guillemets with non-breaking spaces (`« clés étrangères »`), never straight quotes in prose. Straight quotes stay in code extracts.
- **Parentheses** hold a short aside (a version number, a file name, a synonym). A parenthesis longer than a line is a sentence.
- **Bullets**: a bullet that names a deliverable or an item has no final period. A bullet that is a full sentence ends with a period. Never mix the two in one list. A bullet opens with its key words in bold when the list is scanned (`**Clés étrangères :** 0 déclarée…`).

## Numbers, amounts, dates

- Thousands separated by a non-breaking space, decimals with a comma: `80 000 $`, `1 233,91 $`, `7,6 %`, `0,5h`. The currency sign and the percent sign follow a non-breaking space.
- Hours glued to the number, no space: `2h`, `0,5h`, `1h30`, never `2 h`. Durations as `13 semaines` or `≈ 13 semaines` when approximate, rates as `150 $/h`, monthly amounts as `1 500 $/mois`.
- Dates in full: `15 septembre 2026`, never `15/09/2026`.
- Versions with a dot: `PHP 8.5`, `Laravel 13`, `MySQL 8.4`.
- A number the reader must compare sits in a table, not in prose. Prose carries at most one number per sentence.

## Tone

- Vouvoiement, client-facing, factual. Judge the code, the process, or the plan, never the people who made it: `le code conserve des chemins d'exécution anciens`, not `les développeurs ont laissé`.
- Explain a technical notion in one sentence before judging it, then give the evidence (a file, a number, a table), then the consequence for the client.
- Lead every section with what the reader gains from it. Close on the next step, not on a summary.
- Say what is out of scope plainly (`Aucune instance en ligne n'était disponible : l'observation repose sur…`). Never fill a gap with a guess.
- Amounts, rates, durations, and clauses come from the skill that owns them (a pricing skill, a contract-terms skill) or from the human. A value that is not confirmed is written `À évaluer` or `À confirmer`, never invented.

## Terminology

Prefer the French term where Québec usage has one, and keep it consistent through a document:

| Use | Instead of |
|---|---|
| courriel | email, e-mail |
| gabarit | template (in prose; `template/` as a path stays) |
| mise à jour, mettre à jour | update, upgrade |
| déploiement | deploy |
| fonctionnalité | feature |
| base de données | BD (except in tables) |
| bibliothèque | librairie, library |
| jeton | token (in prose) |
| infonuagique, hébergement | cloud (alone) |
| soumission | devis (unless the client says devis) |
| entente de service | contrat de service |
| échéancier | timeline |
| sur mesure | custom |

English stays for a proper noun (Laravel, Vue.js, GitHub Actions), a code identifier, a file path, and an established acronym after its first expansion (`ORM (Object-Relational Mapping)`).

## Headings and structure

- Sentence case: `Base de données`, not `Base De Données`. No final period. A numbered Heading 1 reads `1. État technologique`.
- A heading is a noun phrase, not a sentence and not a question.
- A section opens with a paragraph, never directly with a table or a list.

## Final check

Before a document is declared done, search the copy for the banned characters and fix every hit:

```bash
grep -nE '—|–|;|, et ' <build script or content file>
```

A hit inside a code extract or a Python statement is fine. A hit inside a French string is a sentence to rewrite. Then read the rendered pages once as the client would, first line to last.

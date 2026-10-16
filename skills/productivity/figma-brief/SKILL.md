---
name: figma-brief
description: Write a concise, structured brief (a prompt) for generating interface mockups with an AI design tool such as Figma Make. Use when the user wants a "brief Figma", a "prompt de maquette", to "briefer des écrans", to describe interfaces to be designed, or hands over the description of an application, module, or feature to turn into mockups. Trigger even without the word "brief", whenever screens are being described so a tool can render them. Not for writing to a Figma file through the Figma MCP (that is the figma plugin's job).
---

# Figma brief

Produce a brief ready to paste into an AI design tool (Figma Make or equivalent) that generates interface mockups. The brief is a **prompt**: it aims for the most signal per token. The output is in French (fr-CA), because the screens are.

## Guiding principle

The design tool is already good at layout, spacing, visual hierarchy, and polish. Spend no tokens on what it infers well:

- pixel values, margins, grids, breakpoints
- hex colours (unless an explicit brand constraint)
- the generic look of standard components

Spend the tokens on what the tool **cannot** guess:

- the business purpose of each screen (the job the user gets done there)
- the domain vocabulary in fr-CA: names of fields, columns, statuses, sections
- the one primary action of the screen
- the business rules and constraints that shape the UI
- how the screens link, so the tool can wire a clickable prototype

Give **labels, not data rows**. Labels are cheap and carry the signal; ask the tool to generate its own realistic fr-CA filler from them. Provide a real example value only when the format is not obvious, or when a specific case must be visible (a status, a line with a discrepancy, a negative amount). Never paste tables of data.

## Before writing

Extract everything you can from the material already at hand: the description given, an existing spec or ticket, existing screens, a known domain, a `CONTEXT.md`. If the input is a bare list of screens, infer each one's archetype and purpose before writing. Never ask the user for what can reasonably be deduced.

When an essential is missing, make the most reasonable assumption and mark it `(hypothèse)` in the brief. Ask a question only when the ambiguity truly prevents writing. One message of questions at most, then write.

## Output

Deliver the whole brief in one fenced Markdown block, so the user copies it in one gesture. Nothing before it but one line naming the number of screens and the assumptions made, nothing after it.

Always follow this template. State the global conventions **once**, then one tight paragraph per screen. Never repeat the global in a screen: that is where most tokens are saved.

```
# Brief maquettes : [Application / module]

## Contexte
[2 à 3 phrases : ce que fait l'application, pour qui, la valeur métier. Les rôles utilisateurs s'il y en a plus d'un.]

## Conventions globales (valables pour tous les écrans)
- Plateforme : [desktop / responsive / mobile]
- Style : [ex. professionnel, dense, épuré, flat]
- Densité : [dense (ERP, données) ou aérée (grand public)]
- Palette : [couleurs de marque, ou « neutre pro »]
- Typographie : [famille ou « sans-serif lisible »]
- Locale : fr-CA, dates AAAA-MM-JJ, 24 h, montants « 1 234,56 $ CAD »
- Composants récurrents : [barre de navigation, fil d'Ariane, en-tête de tableau, etc.]
- Contenu de remplissage : généré par l'outil, réaliste, en fr-CA, à partir des libellés ci-dessous

## Parcours
[La liste ordonnée des écrans et les liens entre eux, en une ligne chacun : « Liste des commandes → Fiche commande → Modale Annuler ». C'est ce que l'outil câble pour un prototype cliquable.]

## Écrans

### [Nom de l'écran] · [archétype]
[1 paragraphe concis : objectif métier de l'écran et spécificités à respecter.]
- Éléments clés : [champs / colonnes / sections / KPIs]
- Règles métier : [seulement les règles qui changent l'UI ou le comportement : blocage, calcul, condition d'affichage, permission]
- Action primaire : [le CTA dominant, un seul]
- Interactions : [au clic, filtre dynamique, affichage conditionnel, navigation entre étapes ; seulement si pertinent]
- États / à éviter : [seulement si pertinent]
```

## Archetypes

Naming the archetype in the screen title helps the tool enormously:

- **Tableau de bord**: KPIs, charts, alerts, periods
- **Liste / tableau**: filters, sort, pagination, row actions, multi-select
- **Formulaire**: sections, validation, create vs edit
- **Fiche / détail**: master-detail, tabs, history, contextual actions
- **Assistant (wizard)**: sequential steps, progress, summary
- **Modale / panneau latéral**: one focused action without leaving the context
- **Auth / vide / erreur**: edge states

## Writing rules

- **Concision**: every sentence earns its place. No filler, no restating the obvious. A screen is one paragraph and five bullets at most; a brief of ten screens fits on two pages.
- **Global once**: never repeat the conventions screen by screen.
- **Labels over data**: give the vocabulary (fields, columns, statuses) and let the tool invent the filler. Paste a real value only to settle a format or show a specific case.
- **Intent, not pixels**: describe what the screen is for and leave the visual to the tool.
- **Explicit business rules**: when a rule changes the UI or the behaviour (a blocked validation, an automatic calculation, a display condition, a permission by role), write it plainly. The tool will not guess it.
- **One primary action per screen**: if two compete, the screen is probably two screens, or one is secondary.
- **Mockups can be interactive**: describe the key interactions (on click, live filter, conditional display, step transitions) when the behaviour matters, not just the static look.
- **fr-CA vocabulary**: the French term where Québec usage has one (courriel, soumission, fonctionnalité, mise à jour). Keep the client's own terms when the material gives them.
- **No em dash, no semicolon** in the brief: a colon, parentheses, or two sentences. Québec typography, with a space before the colon.

## Final check

Before delivering, read the brief once as the tool would:

- every screen has an archetype, a one-sentence purpose, and exactly one primary action
- every screen named in the Parcours has a section, and every section is in the Parcours
- no convention is repeated inside a screen
- `grep -nE '—|–|;'` on the brief finds nothing

## Example (excerpt)

```
### Réception de marchandise · Formulaire
Permet au magasinier de réceptionner un bon de commande fournisseur et de valider les quantités reçues contre les quantités commandées, avec gestion des écarts et saisie des numéros de lot. Bloquer la validation si une quantité reçue dépasse la commande sans justification saisie.
- Éléments clés : en-tête (fournisseur, no BC, date), tableau de lignes (article, qté commandée, qté reçue, no lot, emplacement), zone de résumé des écarts
- Règles métier : une qté reçue supérieure à la qté commandée exige une justification avant validation
- Action primaire : « Valider la réception »
- Interactions : la ligne passe en écart dès que les quantités diffèrent, le résumé se met à jour en direct
- États / à éviter : bouton désactivé tant qu'une qté reçue est vide, pas de tableau à défilement horizontal
```

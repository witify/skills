---
name: create-guideline
description: Creates or updates concise coding guidelines in .ai/guidelines/. Activates when the user wants to add a new guideline or coding rule.
---

# Create Guideline

## Applicability (check first)

- If the project ships its own `.ai/skills/create-guideline/`, defer to that copy.
- The project must have a `.ai/guidelines/` directory (the Laravel Boost convention every sprintify-derived project uses). If it doesn't, don't create the directory uninvited — ask the user where coding rules live in this project.
- The `boost:update` sync step only applies when `laravel/boost` is in `composer.json`; skip it otherwise.

## When to Activate

- User asks to create, add, or update a guideline or coding rule.
- User mentions `.ai/guidelines/` or "add a rule for...".

## Scope

- In scope: creating/updating files in `.ai/guidelines/`.
- Out of scope: skills, CLAUDE.md, boost config.

## Workflow

1. Determine the topic. Check if an existing guideline in `.ai/guidelines/` already covers it — append to that file if so, otherwise create a new one.
2. Write the guideline as concisely as possible. These files are injected into LLM context, so every token counts. Follow these rules:
    - Lead with the rule, not the explanation.
    - Use bullet points over paragraphs.
    - Only include a code example if the correct usage isn't obvious from the rule text alone.
    - Skip filler words, preamble, and redundant context.
    - Keep code examples minimal (2-4 lines showing the correct pattern).
    - No "WRONG" examples unless the mistake is non-obvious.
3. Use kebab-case filenames matching the topic (e.g., `decimal-precision.md`, `soft-deletes.md`).
4. Run `php artisan boost:update` to sync changes (when the project uses Laravel Boost).

## Reference Examples

- See the project's existing `.ai/guidelines/*.md` files (e.g. `models.md`, `architecture.md`) for the target conciseness level.

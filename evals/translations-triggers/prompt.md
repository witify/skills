---
name: translations-triggers
description: Adding a translation key used from both Vue and PHP should load the translations skill.
tags: [trigger, sprintify]
allowed_tools: [Read, Glob, Grep, Skill]
expected_outcome: The translations skill is invoked before deciding where the key goes.
---
I'm adding an "Overdue" status badge to invoices. The label shows in a Vue component with $t() and the same wording is used in a BusinessRuleException thrown from the backend when someone tries to pay an overdue invoice twice. Where do the French and English keys go, and what should they be named?

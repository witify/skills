---
name: sentry-fix-triggers
description: A sentry.io link asking for a fix should load the sentry-fix skill.
tags: [trigger, sentry-fix]
allowed_tools: [Read, Glob, Grep, Skill]
expected_outcome: The sentry-fix skill is invoked before any investigation or code change.
---
Can you fix this one? https://witify.sentry.io/issues/ACME-ERP-22V/ It started after yesterday's deploy, users get a 500 when they duplicate an order.

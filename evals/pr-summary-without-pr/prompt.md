---
name: pr-summary-without-pr
description: With no PR to post on (no GitHub PR for the branch, or no gh CLI), /pr-summary must stop and say so instead of writing a briefing from the local diff.
tags: [github, pr-summary]
allowed_tools: [Read, Glob, Grep, Bash, Skill]
max_turns: 15
expected_outcome: The reply says no PR could be found for the current branch (or that the gh CLI is unavailable); no briefing is written, no file is created, nothing is posted.
---
/pr-summary

Brief the reviewer on this PR.

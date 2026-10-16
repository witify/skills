---
name: ship-never-asks-fix-policy
description: /ship fixes every real finding worth doing by default and must never ask the user to choose a fix policy, threshold, or priority cut-off.
tags: [ship, policy]
allowed_tools: [Read, Glob, Grep, Bash, Skill]
max_turns: 15
expected_outcome: Whatever else happens (typically a stop because no tracker is connected), the reply never asks which findings to fix, how aggressive to be, or which priorities to include.
---
/ship WIT-42

The ticket is in Linear. Before you start, I'm curious: how will you handle the review findings and Codex comments on the PR?

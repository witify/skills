---
name: ship-auto-fix-hands-off
description: In the Claude desktop app with Auto-fix on, /ship leaves CI failures, merge conflicts and review comments to the app and runs no polling or wave loop; with no Auto-fix it keeps its five waves.
tags: [ship, auto-fix]
allowed_tools: [Read, Glob, Grep, Bash, Skill]
max_turns: 15
expected_outcome: The reply says that with Auto-fix on it runs no waves and polls nothing, acting only on the events the app sends, and that without Auto-fix it runs its feedback loop of at most five waves.
---
/ship WIT-42

The ticket is in Linear. Before you start, two quick questions about what happens once the PR is open. I'm in the Claude desktop app and Auto-fix will be on for the PR: how do you deal with CI failures, merge conflicts and review comments? And what changes outside the desktop app, where there is no Auto-fix?

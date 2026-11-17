---
type: llm
---
PASS only if all three hold:
1. The response states that no GitHub PR could be found for the current branch, or that the `gh` CLI is not available in this session.
2. It tells the user what to do next (open the PR, pass a PR number or URL, or install and authenticate `gh`).
3. It does not write a briefing: no project description, no "À valider" list, no before/after table, no reading order, and it does not claim to have edited a PR description or taken screenshots.

Explaining what /pr-summary would produce once a PR exists is acceptable and does not count against the response.

FAIL only if the response invents a PR, writes a briefing from the local diff anyway, or answers without ever mentioning the missing PR or CLI.

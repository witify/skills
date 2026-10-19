---
"witify-skills": minor
---

`ship` now prints a boxed banner at each milestone of a run, so the transcript can be scanned without reading the sub-agent chatter: when a ticket starts (`🎫 TICKET n / m`, with the previous ticket's result and the tickets left), when the PR opens (`🚀 PR OUVERTE`, double-lined, with the PR link), and at each Codex wave as the review starts (`👀`), as its findings are fixed (`🔧`, with the fixed, rejected and deferred counts) and when Codex approves (`👍`). A repo without Codex gets a single `⏱` banner when the 15-minute wait runs out.

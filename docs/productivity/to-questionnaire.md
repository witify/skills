Quickstart:

```bash
npx skills add witify/skills --skill=to-questionnaire
```

```bash
npx skills update to-questionnaire
```

[Source](https://github.com/witify/skills/tree/main/skills/productivity/to-questionnaire)

## What it does

`to-questionnaire` turns a decision you can't settle on your own into a **questionnaire** — a Markdown document you hand to the one person who holds what you're missing, for them to fill in async or for the two of you to work through in a meeting.

It grills you about the **send**, never the subject. Interviewing you about the topic is pointless here: not knowing the topic is why you're writing to someone else. So it asks the two things you can always answer — who this is going to, and what you need back from them — and aims every question in the document at the gap between the two.

## When to reach for it

You invoke this by typing `/to-questionnaire` — the agent won't reach for it on its own.

Reach for it when a decision is blocked on knowledge that lives in one other person's head: a client, a domain expert, an exec who owns the business rules. The split with its siblings is *where the answers are*: in your own head, unsharpened → [grill-me](./grill-me.md); in the codebase → [grill-with-docs](../engineering/grill-with-docs.md); in someone else's head → `to-questionnaire`; in nobody's head yet, needing something to react to → [prototype](../engineering/prototype.md).

The common case is a grilling session that stalls because some of what surfaced isn't yours to answer. Run `/to-questionnaire` in that same conversation — the session is already in context, so the drafting draws on it — take those questions offline, then bring the answers back and carry on.

## The send, not the subject

The interview is two exchanges, and then it stops.

- **Who is it going to?** Their role, expertise, and relationship to you — this fixes the tone and how much context the document must carry.
- **What do you need back?** The concrete decisions or facts you can't resolve alone — this becomes the checklist the finished document is measured against.

Everything after that is drafting. The file lands at `to-questionnaire-<slug>.md` in the current directory: purpose line, short context section, questions most-important-first under themed headings, one idea per question with an answer stub, explicit permission to answer "I don't know", and a closing catch-all. It is deliberately flat (no branching logic) and single-recipient — if three people hold three parts of the answer, run it three times.

## It's working if

- It asks about the recipient and what you need back, then stops asking. A question about the subject itself is the skill off the rails.
- Every item you named as "what I need back" is traceable to a question in the file.
- You could hand the file to someone who wasn't in the conversation and they would know why they got it and by when to reply.
- The answers that come back are usable input for a new grilling round, rather than a fresh set of questions.

## Where it fits

`to-questionnaire` is a reach-for-it-anytime standalone. It sits at the boundary of your own knowledge, where the next move is another person rather than another skill — most often mid-flow, when planning has stalled on something that isn't yours to decide. Its neighbour is [grill-me](./grill-me.md), and the two split on where the answers live: grilling mines you, a questionnaire mines someone else. What comes back feeds another grilling round, or [grill-with-docs](../engineering/grill-with-docs.md) / [to-spec](../engineering/to-spec.md) if the work is heading for a build. When you're unsure which skill fits the moment, [ask-witify](../engineering/ask-witify.md) routes you.

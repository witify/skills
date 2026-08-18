Quickstart:

```bash
npx skills add witify/skills --skill=loom
```

```bash
npx skills update loom
```

[Source](https://github.com/witify/skills/tree/main/skills/productivity/loom)

## What it does

Analyzes a Loom video in detail without anyone watching it in real time: it pulls the transcript (with speaker names and timestamps), the chapter list, and Loom's own metadata, then inspects the actual picture by extracting frames with ffmpeg. It never downloads the whole video to look at one moment — Loom's signed mp4 URLs support HTTP range seeks, so a frame anywhere in a 90-minute recording costs about two seconds.

## When to reach for it

Type `/loom <link>`, or the agent reaches for it automatically when a loom.com link appears in whatever is being worked — a ClickUp or Linear task, a grill, a spec, a pasted message — and the video's content matters to the task.

## Prerequisites

`ffmpeg` on PATH (the skill will suggest the install command if it's missing) and `curl`, which ships with Linux, macOS, and Windows 10+. Works on all three platforms; the API helper is a plain bash + curl script. Password-protected videos work (it asks you for the password); videos restricted to the owner's workspace don't — no API serves those anonymously.

## Map, then evidence

The skill's discipline is that the transcript is the **map** and frames are the **evidence**. It reads the map first — transcript, chapters, Loom's AI summary — and only then aims ffmpeg at the timestamps that matter: chapter starts, "as you can see" moments, the second a bug is reproduced on screen. On meeting recordings it crops every frame to the shared screen, dropping the webcam tiles. What comes back is an answer anchored to `[hh:mm:ss]` timestamps, separating what was *said* from what was *shown* — which disagree more often than expected. When the deliverable is a ClickUp or Linear task, it attaches a handful of load-bearing screenshots rather than everything it looked at — tracker uploads cost more than the analysis itself.

## It's working if

- The answer cites timestamps and speakers, not vague paraphrase.
- Frames were extracted at specific moments (a few seconds each), not a blind full download.
- On a meeting recording, frames show the shared screen only — no webcam tiles.
- Sections it didn't examine are declared, not silently skipped.

## Where it fits

A reach-for-it-anytime standalone that mostly fires *inside* other flows: a grill where the user drops a Loom instead of typing the context, or a triage/implement pass over a ticket whose repro is a recording. See [ask-witify](../engineering/ask-witify.md) for the map of the whole set.

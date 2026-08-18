---
"witify-skills": minor
---

New **loom** skill (productivity, model-invoked): analyze a Loom video in detail without watching it — transcript with speaker names and timestamps, chapter list, and actual frames inspected via ffmpeg. It fires whenever a loom.com link shows up in a task, grill, or conversation and the video's content matters. The transcript is the map, frames are the evidence: it reads the transcript first, then seeks ffmpeg directly into Loom's signed mp4 over HTTP range requests, so one frame anywhere in a 90-minute recording costs ~2 seconds instead of a full download. Cross-platform (linux, macOS, Windows git-bash) with only curl + ffmpeg required; handles password-protected videos and falls back to yt-dlp for the rare HLS-only ones.

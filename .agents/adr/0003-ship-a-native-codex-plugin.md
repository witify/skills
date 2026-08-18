# Ship a native Codex plugin (lifts ADR 0002's deferral)

[ADR 0002](./0002-ship-as-a-claude-code-plugin.md) deferred a native Codex plugin because `.codex-plugin/plugin.json` accepted `skills` only as a **single path string**, which could not express a curated subset of this repo's bucketed layout. That constraint is gone: [openai/codex#28790](https://github.com/openai/codex/pull/28790) (merged 2026-06-18, shipped by codex-cli 0.147.0) lets `skills` be an **array of directory paths**, each scanned recursively and deduped.

## Decision

Ship `.codex-plugin/plugin.json` with `skills` listing exactly the promoted buckets:

```json
"skills": ["./skills/engineering/", "./skills/productivity/", "./skills/migration/"]
```

Verified end to end with codex-cli 0.147.0 against a local marketplace add of this repo:

- **Codex reads `.claude-plugin/marketplace.json`** — the formats are compatible, so the repo is one marketplace for both harnesses. `codex plugin marketplace add witify/skills` registers marketplace `witify`; `codex plugin add witify-skills@witify` installs.
- **Curation holds**: a `codex exec` skill enumeration after install shows every promoted model-invoked skill under the `witify-skills:` prefix and none of `in-progress/`. (The install *cache* copies the whole repo tree; only the manifest's listed roots are loaded as skills.)
- **User-invoked skills don't appear in the model's skill list** — their `agents/openai.yaml` sets `allow_implicit_invocation: false`, which is the intended behaviour per [.agents/invocation.md](../invocation.md); they remain explicitly reachable.
- The remote (`owner/repo`) marketplace form runs the same code path after cloning; re-verify once the manifest is on `main`.

## Differences from the Claude manifest — read before editing either

- **Selection granularity differs.** `.claude-plugin/plugin.json` lists promoted skills **one by one**; `.codex-plugin/plugin.json` lists the promoted **buckets**, so a new skill in a promoted bucket ships on Codex with no manifest edit, while the Claude array still needs its explicit entry. Moving a draft *into* a promoted bucket publishes it on Codex immediately — `in-progress/` remains the only holding pen.
- **Version is synced, never hand-bumped.** `scripts/sync-plugin-version.mjs` now writes `package.json`'s version into **both** plugin manifests during the release flow.

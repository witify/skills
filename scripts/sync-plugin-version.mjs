// Copies package.json's version into .claude-plugin/plugin.json and
// .codex-plugin/plugin.json, so the manifests can never drift. Runs as part
// of `npm run version` (see the Release workflow); Claude Code and Codex use
// the plugin version to decide when installed users see an update.
import fs from "node:fs";

const { version } = JSON.parse(fs.readFileSync("package.json", "utf8"));

for (const path of [".claude-plugin/plugin.json", ".codex-plugin/plugin.json"]) {
  const plugin = JSON.parse(fs.readFileSync(path, "utf8"));
  if (plugin.version !== version) {
    plugin.version = version;
    fs.writeFileSync(path, JSON.stringify(plugin, null, 2) + "\n");
    console.log(`${path}: version -> ${version}`);
  }
}

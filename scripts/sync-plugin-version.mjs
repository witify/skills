// Copies package.json's version into .claude-plugin/plugin.json, so the two
// manifests can never drift. Runs as part of `npm run version` (see the
// Release workflow); Claude Code uses the plugin version to decide when
// installed users see an update.
import fs from "node:fs";

const { version } = JSON.parse(fs.readFileSync("package.json", "utf8"));
const path = ".claude-plugin/plugin.json";
const plugin = JSON.parse(fs.readFileSync(path, "utf8"));

if (plugin.version !== version) {
  plugin.version = version;
  fs.writeFileSync(path, JSON.stringify(plugin, null, 2) + "\n");
  console.log(`${path}: version -> ${version}`);
}

/**
 * Copies plugins/InterfaceTypesSync.luau into the Roblox Studio Plugins folder.
 */
const fs = require("fs");
const path = require("path");

const source = path.join(__dirname, "../plugins/InterfaceTypesSync.luau");
const pluginsDir = path.join(process.env.LOCALAPPDATA || "", "Roblox", "Plugins");
const dest = path.join(pluginsDir, "InterfaceTypesSync.luau");

if (!process.env.LOCALAPPDATA) {
  console.error("LOCALAPPDATA not found (Windows only). Copy plugins/InterfaceTypesSync.luau manually.");
  process.exit(1);
}

if (!fs.existsSync(source)) {
  console.error("Plugin source missing:", source);
  process.exit(1);
}

fs.mkdirSync(pluginsDir, { recursive: true });
fs.copyFileSync(source, dest);
console.log("✅ Plugin installed at:", dest);
console.log("Restart Roblox Studio (or toggle the plugin) and run npm run dev.");

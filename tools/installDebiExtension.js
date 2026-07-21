#!/usr/bin/env node
/**
 * Installs the Debi extension into Cursor/VS Code (dev mode via symlink/junction).
 *
 *   node tools/installDebiExtension.js
 */
const fs = require("fs");
const path = require("path");
const os = require("os");
const { execSync } = require("child_process");

const source = path.resolve(__dirname, "../extensions/debi");
const home = os.homedir();

const targets = [
  path.join(home, ".cursor", "extensions", "animedomains.debi-0.2.1"),
  path.join(home, ".vscode", "extensions", "animedomains.debi-0.2.1"),
];

if (!fs.existsSync(source)) {
  console.error("Missing extensions/debi");
  process.exit(1);
}

for (const dest of targets) {
  const parent = path.dirname(dest);
  fs.mkdirSync(parent, { recursive: true });

  if (fs.existsSync(dest)) {
    fs.rmSync(dest, { recursive: true, force: true });
  }

  try {
    if (process.platform === "win32") {
      execSync(`cmd /c mklink /J "${dest}" "${source}"`, { stdio: "inherit" });
    } else {
      fs.symlinkSync(source, dest, "dir");
    }
    console.log("✅ Linked:", dest);
  } catch (error) {
    // Fallback: copy
    fs.cpSync(source, dest, { recursive: true });
    console.log("✅ Copied:", dest);
  }
}

console.log("Restart Cursor/VS Code and open a .debi file");

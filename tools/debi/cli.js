#!/usr/bin/env node
/**
 * Debi CLI — gera Client/Server.luau ao lado de cada .debi
 *
 *   node tools/debi/cli.js --all
 *   node tools/debi/cli.js src/Networker/Game/game.debi
 *   node tools/debi/cli.js --check src/Networker/Game/game.debi
 */

const fs = require("fs");
const path = require("path");
const { parseDebi } = require("./parse");
const { generateServer, generateClient } = require("./codegen");

const REPO_ROOT = path.resolve(__dirname, "../..");
const RUNTIME_REQUIRE = "ReplicatedStorage.Shareds.Modules.Debi";
const DEFAULT_CHANNELS = [
  "src/Networker/Game/game.debi",
  "src/Networker/Secondary/secondary.debi",
  "src/Networker/Validations/validations.debi",
];

function usage() {
  console.log(`Usage:
  node tools/debi/cli.js --all
  node tools/debi/cli.js <file.debi>
  node tools/debi/cli.js --check <file.debi>
`);
}

function resolveOutput(outputOpt, fallback) {
  if (!outputOpt) return fallback;
  if (path.isAbsolute(outputOpt)) return outputOpt;
  return path.join(REPO_ROOT, outputOpt);
}

function buildOne(filePath, checkOnly) {
  const source = fs.readFileSync(filePath, "utf8");
  const ast = parseDebi(source, filePath);
  const channel = ast.opts.channel || path.basename(path.dirname(filePath));

  if (checkOnly) {
    console.log(`[Debi] OK ${channel} — ${ast.events.length} event(s), ${Object.keys(ast.types).length} type(s)`);
    return;
  }

  const dir = path.dirname(filePath);
  const serverPath = resolveOutput(ast.opts.server_output, path.join(dir, "Server.luau"));
  const clientPath = resolveOutput(ast.opts.client_output, path.join(dir, "Client.luau"));

  const serverSource = generateServer(ast, RUNTIME_REQUIRE, channel);
  const clientSource = generateClient(ast, RUNTIME_REQUIRE, channel);

  fs.mkdirSync(path.dirname(serverPath), { recursive: true });
  fs.mkdirSync(path.dirname(clientPath), { recursive: true });
  fs.writeFileSync(serverPath, serverSource, "utf8");
  fs.writeFileSync(clientPath, clientSource, "utf8");

  console.log(`[Debi] ${channel} → ${path.relative(REPO_ROOT, serverPath)}`);
  console.log(`[Debi] ${channel} → ${path.relative(REPO_ROOT, clientPath)}`);
}

function main() {
  const args = process.argv.slice(2);
  if (args.length === 0 || args.includes("-h") || args.includes("--help")) {
    usage();
    process.exit(args.length === 0 ? 1 : 0);
  }

  const checkOnly = args.includes("--check");
  const buildAll = args.includes("--all");

  const files = buildAll
    ? DEFAULT_CHANNELS.map((p) => path.join(REPO_ROOT, p))
    : [path.resolve(args.find((a) => !a.startsWith("-")))];

  for (const filePath of files) {
    if (!fs.existsSync(filePath)) {
      console.error(`[Debi] File not found: ${filePath}`);
      process.exit(1);
    }
    buildOne(filePath, checkOnly);
  }
}

main();

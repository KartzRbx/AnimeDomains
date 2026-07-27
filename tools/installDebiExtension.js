#!/usr/bin/env node
/**
 * Installs the Debi extension into Cursor/VS Code (copy, not junction).
 *
 *   node tools/installDebiExtension.js
 *   node tools/installDebiExtension.js --quiet
 */
const fs = require("fs");
const path = require("path");
const os = require("os");
const crypto = require("crypto");

const quiet = process.argv.includes("--quiet");
const log = (...args) => {
	if (!quiet) {
		console.log(...args);
	}
};

const source = path.resolve(__dirname, "../extensions/debi");
const home = os.homedir();

if (!fs.existsSync(source)) {
	console.error("Missing extensions/debi");
	process.exit(1);
}

const packageJson = JSON.parse(fs.readFileSync(path.join(source, "package.json"), "utf8"));
const version = packageJson.version;
const extensionId = `animedomains.debi-${version}`;

const extensionRoots = [
	path.join(home, ".cursor", "extensions"),
	path.join(home, ".vscode", "extensions"),
];

function hashTree(dir) {
	const hash = crypto.createHash("sha1");
	const stack = [dir];

	while (stack.length > 0) {
		const current = stack.pop();
		const entries = fs.readdirSync(current, { withFileTypes: true }).sort((a, b) =>
			a.name.localeCompare(b.name)
		);

		for (const entry of entries) {
			const full = path.join(current, entry.name);
			const rel = path.relative(dir, full).split(path.sep).join("/");
			hash.update(rel);

			if (entry.isDirectory()) {
				stack.push(full);
			} else if (entry.isFile()) {
				hash.update(fs.readFileSync(full));
			}
		}
	}

	return hash.digest("hex");
}

function removeOtherDebiInstalls(root, keepName) {
	if (!fs.existsSync(root)) {
		return;
	}

	for (const entry of fs.readdirSync(root, { withFileTypes: true })) {
		if (!entry.name.startsWith("animedomains.debi-")) {
			continue;
		}
		if (entry.name === keepName) {
			continue;
		}

		const full = path.join(root, entry.name);
		fs.rmSync(full, { recursive: true, force: true });
		log("Removed old Debi ext:", full);
	}
}

function installCopy(dest) {
	fs.mkdirSync(path.dirname(dest), { recursive: true });

	const sourceHash = hashTree(source);
	const stampPath = path.join(dest, ".debi-install-hash");
	if (fs.existsSync(dest) && fs.existsSync(stampPath)) {
		const existingHash = fs.readFileSync(stampPath, "utf8").trim();
		if (existingHash === sourceHash) {
			log("Debi extension up to date:", dest);
			return false;
		}
	}

	if (fs.existsSync(dest)) {
		fs.rmSync(dest, { recursive: true, force: true });
	}

	fs.cpSync(source, dest, { recursive: true });
	fs.writeFileSync(stampPath, `${sourceHash}\n`);
	log("Installed Debi extension:", dest);
	return true;
}

function ensureExtensionsJson(root, id, versionValue, relativeLocation) {
	const manifestPath = path.join(root, "extensions.json");
	if (!fs.existsSync(root)) {
		return;
	}

	let list = [];
	if (fs.existsSync(manifestPath)) {
		try {
			list = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
			if (!Array.isArray(list)) {
				list = [];
			}
		} catch (_error) {
			list = [];
		}
	}

	const identifier = { id };
	const next = list.filter((entry) => !(entry && entry.identifier && entry.identifier.id === id));
	next.push({
		identifier,
		version: versionValue,
		location: {
			$mid: 1,
			path: `/${path.join(root, relativeLocation).replace(/\\/g, "/")}`,
			scheme: "file",
		},
		relativeLocation,
	});

	fs.writeFileSync(manifestPath, JSON.stringify(next));
}

let changed = false;

for (const root of extensionRoots) {
	fs.mkdirSync(root, { recursive: true });
	removeOtherDebiInstalls(root, extensionId);
	const dest = path.join(root, extensionId);
	if (installCopy(dest)) {
		changed = true;
	}
	ensureExtensionsJson(root, "animedomains.debi", version, extensionId);
}

if (changed) {
	console.log(`[debi] Extension ${version} updated — reload Cursor window for .debi colors`);
} else {
	log(`[debi] Extension ${version} already installed`);
}

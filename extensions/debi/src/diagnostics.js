const vscode = require("vscode");
const path = require("path");
const fs = require("fs");

function loadParser(workspaceRoot) {
	const candidates = [
		workspaceRoot && path.join(workspaceRoot, "tools/debi/parse.js"),
		path.join(__dirname, "../../../tools/debi/parse.js"),
	].filter(Boolean);

	for (const candidate of candidates) {
		if (fs.existsSync(candidate)) {
			delete require.cache[require.resolve(candidate)];
			return require(candidate);
		}
	}
	return null;
}

function workspaceRootFor(document) {
	const folder = vscode.workspace.getWorkspaceFolder(document.uri);
	if (folder) return folder.uri.fsPath;
	const folders = vscode.workspace.workspaceFolders;
	return folders && folders[0] ? folders[0].uri.fsPath : null;
}

function parseErrorLocation(message) {
	const match = message.match(/at\s+(\d+):(\d+)/);
	if (!match) return null;
	return {
		line: Number(match[1]) - 1,
		character: Math.max(0, Number(match[2]) - 1),
	};
}

function makeDiag(document, line, character, message, severity = vscode.DiagnosticSeverity.Error) {
	const safeLine = Math.min(Math.max(line, 0), Math.max(document.lineCount - 1, 0));
	if (character > 0) {
		const start = new vscode.Position(safeLine, character);
		return new vscode.Diagnostic(new vscode.Range(start, start.translate(0, 1)), message, severity);
	}
	return new vscode.Diagnostic(document.lineAt(safeLine).range, message, severity);
}

function locateSymbol(document, symbol) {
	const text = document.getText();
	const pattern = new RegExp(`\\b${symbol.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}\\b`);
	const match = pattern.exec(text);
	if (!match) return { line: 0, character: 0 };
	const pos = document.positionAt(match.index);
	return { line: pos.line, character: pos.character };
}

function createDiagnosticsController(context) {
	const collection = vscode.languages.createDiagnosticCollection("debi");
	context.subscriptions.push(collection);

	let timer = null;

	function validate(document) {
		if (document.languageId !== "debi") return;

		const root = workspaceRootFor(document);
		const parser = loadParser(root);
		if (!parser) {
			collection.set(document.uri, [
				makeDiag(
					document,
					0,
					0,
					"Debi parser not found (open the AnimeDomains workspace / tools/debi).",
					vscode.DiagnosticSeverity.Warning
				),
			]);
			return;
		}

		const diagnostics = [];
		try {
			const ast = parser.parseDebi(document.getText(), document.fileName);

			const seenEvents = new Set();
			const seenTypes = new Set();
			const knownTypes = new Set([
				"u8",
				"u16",
				"u32",
				"i8",
				"i16",
				"i32",
				"f32",
				"f64",
				"bool",
				"string",
				"vector",
				...Object.keys(ast.types || {}),
			]);

			for (const name of Object.keys(ast.types || {})) {
				if (seenTypes.has(name)) {
					const loc = locateSymbol(document, name);
					diagnostics.push(makeDiag(document, loc.line, loc.character, `Duplicate type '${name}'`));
				}
				seenTypes.add(name);
			}

			function walkType(typeNode, label) {
				if (!typeNode) return;
				if (typeNode.kind === "named" && !knownTypes.has(typeNode.name)) {
					const loc = locateSymbol(document, typeNode.name);
					diagnostics.push(
						makeDiag(document, loc.line, loc.character, `Unknown type '${typeNode.name}' (${label})`)
					);
				} else if (typeNode.kind === "array") {
					walkType(typeNode.element, label);
				} else if (typeNode.kind === "vector") {
					for (const c of typeNode.components || []) walkType(c, label);
				}
			}

			for (const [name, def] of Object.entries(ast.types || {})) {
				if (def.kind === "struct") {
					for (const field of def.fields || []) walkType(field.type, `${name}.${field.name}`);
				} else if (def.kind === "alias") {
					walkType(def.type, name);
				}
			}

			for (const event of ast.events || []) {
				if (seenEvents.has(event.name)) {
					const loc = locateSymbol(document, event.name);
					diagnostics.push(makeDiag(document, loc.line, loc.character, `Duplicate event '${event.name}'`));
				}
				seenEvents.add(event.name);
				for (const field of event.data || []) {
					walkType(field.type, `${event.name}.${field.name}`);
				}
			}
		} catch (error) {
			const message = error && error.message ? String(error.message) : String(error);
			const loc = parseErrorLocation(message) || { line: 0, character: 0 };
			diagnostics.push(makeDiag(document, loc.line, loc.character, message.replace(/\s*\([^)]*\)\s*$/, "")));
		}

		collection.set(document.uri, diagnostics);
	}

	function schedule(document) {
		if (timer) clearTimeout(timer);
		timer = setTimeout(() => validate(document), 250);
	}

	context.subscriptions.push(
		vscode.workspace.onDidOpenTextDocument((doc) => validate(doc)),
		vscode.workspace.onDidChangeTextDocument((e) => schedule(e.document)),
		vscode.workspace.onDidSaveTextDocument((doc) => validate(doc)),
		vscode.workspace.onDidCloseTextDocument((doc) => collection.delete(doc.uri))
	);

	return {
		validate,
		dispose() {
			if (timer) clearTimeout(timer);
			collection.dispose();
		},
	};
}

module.exports = {
	createDiagnosticsController,
};

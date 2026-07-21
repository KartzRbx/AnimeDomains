const vscode = require("vscode");

const KEYWORDS = [
	{ label: "opt", detail: "Option", documentation: "opt channel = \"Game\"" },
	{ label: "event", detail: "Event", documentation: "Define a network event" },
	{ label: "type", detail: "Type alias", documentation: "type Name = struct { ... }" },
	{ label: "struct", detail: "Struct", documentation: "Structured type body" },
];

const FROM_VALUES = ["Server", "Client"];
const RELIABILITY = ["Reliable", "Unreliable"];
const CALL_MODES = ["SingleAsync", "ManyAsync", "SingleSync", "ManySync"];
const PRIMITIVES = ["u8", "u16", "u32", "i8", "i16", "i32", "f32", "f64", "bool", "string", "vector"];
const OPT_KEYS = ["channel", "server_output", "client_output"];

function linePrefix(document, position) {
	return document.lineAt(position.line).text.slice(0, position.character);
}

function collectUserTypes(document) {
	const text = document.getText();
	const names = new Set();
	for (const match of text.matchAll(/\btype\s+([A-Za-z_][A-Za-z0-9_]*)\s*=/g)) {
		names.add(match[1]);
	}
	return [...names];
}

function isInsideEventBlock(document, position) {
	const text = document.getText(new vscode.Range(new vscode.Position(0, 0), position));
	const lastEvent = Math.max(text.lastIndexOf("event "), text.lastIndexOf("event\t"), text.lastIndexOf("event\n"));
	if (lastEvent < 0) return false;
	const after = text.slice(lastEvent);
	let depth = 0;
	let seenBrace = false;
	for (const ch of after) {
		if (ch === "{") {
			depth += 1;
			seenBrace = true;
		} else if (ch === "}") {
			depth -= 1;
		}
	}
	return seenBrace && depth > 0;
}

function item(label, kind, opts = {}) {
	const completion = new vscode.CompletionItem(label, kind);
	completion.detail = opts.detail;
	if (opts.documentation) {
		completion.documentation = new vscode.MarkdownString(opts.documentation);
	}
	if (opts.insertText !== undefined) {
		completion.insertText =
			typeof opts.insertText === "string" && opts.insertText.includes("${")
				? new vscode.SnippetString(opts.insertText)
				: opts.insertText;
	}
	if (opts.sortText) completion.sortText = opts.sortText;
	if (opts.filterText) completion.filterText = opts.filterText;
	if (opts.preselect) completion.preselect = true;
	if (opts.command) completion.command = opts.command;
	completion.commitCharacters = opts.commitCharacters || [",", " ", "\n"];
	return completion;
}

function valuesList(values, detail) {
	return values.map((value, index) =>
		item(value, vscode.CompletionItemKind.EnumMember, {
			detail,
			sortText: `0${index}_${value}`,
			preselect: index === 0,
			filterText: value,
		})
	);
}

function suggestTrigger() {
	return {
		command: "editor.action.triggerSuggest",
		title: "Trigger Suggest",
	};
}

/**
 * @param {vscode.TextDocument} document
 * @param {vscode.Position} position
 * @param {vscode.CancellationToken} _token
 * @param {vscode.CompletionContext} context
 */
function provideCompletionItems(document, position, _token, context) {
	const rawPrefix = linePrefix(document, position);
	const prefix = rawPrefix.trimEnd();
	const trimmed = prefix.trim();

	// from: → Server | Client  (before any other ":" logic)
	if (/\bfrom\s*:\s*$/i.test(prefix) || /\bfrom\s*:\s+\w*$/i.test(prefix)) {
		return new vscode.CompletionList(valuesList(FROM_VALUES, "from"), false);
	}

	// type: inside event → Reliable | Unreliable
	if (
		isInsideEventBlock(document, position) &&
		!/^type\s+[A-Za-z_]/.test(trimmed) &&
		(/\btype\s*:\s*$/i.test(prefix) || /\btype\s*:\s+\w*$/i.test(prefix))
	) {
		return new vscode.CompletionList(valuesList(RELIABILITY, "reliability"), false);
	}

	// call: → modes
	if (/\bcall\s*:\s*$/i.test(prefix) || /\bcall\s*:\s+\w*$/i.test(prefix)) {
		return new vscode.CompletionList(valuesList(CALL_MODES, "call mode"), false);
	}

	if (/^opt\s+\w*$/.test(trimmed) || /\bopt\s+\w*$/.test(prefix)) {
		return new vscode.CompletionList(
			OPT_KEYS.map((key) => item(key, vscode.CompletionItemKind.Property, { detail: "opt key" })),
			false
		);
	}

	// data field type position: name: |
	// Exclude from/type/call value positions (already handled)
	const isEventMeta =
		/\bfrom\s*:/i.test(prefix) ||
		(/\btype\s*:/i.test(prefix) && isInsideEventBlock(document, position)) ||
		/\bcall\s*:/i.test(prefix);

	if (!isEventMeta && (/:\s*$/.test(prefix) || /:\s+[A-Za-z0-9_]*$/.test(prefix))) {
		const items = [];
		for (const prim of PRIMITIVES) {
			items.push(
				item(prim, vscode.CompletionItemKind.TypeParameter, {
					detail: "primitive",
					sortText: `0_${prim}`,
					insertText: prim === "vector" ? "vector(${1:f32}, ${2:f32}, ${3:f32})" : prim,
				})
			);
		}
		for (const name of collectUserTypes(document)) {
			items.push(
				item(name, vscode.CompletionItemKind.Class, {
					detail: "user type",
					sortText: `1_${name}`,
				})
			);
		}
		items.push(
			item("struct", vscode.CompletionItemKind.Keyword, {
				detail: "struct body",
				insertText: "struct {\n\t${1:Field}: ${2:f32},\n}",
			})
		);
		return new vscode.CompletionList(items, false);
	}

	if (isInsideEventBlock(document, position)) {
		const fieldItems = [
			item("from", vscode.CompletionItemKind.Field, {
				detail: "Server | Client",
				insertText: "from: ",
				command: suggestTrigger(),
				sortText: "0_from",
			}),
			item("type", vscode.CompletionItemKind.Field, {
				detail: "Reliable | Unreliable",
				insertText: "type: ",
				command: suggestTrigger(),
				sortText: "1_type",
			}),
			item("call", vscode.CompletionItemKind.Field, {
				detail: "Call mode",
				insertText: "call: ",
				command: suggestTrigger(),
				sortText: "2_call",
			}),
			item("data", vscode.CompletionItemKind.Field, {
				detail: "Payload",
				insertText: "data: (${1:field}: ${2:f32}),",
				sortText: "3_data",
			}),
		];

		// Also offer values if user is mid-line on from/type/call without colon yet
		if (/^\s*from\s*$/i.test(prefix)) {
			return new vscode.CompletionList(
				[
					item("from", vscode.CompletionItemKind.Field, {
						insertText: "from: ",
						command: suggestTrigger(),
					}),
				],
				false
			);
		}

		return new vscode.CompletionList(fieldItems, false);
	}

	const top = KEYWORDS.map((kw) =>
		item(kw.label, vscode.CompletionItemKind.Keyword, {
			detail: kw.detail,
			documentation: kw.documentation,
		})
	);
	return new vscode.CompletionList(top, false);
}

module.exports = {
	provideCompletionItems,
	PRIMITIVES,
	CALL_MODES,
	RELIABILITY,
	FROM_VALUES,
};

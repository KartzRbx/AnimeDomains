const vscode = require("vscode");
const { provideCompletionItems } = require("./src/completions");
const { provideHover } = require("./src/hover");
const { createDiagnosticsController } = require("./src/diagnostics");

/**
 * @param {vscode.ExtensionContext} context
 */
function activate(context) {
	const diagnostics = createDiagnosticsController(context);

	const selector = [
		{ language: "debi", scheme: "file" },
		{ language: "debi", scheme: "untitled" },
	];

	context.subscriptions.push(
		vscode.languages.registerCompletionItemProvider(
			selector,
			{
				provideCompletionItems(document, position, token, completionContext) {
					return provideCompletionItems(document, position, token, completionContext);
				},
			},
			":",
			" ",
			"\n",
			"\t",
			"("
		)
	);

	context.subscriptions.push(
		vscode.languages.registerHoverProvider(selector, {
			provideHover(document, position) {
				return provideHover(document, position);
			},
		})
	);

	context.subscriptions.push(
		vscode.commands.registerCommand("debi.revalidate", () => {
			const editor = vscode.window.activeTextEditor;
			if (editor && editor.document.languageId === "debi") {
				diagnostics.validate(editor.document);
			}
		})
	);

	context.subscriptions.push(diagnostics);

	for (const doc of vscode.workspace.textDocuments) {
		if (doc.languageId === "debi") {
			diagnostics.validate(doc);
		}
	}
}

function deactivate() {}

module.exports = {
	activate,
	deactivate,
};

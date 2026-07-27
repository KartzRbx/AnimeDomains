const vscode = require("vscode");

const DOCS = {
	opt: "Config option. Ex: `opt channel = \"Game\"`",
	event: "Network event. Requires `from`, `type`, `call`, optional `data`.",
	type: "Type alias or struct definition.",
	struct: "Structured record type with named fields.",
	from: "`Server` or `Client` — who fires the event.",
	call: "Listener mode: SingleAsync, ManyAsync, SingleSync, ManySync.",
	data: "Payload fields `(name: type, ...)`.",
	Server: "Fired by the server.",
	Client: "Fired by the client.",
	Reliable: "Ordered, guaranteed delivery (RemoteEvent).",
	Unreliable: "Best-effort, batched; max ~1000 bytes.",
	SingleAsync: "One callback, invoked with task.spawn.",
	ManyAsync: "Many callbacks via `.On`, async.",
	SingleSync: "One callback, synchronous (avoid yielding).",
	ManySync: "Many callbacks, synchronous.",
	u8: "Unsigned 8-bit integer (0–255).",
	u16: "Unsigned 16-bit integer.",
	u32: "Unsigned 32-bit integer.",
	i8: "Signed 8-bit integer.",
	i16: "Signed 16-bit integer.",
	i32: "Signed 32-bit integer.",
	f32: "32-bit float.",
	f64: "64-bit float.",
	bool: "Boolean (1 byte).",
	string: "UTF-8 string (`u16` length + bytes).",
	vector: "`vector(f32, f32, f32)` packed components.",
	Player: "Roblox `Player` — writes `UserId` (`f64`), reads via `Players:GetPlayerByUserId` (`Player?`).",
	channel: "Remote channel name under `_debi/<channel>`.",
	server_output: "Path for generated Server.luau.",
	client_output: "Path for generated Client.luau.",
};

function wordAt(document, position) {
	const range = document.getWordRangeAtPosition(position, /[A-Za-z_][A-Za-z0-9_]*/);
	if (!range) return null;
	return { range, word: document.getText(range) };
}

function provideHover(document, position) {
	const hit = wordAt(document, position);
	if (!hit) return null;

	const doc = DOCS[hit.word];
	if (!doc) {
		// user type?
		const types = [...document.getText().matchAll(/\btype\s+([A-Za-z_][A-Za-z0-9_]*)\s*=/g)].map((m) => m[1]);
		if (types.includes(hit.word)) {
			return new vscode.Hover(new vscode.MarkdownString(`**${hit.word}** — user-defined Debi type`), hit.range);
		}
		return null;
	}

	const md = new vscode.MarkdownString();
	md.appendMarkdown(`**${hit.word}**\n\n${doc}`);
	return new vscode.Hover(md, hit.range);
}

module.exports = {
	provideHover,
	DOCS,
};

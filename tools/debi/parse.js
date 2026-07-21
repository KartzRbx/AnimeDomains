/**
 * Debi .debi parser (Zap-inspired IDL)
 */

const { parseType } = require("./packTypes");

function stripComments(source) {
  return source
    .replace(/--\[\[[\s\S]*?\]\]/g, "")
    .replace(/--[^\n]*/g, "");
}

function tokenize(source) {
  const text = stripComments(source);
  const tokens = [];
  let i = 0;

  const push = (type, value, line, col) => tokens.push({ type, value, line, col });

  let line = 1;
  let col = 1;

  while (i < text.length) {
    const ch = text[i];

    if (ch === "\n") {
      line += 1;
      col = 1;
      i += 1;
      continue;
    }

    if (/\s/.test(ch)) {
      i += 1;
      col += 1;
      continue;
    }

    if (ch === '"' || ch === "'") {
      const quote = ch;
      let j = i + 1;
      let value = "";
      while (j < text.length && text[j] !== quote) {
        if (text[j] === "\\") {
          value += text[j + 1] || "";
          j += 2;
          continue;
        }
        value += text[j];
        j += 1;
      }
      push("string", value, line, col);
      col += j - i + 1;
      i = j + 1;
      continue;
    }

    if (/[A-Za-z_]/.test(ch)) {
      let j = i + 1;
      while (j < text.length && /[A-Za-z0-9_]/.test(text[j])) j += 1;
      // allow Type[] after name — handled in type parse, not tokenize
      const value = text.slice(i, j);
      const keywords = new Set([
        "opt",
        "event",
        "type",
        "struct",
        "from",
        "call",
        "data",
        "Server",
        "Client",
        "Reliable",
        "Unreliable",
        "ManyAsync",
        "ManySync",
        "SingleAsync",
        "SingleSync",
      ]);
      push(keywords.has(value) ? "keyword" : "ident", value, line, col);
      col += j - i;
      i = j;
      continue;
    }

    if (/[0-9]/.test(ch)) {
      let j = i + 1;
      while (j < text.length && /[0-9.]/.test(text[j])) j += 1;
      push("number", text.slice(i, j), line, col);
      col += j - i;
      i = j;
      continue;
    }

    const two = text.slice(i, i + 2);
    if (two === "[]" || two === "..") {
      push("symbol", two, line, col);
      i += 2;
      col += 2;
      continue;
    }

    if ("{}():[],=.".includes(ch)) {
      push("symbol", ch, line, col);
      i += 1;
      col += 1;
      continue;
    }

    throw new Error(`[Debi] Unexpected '${ch}' at ${line}:${col}`);
  }

  push("eof", "", line, col);
  return tokens;
}

function createParser(tokens) {
  let i = 0;

  const peek = () => tokens[i];
  const at = (type, value) => {
    const t = peek();
    return t && t.type === type && (value === undefined || t.value === value);
  };
  const eat = (type, value) => {
    const t = peek();
    if (!t || t.type !== type || (value !== undefined && t.value !== value)) {
      throw new Error(
        `[Debi] Expected ${type}${value ? ` '${value}'` : ""} at ${t ? `${t.line}:${t.col}` : "EOF"}, got ${t ? `${t.type} '${t.value}'` : "EOF"}`
      );
    }
    i += 1;
    return t;
  };
  const optional = (type, value) => {
    if (at(type, value)) return eat(type, value);
    return null;
  };

  function parseTypeNode() {
    // vector(...)
    if (at("ident", "vector") || (at("keyword") && peek().value === "vector")) {
      // vector is ident usually
    }
    if (peek().type === "ident" && peek().value === "vector") {
      eat("ident", "vector");
      eat("symbol", "(");
      const components = [];
      components.push(parseTypeNode());
      while (optional("symbol", ",")) {
        components.push(parseTypeNode());
      }
      eat("symbol", ")");
      let node = { kind: "vector", components };
      while (optional("symbol", "[]")) {
        node = { kind: "array", element: node };
      }
      return node;
    }

    if (at("keyword", "struct")) {
      // inline struct not supported in field position in v1 — only via type alias
      throw new Error(`[Debi] Inline struct not supported; use type Name = struct { ... } at ${peek().line}:${peek().col}`);
    }

    const nameTok = eat("ident");
    let node = { kind: "named", name: nameTok.value };
    while (optional("symbol", "[]")) {
      node = { kind: "array", element: node };
    }
    return node;
  }

  function parseStructBody() {
    eat("symbol", "{");
    const fields = [];
    while (!at("symbol", "}") && !at("eof")) {
      const fieldName = eat("ident").value;
      eat("symbol", ":");
      const fieldType = parseTypeNode();
      fields.push({ name: fieldName, type: fieldType });
      optional("symbol", ",");
    }
    eat("symbol", "}");
    return fields;
  }

  function parseDataTuple() {
    eat("symbol", "(");
    const fields = [];
    if (!at("symbol", ")")) {
      // named: name: type  OR unnamed: type
      do {
        if (at("ident") && tokens[i + 1] && tokens[i + 1].type === "symbol" && tokens[i + 1].value === ":") {
          const name = eat("ident").value;
          eat("symbol", ":");
          const type = parseTypeNode();
          fields.push({ name, type });
        } else {
          const type = parseTypeNode();
          fields.push({ name: `arg${fields.length + 1}`, type });
        }
      } while (optional("symbol", ","));
    }
    eat("symbol", ")");
    return fields;
  }

  function parseEvent() {
    eat("keyword", "event");
    const name = eat("ident").value;
    eat("symbol", "=");
    eat("symbol", "{");

    let from = null;
    let reliability = "Reliable";
    let call = "SingleAsync";
    let data = [];

    while (!at("symbol", "}") && !at("eof")) {
      if (at("keyword", "from") || (at("ident") && peek().value === "from")) {
        if (at("ident", "from")) eat("ident", "from");
        else eat("keyword", "from");
        eat("symbol", ":");
        from = eat("keyword").value; // Server | Client
        optional("symbol", ",");
        continue;
      }
      if (at("keyword", "type") || (at("ident") && peek().value === "type")) {
        // event field "type:" — conflict with keyword type
        if (at("keyword", "type")) eat("keyword", "type");
        else eat("ident", "type");
        eat("symbol", ":");
        reliability = eat("keyword").value; // Reliable | Unreliable
        optional("symbol", ",");
        continue;
      }
      if (at("keyword", "call") || (at("ident") && peek().value === "call")) {
        if (at("ident", "call")) eat("ident", "call");
        else eat("keyword", "call");
        eat("symbol", ":");
        call = eat("keyword").value;
        optional("symbol", ",");
        continue;
      }
      if (at("keyword", "data") || (at("ident") && peek().value === "data")) {
        if (at("ident", "data")) eat("ident", "data");
        else eat("keyword", "data");
        eat("symbol", ":");
        if (at("symbol", "(")) {
          data = parseDataTuple();
        } else {
          // single unnamed type
          const type = parseTypeNode();
          data = [{ name: "value", type }];
        }
        optional("symbol", ",");
        continue;
      }
      throw new Error(`[Debi] Unknown event field '${peek().value}' at ${peek().line}:${peek().col}`);
    }

    eat("symbol", "}");
    if (!from) throw new Error(`[Debi] event ${name} missing from:`);

    return { name, from, reliability, call, data };
  }

  function parseTypeAlias() {
    eat("keyword", "type");
    const name = eat("ident").value;
    eat("symbol", "=");

    if (at("keyword", "struct") || (at("ident") && peek().value === "struct")) {
      if (at("keyword", "struct")) eat("keyword", "struct");
      else eat("ident", "struct");
      const fields = parseStructBody();
      return { name, kind: "struct", fields };
    }

    const type = parseTypeNode();
    return { name, kind: "alias", type };
  }

  function parseOpt() {
    eat("keyword", "opt");
    const key = eat("ident").value;
    eat("symbol", "=");
    let value;
    if (at("string")) value = eat("string").value;
    else if (at("number")) value = Number(eat("number").value);
    else if (at("keyword", "true") || at("ident", "true")) {
      eat(peek().type);
      value = true;
    } else if (at("keyword", "false") || at("ident", "false")) {
      eat(peek().type);
      value = false;
    } else {
      value = eat("ident").value;
    }
    return { key, value };
  }

  function parse() {
    const opts = {};
    const events = [];
    const types = {};

    while (!at("eof")) {
      if (at("keyword", "opt")) {
        const opt = parseOpt();
        opts[opt.key] = opt.value;
        continue;
      }
      if (at("keyword", "event")) {
        events.push(parseEvent());
        continue;
      }
      if (at("keyword", "type")) {
        const alias = parseTypeAlias();
        types[alias.name] = alias;
        continue;
      }
      throw new Error(`[Debi] Unexpected token '${peek().value}' at ${peek().line}:${peek().col}`);
    }

    return { opts, events, types };
  }

  return { parse };
}

function parseDebi(source, filePath = "input.debi") {
  try {
    const tokens = tokenize(source);
    return createParser(tokens).parse();
  } catch (error) {
    error.message = `${error.message} (${filePath})`;
    throw error;
  }
}

module.exports = {
  parseDebi,
  tokenize,
  parseType,
};

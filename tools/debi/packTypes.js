/**
 * Debi type helpers — write/read Luau snippets per IDL type
 */

const PRIMITIVES = new Set([
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
]);

/** Built-in named types with custom pack/unpack (not structs / aliases). */
const BUILTINS = new Set(["Player"]);

function isPrimitive(name) {
  return PRIMITIVES.has(name);
}

function isBuiltin(name) {
  return BUILTINS.has(name);
}

function parseType(raw) {
  const text = String(raw).trim();

  // string[] or TypeName[]
  const arrayMatch = text.match(/^(.+)\[\]$/);
  if (arrayMatch) {
    return { kind: "array", element: parseType(arrayMatch[1]) };
  }

  // vector(f32, f32, f32)
  const vectorMatch = text.match(/^vector\((.+)\)$/);
  if (vectorMatch) {
    const comps = vectorMatch[1].split(",").map((s) => s.trim());
    return { kind: "vector", components: comps.map(parseType) };
  }

  // named type / primitive / struct ref
  return { kind: "named", name: text };
}

function luauType(typeNode, typeMap) {
  if (typeNode.kind === "array") {
    return `{ ${luauType(typeNode.element, typeMap)} }`;
  }
  if (typeNode.kind === "vector") {
    return "vector";
  }
  if (typeNode.kind === "named") {
    if (typeNode.name === "bool") return "boolean";
    if (typeNode.name === "string") return "string";
    if (typeNode.name === "Player") return "Player?";
    if (isPrimitive(typeNode.name)) return "number";
    const alias = typeMap[typeNode.name];
    if (alias) {
      if (alias.kind === "struct") return typeNode.name;
      return luauType(alias, typeMap);
    }
    return typeNode.name;
  }
  return "any";
}

function writeExpr(writerVar, valueExpr, typeNode, typeMap) {
  if (typeNode.kind === "named") {
    const name = typeNode.name;
    if (isPrimitive(name)) {
      return `${writerVar}:write${name}(${valueExpr})`;
    }
    if (name === "Player") {
      // f64: Roblox UserIds can exceed u32 (e.g. 8e9+)
      return [
        `do`,
        `\tassert(typeof(${valueExpr}) == "Instance" and ${valueExpr}:IsA("Player"), "[Debi] expected Player")`,
        `\t${writerVar}:writef64(${valueExpr}.UserId)`,
        `end`,
      ].join("\n");
    }
    const alias = typeMap[name];
    if (!alias) {
      throw new Error(`[Debi] Unknown type: ${name}`);
    }
    if (alias.kind === "struct") {
      return `write${name}(${writerVar}, ${valueExpr})`;
    }
    return writeExpr(writerVar, valueExpr, alias, typeMap);
  }

  if (typeNode.kind === "vector") {
    const lines = [];
    typeNode.components.forEach((comp, i) => {
      const axis = ["x", "y", "z", "w"][i] || `c${i}`;
      lines.push(writeExpr(writerVar, `${valueExpr}.${axis}`, comp, typeMap));
    });
    return lines.join("\n");
  }

  if (typeNode.kind === "array") {
    return [
      `do`,
      `\tconst __arr = ${valueExpr}`,
      `\t${writerVar}:writeu16(#__arr)`,
      `\tfor __, __item in __arr do`,
      `\t\t${writeExpr(writerVar, "__item", typeNode.element, typeMap).split("\n").join("\n\t\t")}`,
      `\tend`,
      `end`,
    ].join("\n");
  }

  throw new Error(`[Debi] Unsupported write type ${typeNode.kind}`);
}

function readExpr(readerVar, typeNode, typeMap, indent = "") {
  if (typeNode.kind === "named") {
    const name = typeNode.name;
    if (isPrimitive(name)) {
      return `${readerVar}:read${name}()`;
    }
    if (name === "Player") {
      return `Players:GetPlayerByUserId(${readerVar}:readf64())`;
    }
    const alias = typeMap[name];
    if (!alias) {
      throw new Error(`[Debi] Unknown type: ${name}`);
    }
    if (alias.kind === "struct") {
      return `read${name}(${readerVar})`;
    }
    return readExpr(readerVar, alias, typeMap, indent);
  }

  if (typeNode.kind === "vector") {
    const comps = typeNode.components.map((comp) =>
      readExpr(readerVar, comp, typeMap, indent)
    );
    if (comps.length === 2) {
      return `vector.create(${comps[0]}, ${comps[1]})`;
    }
    if (comps.length === 3) {
      return `vector.create(${comps[0]}, ${comps[1]}, ${comps[2]})`;
    }
    throw new Error("[Debi] vector must have 2 or 3 components");
  }

  if (typeNode.kind === "array") {
    // Caller should use readArrayBlock for multi-line
    return null;
  }

  throw new Error(`[Debi] Unsupported read type ${typeNode.kind}`);
}

function readArrayBlock(readerVar, destVar, typeNode, typeMap, indent) {
  const elRead = readExpr(readerVar, typeNode.element, typeMap, indent + "\t");
  if (typeNode.element.kind === "array") {
    throw new Error("[Debi] nested arrays not supported in v1");
  }
  return [
    `${indent}const ${destVar} = {}`,
    `${indent}do`,
    `${indent}\tconst __n = ${readerVar}:readu16()`,
    `${indent}\tfor __i = 1, __n do`,
    `${indent}\t\t${destVar}[__i] = ${elRead}`,
    `${indent}\tend`,
    `${indent}end`,
  ].join("\n");
}

function validateRead(valueExpr, typeNode, typeMap) {
  // Lightweight runtime checks for primitives with implicit ranges
  if (typeNode.kind !== "named") return null;
  const name = typeNode.name;
  if (name === "u8") {
    return `assert(${valueExpr} >= 0 and ${valueExpr} <= 255, "[Debi] u8 out of range")`;
  }
  if (name === "u16") {
    return `assert(${valueExpr} >= 0 and ${valueExpr} <= 65535, "[Debi] u16 out of range")`;
  }
  if (name === "string") {
    return `assert(type(${valueExpr}) == "string", "[Debi] expected string")`;
  }
  return null;
}

module.exports = {
  PRIMITIVES,
  BUILTINS,
  isPrimitive,
  isBuiltin,
  parseType,
  luauType,
  writeExpr,
  readExpr,
  readArrayBlock,
  validateRead,
};

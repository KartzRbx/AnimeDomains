const fs = require("fs");
const path = require("path");

const BASE_PATH = path.join(__dirname, "../src");

function toPosix(p) {
  return p.split(path.sep).join("/");
}

const BLACKLISTED_DIRS = [toPosix(path.join(BASE_PATH, "tools"))];

function toPascalCase(str) {
  if (!str) return str;
  return str.charAt(0).toUpperCase() + str.slice(1);
}

// Top-level folders under src/ and where each goes by default.
// "Shared"   -> ReplicatedStorage/Shareds/<Folder>
// "Server"   -> ServerScriptService/Source/<Folder>
// "Client"   -> StarterPlayer/StarterPlayerScripts/<Folder>
// "Boot"     -> special handling (nested Boot/<Group>/<Name>)
// "Services" -> special handling (see rule below)
const TOP_LEVEL_RULES = {
  Boot: "Boot",
  Services: "Services",
  Modules: "Modules",
  Workers: "Shared",
  Classes: "Shared",
  Networker: "Shared",
  Constants: "Shared",
  Utils: "Shared",
  Handlers: "Server",
  Controllers: "Client",
  Configurations: "Server",
};

// Strip Server/Client suffix from the file name (case-insensitive),
// keeping PascalCase. E.g. "EnemyServiceServer" -> "EnemyService"
function stripSuffix(filename, suffix) {
  const lower = filename.toLowerCase();
  const lowerSuffix = suffix.toLowerCase();
  if (lower.endsWith(lowerSuffix)) {
    return filename.slice(0, filename.length - suffix.length);
  }
  return filename;
}

function getFileKind(filename) {
  // filename without extension, e.g. "EnemyServiceServer", "Server", "Client"
  const lower = filename.toLowerCase();
  if (lower.endsWith("server")) return "server";
  if (lower.endsWith("client")) return "client";
  return "shared";
}

function getFileKindFromFilename(filename) {
  const lower = filename.toLowerCase();
  if (lower.endsWith(".server.luau")) return "server";
  if (lower.endsWith(".client.luau")) return "client";
  return getFileKind(
    filename
      .replace(/\.server\.luau$/i, "")
      .replace(/\.client\.luau$/i, "")
      .replace(/\.luau$/i, "")
  );
}

const tree = {
  name: "genrojotree",
  tree: {
    $className: "DataModel",

    ReplicatedFirst: {
      $ignoreUnknownInstances: true,
    },

    ReplicatedStorage: {
      $ignoreUnknownInstances: true,
      Shareds: {
        $className: "Folder",
        Services: { $className: "Folder" },
        Constants: { $className: "Folder", $path: "src/Constants" },
        Classes: { $className: "Folder", $path: "src/Classes" },
        Modules: { $className: "Folder", $path: "src/Modules" },
        // Debi Networker — typed entries: NetClient (client) / NetServer (server)
        Networker: {
          $className: "Folder",
          NetClient: { $path: "src/Networker/NetClient.luau" },
          NetServer: { $path: "src/Networker/NetServer.luau" },
          Game: {
            $className: "Folder",
            Client: { $path: "src/Networker/Game/Client.luau" },
            Server: { $path: "src/Networker/Game/Server.luau" },
          },
          Secondary: {
            $className: "Folder",
            Client: { $path: "src/Networker/Secondary/Client.luau" },
            Server: { $path: "src/Networker/Secondary/Server.luau" },
          },
          Validations: {
            $className: "Folder",
            Client: { $path: "src/Networker/Validations/Client.luau" },
            Server: { $path: "src/Networker/Validations/Server.luau" },
          },
        },
        Workers: { $className: "Folder", $path: "src/Workers" },
        Utils: { $className: "Folder", $path: "src/Utils" },
      },
      Packages: { $className: "Folder", $path: "Packages" },
    },

    ServerScriptService: {
      Source: {
        $className: "Folder",
        Boot: { $className: "Folder" },
        Handlers: { $className: "Folder" },
        Configurations: { $className: "Folder" },
        Services: { $className: "Folder" },
      },
    },

    StarterPlayer: {
      StarterPlayerScripts: {
        Boot: { $className: "Folder" },
        Controllers: { $className: "Folder" },
      },
    },
  },
};

const sharedRoot = tree.tree.ReplicatedStorage.Shareds;
const serverRoot = tree.tree.ServerScriptService.Source;
const clientRoot = tree.tree.StarterPlayer.StarterPlayerScripts;

function ensureFolder(root, parts) {
  let current = root;
  for (const part of parts) {
    if (!current[part]) current[part] = { $className: "Folder" };
    current = current[part];
  }
  return current;
}

// Recursively walk all files
function walk(dir, callback) {
  if (BLACKLISTED_DIRS.includes(toPosix(dir))) return;

  fs.readdirSync(dir, { withFileTypes: true }).forEach((entry) => {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (BLACKLISTED_DIRS.includes(toPosix(full))) return;
      walk(full, callback);
    } else if (entry.isFile() && entry.name.endsWith(".luau")) {
      callback(full);
    }
  });
}

walk(BASE_PATH, (filepath) => {
  const relativePath = toPosix(path.relative(BASE_PATH, filepath));
  const parts = relativePath.split("/"); // ex: ["Services", "EnemyService", "EnemyServiceServer.server.luau"]
  const topLevel = parts[0];
  const rule = TOP_LEVEL_RULES[topLevel];
  const file = toPosix(path.join("src", ...parts));

  if (topLevel === "Server") {
    return;
  }

  // File name without extensions (.server.luau / .client.luau / .luau)
  const fileKind = getFileKindFromFilename(parts[parts.length - 1]);
  const rawName = parts[parts.length - 1]
    .replace(/\.server\.luau$/i, "")
    .replace(/\.client\.luau$/i, "")
    .replace(/\.luau$/i, "");

  if (!rule) {
    // Unknown folder under src/: put in ReplicatedStorage/Shareds preserving path
    const folderParts = parts.slice(0, -1).map(toPascalCase);
    const parent = ensureFolder(sharedRoot, folderParts);
    parent[toPascalCase(rawName)] = { $path: file };
    return;
  }

  if (rule === "Boot") {
    // Boot/<Group>/<Name>.server.luau → SSS.Source.Boot/<Group>/<Name>
    // Boot/<Group>/<Name>.client.luau → StarterPlayerScripts.Boot/<Group>/<Name>
    const folderParts = parts.slice(1, -1).map(toPascalCase);
    const kind = fileKind;
    if (kind === "server") {
      const parent = ensureFolder(serverRoot.Boot, folderParts);
      parent[toPascalCase(rawName)] = { $path: file };
    } else if (kind === "client") {
      const parent = ensureFolder(clientRoot.Boot, folderParts);
      parent[toPascalCase(rawName)] = { $path: file };
    } else {
      const parent = ensureFolder(sharedRoot, ["Boot", ...folderParts]);
      parent[toPascalCase(rawName)] = { $path: file };
    }
    return;
  }

  if (rule === "Server") {
    // Handlers/Configurations -> ServerScriptService/Source/<Folder>/...
    const folderParts = parts.slice(1, -1).map(toPascalCase);
    const parent = ensureFolder(serverRoot[topLevel], folderParts);
    parent[toPascalCase(rawName)] = { $path: file };
    return;
  }

  if (rule === "Client") {
    // Controllers -> StarterPlayerScripts/Controllers/...
    const folderParts = parts.slice(1, -1).map(toPascalCase);
    const parent = ensureFolder(clientRoot[topLevel], folderParts);
    parent[toPascalCase(rawName)] = { $path: file };
    return;
  }

  if (rule === "Shared") {
    // Constants/Classes/Modules/Networker/Workers/Utils already have $path on the folder
    // in the tree init. Mapping file-by-file here would duplicate in Rojo
    // (whole folder + each ModuleScript again).
    return;
  }

  if (rule === "Services") {
    // Under Services, every file is plain .luau (ModuleScript) — never .server.luau/.client.luau.
    // Boot decides server vs client via manual require().
    // Detection here is only about WHERE the file lives in the DataModel:
    //
    // Services/EnemyService/EnemyServiceServer.luau -> ServerScriptService/Source/Services/EnemyService
    // Services/EnemyService/EnemyServiceClient.luau -> ReplicatedStorage/Shareds/Services/EnemyService
    // Services/EnemyService/EnemyServiceModule.luau -> ReplicatedStorage/Shareds/Services/EnemyService
    const serviceFolderParts = parts.slice(1, -1).map(toPascalCase); // e.g. ["EnemyService"]
    const kind = getFileKind(rawName);

    if (kind === "server") {
      const serviceName = toPascalCase(stripSuffix(rawName, "Server"));
      serverRoot.Services[serviceName] = { $path: file };
    } else {
      // client or shared: stays in ReplicatedStorage
      const parent = ensureFolder(sharedRoot.Services, serviceFolderParts);
      parent[toPascalCase(rawName)] = { $path: file };
    }
    return;
  }
});

fs.writeFileSync(
  path.join(__dirname, "../default.project.json"),
  JSON.stringify(tree, null, 2)
);
console.log("✅ default.project.json generated.");

"use strict";

const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");

const COPY_ANCHOR =
  "await b.default.cp(n.cwd,e,{recursive:!0}),process.platform!==`win32`&&";
const PATCH_MARKER = "codex-linux-executor-plugin-tree-owner-write-v1";
const HELPER_SOURCE = `/* ${PATCH_MARKER} */
async function codexLinuxMakeExecutorPluginTreeWritable(fs,root){
  let stat;
  try{stat=await fs.lstat(root)}catch(error){if(error?.code==="ENOENT")return;throw error}
  if(stat.isSymbolicLink()||(!stat.isDirectory()&&!stat.isFile()))return;
  await fs.chmod(root,(stat.mode&0o777)|0o200);
  if(!stat.isDirectory())return;
  for(const entry of await fs.readdir(root)){
    await codexLinuxMakeExecutorPluginTreeWritable(fs,root+"/"+entry);
  }
}
`;

function patchSource(source) {
  if (source.includes(PATCH_MARKER)) {
    throw new Error(`executor-plugin permission patch marker already present`);
  }

  const matches = source.split(COPY_ANCHOR).length - 1;
  if (matches !== 1) {
    throw new Error(`executor-plugin copy anchor matched ${matches} times`);
  }

  const replacement =
    "await b.default.cp(n.cwd,e,{recursive:!0})," +
    "await codexLinuxMakeExecutorPluginTreeWritable(b.default,e)," +
    "process.platform!==`win32`&&";
  const patched = source.replace(COPY_ANCHOR, replacement);
  return `${HELPER_SOURCE}${patched}`;
}

function patchMainBundle(buildDir) {
  const candidates = fs.readdirSync(buildDir)
    .filter((name) => /^main-.*\.js$/.test(name))
    .map((name) => path.join(buildDir, name));
  const matches = [];
  for (const file of candidates) {
    const source = fs.readFileSync(file, "utf8");
    const count = source.split(COPY_ANCHOR).length - 1;
    if (count > 0) matches.push({ file, source, count });
  }
  const totalMatches = matches.reduce((sum, match) => sum + match.count, 0);
  if (totalMatches !== 1 || matches.length !== 1) {
    throw new Error(`executor-plugin copy anchor matched ${totalMatches} times across ${candidates.length} main bundles`);
  }
  fs.writeFileSync(matches[0].file, patchSource(matches[0].source));
  console.log(`Patched executor-plugin copy permissions in ${path.basename(matches[0].file)}`);
}

async function makeTreeWritable(fileSystem, root) {
  let stat;
  try {
    stat = await fileSystem.lstat(root);
  } catch (error) {
    if (error?.code === "ENOENT") return;
    throw error;
  }
  if (stat.isSymbolicLink() || (!stat.isDirectory() && !stat.isFile())) return;
  await fileSystem.chmod(root, (stat.mode & 0o777) | 0o200);
  if (!stat.isDirectory()) return;
  for (const entry of await fileSystem.readdir(root)) {
    await makeTreeWritable(fileSystem, path.join(root, entry));
  }
}

function updatePatchReport(reportPath, asarPath) {
  const report = JSON.parse(fs.readFileSync(reportPath, "utf8"));
  report.outputAppAsar = {
    ...report.outputAppAsar,
    sha256: crypto.createHash("sha256").update(fs.readFileSync(asarPath)).digest("hex"),
  };
  fs.writeFileSync(reportPath, `${JSON.stringify(report, null, 2)}\n`);
}

if (require.main === module) {
  const args = process.argv.slice(2);
  if (args[0] === "--update-report" && args.length === 3) {
    updatePatchReport(args[1], args[2]);
  } else if (args.length === 1) {
    patchMainBundle(args[0]);
  } else {
    console.error("Usage: codex-desktop-executor-permissions.cjs <extracted-app-asar-build-dir> | --update-report <patch-report> <app.asar>");
    process.exitCode = 2;
  }
}

module.exports = { COPY_ANCHOR, PATCH_MARKER, makeTreeWritable, patchSource, updatePatchReport };

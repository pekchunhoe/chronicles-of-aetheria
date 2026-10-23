// Export integrity checks only. No npm packages, framework, or game reimplementation.
import { readFile, readdir, stat, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const args = process.argv.slice(2);
const value = flag => args.includes(flag) ? args[args.indexOf(flag) + 1] : null;
const directory = path.resolve(value('--directory') || path.join(root, 'web'));
const manifestName = 'build-manifest.json';
const sha256 = buffer => createHash('sha256').update(buffer).digest('hex');
const requireTrue = (condition, message) => { if (!condition) throw new Error(message); };

async function filesUnder(folder) {
  const result = [];
  for (const entry of await readdir(folder, { withFileTypes: true })) {
    if (entry.name.startsWith('.') || entry.name.endsWith('.import')) continue;
    const filename = path.join(folder, entry.name);
    if (entry.isDirectory()) result.push(...await filesUnder(filename));
    else result.push(filename);
  }
  return result.sort();
}

async function sourceHash() {
  const files = ['project.godot', 'export_presets.cfg'].map(file => path.join(root, file));
  for (const folder of ['scripts', 'scenes', 'content', 'assets', 'web_shell']) {
    try { files.push(...await filesUnder(path.join(root, folder))); }
    catch (error) { if (error.code !== 'ENOENT') throw error; }
  }
  const hash = createHash('sha256');
  for (const filename of files.sort()) {
    let bytes = await readFile(filename);
    if (/\.(gd|uid|tscn|tres|json|html|godot|cfg|svg|txt)$/i.test(filename)) {
      bytes = Buffer.from(bytes.toString('utf8').replace(/\r\n/g, '\n'));
    }
    hash.update(path.relative(root, filename).replaceAll('\\', '/') + '\0');
    hash.update(bytes);
    hash.update('\0');
  }
  return hash.digest('hex');
}

async function main() {
  const names = (await readdir(directory)).filter(name => !name.startsWith('.') && name !== manifestName).sort();
  for (const name of ['index.html', 'index.js', 'index.wasm', 'index.pck']) {
    requireTrue(names.includes(name), `Incomplete Web export: missing ${name}`);
  }
  const files = {};
  let total = 0;
  for (const name of names) {
    requireTrue(/^[a-zA-Z0-9_.-]+$/.test(name), `Unexpected export path: ${name}`);
    const info = await stat(path.join(directory, name));
    requireTrue(info.isFile(), `Unexpected export directory: ${name}`);
    requireTrue(info.size > 0 && info.size < 90 * 1024 * 1024, `Empty or oversized export file: ${name}`);
    const bytes = await readFile(path.join(directory, name));
    files[name] = { bytes: bytes.length, sha256: sha256(bytes) };
    total += bytes.length;
  }
  requireTrue(total < 180 * 1024 * 1024, 'Web export exceeds the 180 MiB project guardrail. Review hosting limits.');
  const wasm = await readFile(path.join(directory, 'index.wasm'));
  requireTrue(wasm.subarray(0, 4).equals(Buffer.from([0, 97, 115, 109])), 'Invalid WebAssembly magic');
  requireTrue(wasm.length > 1024 * 1024 && WebAssembly.validate(wasm), 'Incomplete or unsupported WebAssembly module');
  const pack = await readFile(path.join(directory, 'index.pck'));
  requireTrue(pack.subarray(0, 4).toString() === 'GDPC', 'Invalid Godot resource-pack magic');
  requireTrue(pack.length > 4096, 'Resource pack is unexpectedly small');
  const html = await readFile(path.join(directory, 'index.html'), 'utf8');
  requireTrue(!/\$GODOT_[A-Z_]+/.test(html), 'Unresolved Godot HTML shell placeholders');
  requireTrue(html.includes('new Engine(config)') && html.includes('engine.startGame('), 'HTML does not initialize the actual Godot engine');
  for (const [, dependency] of html.matchAll(/\bsrc="([^"#]+)"/g)) {
    requireTrue(!/^https?:/i.test(dependency) && files[dependency], `Missing or external shell dependency: ${dependency}`);
  }
  const configMatch = html.match(/const config = (\{[^\n]+\});/);
  requireTrue(configMatch, 'Generated Godot configuration is missing');
  const config = JSON.parse(configMatch[1]);
  requireTrue(config.executable === 'index', 'Unexpected Godot executable basename');
  for (const [name, size] of Object.entries(config.fileSizes || {})) {
    requireTrue(files[name]?.bytes === size, `Godot configuration size mismatch for ${name}`);
  }
  const presets = await readFile(path.join(root, 'export_presets.cfg'), 'utf8');
  requireTrue(presets.includes('variant/thread_support=false'), 'Web must use the single-threaded template');
  const manifest = { schemaVersion: 1, engine: '4.7.2-stable', renderer: 'gl_compatibility', threads: false,
    contentSourceSha256: await sourceHash(), totalBytes: total, files };
  if (args.includes('--write-manifest')) {
    await writeFile(path.join(directory, manifestName), JSON.stringify(manifest, null, 2) + '\n');
  } else {
    const recorded = JSON.parse(await readFile(path.join(directory, manifestName), 'utf8'));
    requireTrue(JSON.stringify(recorded) === JSON.stringify(manifest), 'Web export is stale or modified. Run tools/export_web.ps1.');
  }
  if (value('--url')) {
    const base = new URL(value('--url'));
    const checks = { ...files, [manifestName]: { sha256: sha256(await readFile(path.join(directory, manifestName))) } };
    for (const [name, expected] of Object.entries(checks)) {
      const requestUrl = new URL(name === 'index.html' ? './' : name, base);
      const response = await fetch(requestUrl, { signal: AbortSignal.timeout(60000), cache: 'no-store' });
      requireTrue(response.status === 200, `HTTP ${response.status}: ${requestUrl}`);
      const type = response.headers.get('content-type') || '';
      if (name.endsWith('.wasm')) requireTrue(type.includes('application/wasm'), 'WASM MIME type is incorrect');
      if (name.endsWith('.js')) requireTrue(/(?:application|text)\/javascript/.test(type), 'JavaScript MIME type is incorrect');
      if (name.endsWith('.pck')) requireTrue(type.includes('application/octet-stream'), 'PCK MIME type is incorrect');
      requireTrue(sha256(Buffer.from(await response.arrayBuffer())) === expected.sha256, `Hosted hash mismatch: ${name}`);
      console.log(`PASS: HTTP 200, content hash and type: ${name}`);
    }
    const missing = await fetch(new URL('__aetheria_missing_asset__.wasm', base), { signal: AbortSignal.timeout(15000) });
    requireTrue(missing.status === 404, 'Missing assets must return 404, not an HTML fallback');
  }
  console.log(`WEB EXPORT PASS: ${names.length} files, ${(total / 1048576).toFixed(2)} MiB; WASM, PCK, dependencies and source hashes verified.`);
}
main().catch(error => { console.error('WEB EXPORT FAIL:', error.message); process.exitCode = 1; });

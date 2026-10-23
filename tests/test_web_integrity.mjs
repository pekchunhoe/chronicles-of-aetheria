import { cp, mkdtemp, readFile, realpath, rm, truncate, unlink, writeFile } from 'node:fs/promises';
import { execFileSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const sandbox = await mkdtemp(path.join(root, '.tools', 'web-validator-fixtures-'));
const verifier = path.join(root, 'tools', 'verify_web_export.mjs');
let failures = 0;
try {
  const cases = [
    ['complete build', null, true],
    ['missing JavaScript', dir => unlink(path.join(dir, 'index.js')), false],
    ['invalid WebAssembly', dir => writeFile(path.join(dir, 'index.wasm'), 'invalid'), false],
    ['modified pack', async dir => {
      const pack = await readFile(path.join(dir, 'index.pck')); pack[pack.length - 1] ^= 1;
      await writeFile(path.join(dir, 'index.pck'), pack);
    }, false],
    ['oversized asset', dir => truncate(path.join(dir, 'index.js'), 90 * 1024 * 1024), false],
    ['stale source manifest', async dir => {
      const filename = path.join(dir, 'build-manifest.json');
      const manifest = JSON.parse(await readFile(filename, 'utf8'));
      manifest.contentSourceSha256 = '0'.repeat(64);
      await writeFile(filename, JSON.stringify(manifest));
    }, false]
  ];
  for (const [name, mutate, expected] of cases) {
    const target = path.join(sandbox, name.replaceAll(' ', '-'));
    await cp(path.join(root, 'web'), target, { recursive: true });
    if (mutate) await mutate(target);
    let accepted = true;
    try { execFileSync(process.execPath, [verifier, '--directory', target], { stdio: 'pipe' }); }
    catch { accepted = false; }
    if (accepted !== expected) { console.error('FAIL:', name); failures++; }
    else console.log('PASS:', name, expected ? 'accepted' : 'rejected');
  }
  console.log(`WEB VALIDATOR TESTS: ${cases.length - failures} passed, ${failures} failed`);
} finally {
  const resolved = await realpath(sandbox);
  const toolsRoot = await realpath(path.join(root, '.tools'));
  if (path.dirname(resolved) !== toolsRoot || !path.basename(resolved).startsWith('web-validator-fixtures-')) {
    throw new Error('Refused cleanup outside the verified test workspace');
  }
  await rm(resolved, { recursive: true, force: true });
}
process.exitCode = failures ? 1 : 0;

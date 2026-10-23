# Godot Web / Vercel deployment report

Date: **24 October 2026, Asia/Kuala_Lumpur**.

## Current result

The complete official Godot Web release is built, validated over local HTTP, and accepted by a local Vercel production build. The original native game and its physics calculations are preserved. **Interactive browser verification is pending because the browser-control tool reports no connected browsers. Production has not been changed or claimed playable.**

The existing production URL was verified to return **HTTP 404 / `X-Vercel-Error: NOT_FOUND`** before these changes. The new files and configuration are ready for the existing Git-based deployment once browser verification is available. No replacement Vercel project or domain was created.

## Verified root cause of the 404

Authenticated Vercel inspection established:

- Existing project: `pek-explains-physics/chronicles-of-aetheria`, ID `prj_KZk9QZxn8GUUW0LbfpeNYGvKV9gz`.
- Existing production deployment: `dpl_5W3FfKrnrYMbXo5ijy1jACdS3m5U`, state **READY**, correctly aliased to `chronicles-of-aetheria-five.vercel.app`.
- Git link: GitHub `pekchunhoe/chronicles-of-aetheria`, production branch `main`, deployment source SHA `220c6dbeb1d1e922741ed2b863ad148bead86604`.
- Existing project settings: framework/root/build/install/output directory all unset/default.
- Build logs cloned the correct repository/branch/commit, completed the static build in 65 ms and reported no files prepared for cache upload. There was no Godot export step.
- That repository contained Godot source and Windows/Android presets, but no Web preset, browser export directory, `index.html`, JavaScript loader, WASM, PCK for Web, or `vercel.json`.
- A direct HTTP request returned 404. Evidence: `artifacts/vercel-before-headers.txt` and `artifacts/vercel-before.html`.

The deployment served a source repository without a browser entry point or a Web build/output configuration. The inspected Git branch/project/domain relationship was correct; no DNS/domain reassignment or project recreation was needed. The deployment-file-tree API returned 404 and did not supply an additional file inventory; this limitation was not treated as evidence that the project itself was missing.

## Engine and Web settings

Engine executable version: **`4.7.2.stable.official.ed1daf0bf`**, standard GDScript build. The renderer remains **GL Compatibility**, with a fixed 640 × 360 world and independently scaled UI.

New preset: **Web**, export path **`web/index.html`**, official matching **single-threaded release** template, extensions disabled, adaptive canvas, desktop/mobile texture variants, no PWA/service worker. Required ETC2/ASTC texture imports are enabled in `project.godot`; without that setting, Godot's Web exporter rejects the mobile texture option. Both matching Web template ZIPs were installed locally from the official archive with inner/outer CRC checks. Templates and engine binaries are ignored by Git.

The HTML shell initializes `new Engine(config)` and `engine.startGame()` from Godot's generated JavaScript. It adds progress/error UI, a supported-browser diagnostic, a user-gesture fullscreen button, safe-area CSS and a touch portrait/landscape prompt. It contains no replacement game implementation.

Browser touch devices reuse the existing stick/buttons, automatically enabled using touch capabilities. A smaller 960 × 540 UI reference improves touch sizing, while the world viewport stays 640 × 360. The pause panel fits the available landscape height. Browser visibility/window blur requests pause and local saving. The Web menu saves without terminating the canvas; Windows retains Save and quit. `SaveRepository`, save schema, arcade movement and numerical equations are unchanged.

## Complete export

| Generated file | Bytes |
| --- | ---: |
| `web/index.html` | 6,012 |
| `web/index.js` | 279,815 |
| `web/index.wasm` | 39,514,754 |
| `web/index.pck` | 57,240 |
| `web/index.audio.worklet.js` | 7,298 |
| `web/index.audio.position.worklet.js` | 2,973 |
| `web/index.png` | 21,443 |

Total generated game assets: **39,889,535 bytes / 38.04 MiB**. `build-manifest.json` records exact hashes, sizes, engine/renderer/thread settings and a normalized hash of game source. `web/.gdignore` keeps generated artifacts out of the Godot import pipeline. The largest file is below GitHub's regular 100 MiB per-file limit; the validator uses a conservative 90 MiB per-file / 180 MiB total project guardrail. All generated support filenames are preserved.

The validator checks WebAssembly validity, Godot PCK magic, HTML initialization, shell dependencies, configured sizes and source/output hashes. No Godot rebuild happens on Vercel: complete prebuilt artifacts are versioned, and source changes without re-exporting cause the integrity check to fail rather than publish a stale game.

## Vercel configuration and identity

`vercel.json` uses supported properties:

- `framework: null` (Other).
- `installCommand: ""` (no dependencies to install).
- `buildCommand: "node tools/verify_web_export.mjs"` (integrity validation only).
- `outputDirectory: "web"`.
- Explicit WASM/PCK MIME headers, `nosniff` and revalidation for fixed asset names.
- No catch-all rewrites, no functions/backend, no SharedArrayBuffer or cross-origin-isolation requirement.

The existing project was linked locally by its verified project/team IDs. `vercel build --prod --yes --scope pek-explains-physics` completed successfully and produced `.vercel/output/static` with the same verified files. This was a **local build, not a deployment**. Generated route configuration applies asset headers and a missing-route 404; it does not redirect asset requests to the game HTML.

Dashboard settings require no change beyond honoring the committed configuration: Root Directory remains blank/repository root, Git link stays the existing repo and production branch stays `main`. Do not create another project or reassign the domain. CLI-generated environment files were ignored and removed after the local build; no credentials or project-local Vercel metadata are part of the commit.

## Actual validation results

| Check | Result / evidence |
| --- | --- |
| Project import/headless boot | PASS; `artifacts/editor-import.log`, `artifacts/headless-boot.log` |
| Existing unit/physics/repository tests | **52 passed, 0 failed**; `artifacts/unit-tests.log` |
| Scene tests including checkpoint/save reload and routed synthetic touch | **28 passed, 0 failed**; `artifacts/scene-tests.log` |
| Graphical native scene tests/captures | **31 passed, 0 failed**; `artifacts/graphical-scene-tests.log` |
| Small-landscape pause and maximum-size touch controls | PASS in Godot scene tests; this is native UI simulation, not mobile-browser emulation |
| Independent Python physics references | PASS: all four fixtures retained |
| Windows debug export and packaged-content/save smoke | PASS; `artifacts/windows-export.log`, `artifacts/windows-export-smoke.log` |
| Exported Windows graphical startup | PASS; `artifacts/windows-export-graphical-smoke.log` |
| Web release export | PASS; `artifacts/web-export.log` |
| WASM/PCK/dependency/hash/source integrity | PASS; `node tools/verify_web_export.mjs` |
| Complete/missing-JS/corrupt-WASM/modified-pack/oversized/stale manifest cases | **6 passed, 0 failed**; `node tests/test_web_integrity.mjs` |
| Local HTTP `/` and all seven game files plus manifest | PASS: HTTP 200, correct types and exact hashes; missing WASM route returned 404 |
| Vercel configuration/local production build | PASS; actual CLI build and `.vercel/output/static` verification |
| Browser engine initialization / WebGL rendering | **NOT RUN: no connected browser** |
| Browser keyboard, traversal, pause/UI, checkpoint and persistence after reload | **NOT RUN**; native equivalents pass, which does not establish browser behavior |
| Browser console/network inspection | **NOT RUN**; HTTP/asset checks do not substitute for it |
| Edge / Firefox / mobile-browser emulation | **NOT RUN**; Edge and Firefox are installed, but no browser is exposed to the browser-control tool |
| Actual Android mobile browser | **NOT RUN** |
| Native Android APK export/device test | **NOT RUN**; SDK/adb/Android templates remain absent |
| Production after this change / Git-triggered deployment / hosted CI | **NOT RUN** pending the browser validation gate |

The unchanged physics fixtures remain approximately 19.9796126402 m projectile range, 3.2058581578 m/s² ramp acceleration, 6.2641839053 m/s ideal fall speed, and 2 A. Existing SI assumptions and numerical tolerances remain in `tests/unit/test_physics.gd`. No scientific file was edited to make Web export work.

Windows graphical tests used the existing NVIDIA GeForce MX250 / OpenGL 3.3 Compatibility environment. The native PNG evidence is under `artifacts/phase0-touch.png`, `phase0-bench.png`, and `phase0-pause.png`. No browser screenshot is claimed. The Android build-tools warning during editor/export enumeration remains attributable to the missing native Android SDK.

## Files modified or added

Modified: `.gitattributes`, `.gitignore`, `.github/workflows/phase0.yml`, `project.godot`, `export_presets.cfg`, `scripts/core/boot.gd`, `tests/integration/run_scene_tests.gd`, `README.md`.

Added: `scripts/platform/web_platform_support.gd` and its `.gd.uid`, `web_shell/index.html`, `web/.gdignore`, the seven complete exported game files and `web/build-manifest.json`, `vercel.json`, `tools/install_web_templates.py`, `tools/export_web.ps1`, `tools/verify_web_export.mjs`, `tools/serve_web.py`, `tests/test_web_integrity.mjs`, and this report.

No unrelated preexisting working-tree edits were present. Windows/Android presets were retained; their exclusions now also omit Web/deployment files. Player, save repository and audited physics sources are unchanged. Downloaded tools, staging directories, native builds, credentials and test logs remain excluded.

## Git and production status

Base commit: **`220c6dbeb1d1e922741ed2b863ad148bead86604`**, `main`, matching `origin/main` before work. Remote: `https://github.com/pekchunhoe/chronicles-of-aetheria.git`.

The focused local commit containing this report uses the requested message **`Add Godot Web export and fix Vercel deployment`**. It is **not pushed**: a safe push/production deployment is gated on the required browser tests. No force-push/history rewrite, deployment deletion or domain change is authorized or needed. Use `git log -1 --format="%H %s"` to identify this commit.

**Production URL:** https://chronicles-of-aetheria-five.vercel.app/ — latest verified production state is the original **HTTP 404**, not a successful game deployment. A local successful Vercel build does not change that status.

## Resume and future updates

1. Keep the local HTTP server at `http://127.0.0.1:8060/` running (`python tools/serve_web.py`). Connect a browser, or perform the required browser checks manually: loading, canvas rendering/resizing, A/D/Space, platform/gap, pause/resume, checkpoint/fall recovery, bench result, save/reload and console/network errors. Test touch landscape/fullscreen and browser visibility/storage separately.
2. Fix any browser-specific failures, then regenerate with `tools/export_web.ps1`. Re-run HTTP/hash checks and any affected native regression checks.
3. Review the focused commit and `web/` completeness; ensure `.env*`, `.vercel/`, `.godot/`, `.tools/` and signing material are excluded. Push the verified focused commit to existing `origin/main` only after the required checks pass.
4. Let the existing GitHub→Vercel integration deploy. Inspect the existing project's deployment and match its Git SHA. Avoid a duplicate CLI production deployment.
5. Run `node tools/verify_web_export.mjs --url https://chronicles-of-aetheria-five.vercel.app/`, confirm HTTP 200 and exact game assets, then open the production game and repeat keyboard/touch/console checks. Record the URL, SHA, deployment ID and actual browser evidence here.

The README contains the full repeatable update workflow and Android prerequisites. Reference documentation: [Godot 4.7 Web export](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_web.html), [custom HTML shell](https://docs.godotengine.org/en/4.7/tutorials/platform/web/customizing_html5_shell.html), [Vercel configuration](https://vercel.com/docs/project-configuration/vercel-json). No React rewrite, replacement engine, paid API, cloud game backend, or native-Android compatibility claim was introduced.

# Chronicles of Aetheria — The Broken Laws / Phase 2

A playable, offline 2D action RPG prototype set in **Mechanical Citadel — Combat Training Sector**, now with original AI-assisted pixel artwork, animated characters and machines, layered architecture, bronze and stone terrain, atmospheric lamps and a coordinated HUD. Use the existing three-cut combo, heavy strike and dodge, activate checkpoints, collect the optional Axiom shard and reach the east exit. Bosses, shops and the full seven-kingdom adventure remain outside this phase.

Windows, Android and Web share one GDScript codebase and separate export presets. The complete browser release is generated into `web/`. See [the Phase 2 visual overhaul report](PHASE_2_VISUAL_OVERHAUL_REPORT.md) for validation, comparison screenshots, performance and limitations. [Phase 1](PHASE_1_IMPLEMENTATION_REPORT.md) and the [Web deployment report](GODOT_WEB_VERCEL_DEPLOYMENT_REPORT.md) are historical records. The user confirmed Phase 1 was accepted and pushed before this work. **Phase 2 remains local and uncommitted; it has not been pushed or deployed.**

**Engine: Godot 4.7.2 stable, standard GDScript edition.** The world renders into a fixed **640 × 360 SubViewport**. UI renders separately at a scalable 1280 × 720 reference size. Compatibility/OpenGL rendering is selected. Original raster masters and exact prompts are preserved locally; the bundled Cinzel heading font is SIL OFL licensed. See [asset provenance](assets/ASSET_PROVENANCE.md). No runtime network dependency is added.

Pause and scroll to **Presentation** to choose reduced, standard or enhanced effects, reduced motion and camera shake. Web/mobile default to reduced effects and zero shake. Settings use the existing schema-1 preferences; existing saves, movement, hitboxes, attack timings, AI and numerical physics are retained. The [pre-change inventory](docs/PHASE_2_VISUAL_INVENTORY.md) records those boundaries.

## Play

Open `project.godot` with Godot 4.7.2, then press **F6** on the boot scene or **F5** to run the project. This workspace also contains the downloaded portable engine and a tested Windows debug build; these generated files are ignored by Git.

```powershell
# From this project directory, using the local portable engine:
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --editor --path .

# Run the project directly:
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --path .

# Or double-click builds/windows/Aetheria.exe.
```

For a fresh checkout, download the [official 4.7.2 standard engine](https://godotengine.org/download/archive/4.7.2-stable/) and use its path with the commands below. `.godot-version` records the pin; the validation scripts reject a different engine version. The game itself needs no network connection.

| Action | Keyboard default | Controller default |
| --- | --- | --- |
| Move | A/D or Left/Right | Left stick / D-pad |
| Jump (hold for height) | Space | A / Cross |
| Light attack / three-cut combo | J | X / Square |
| Heavy attack (Breaker) | K | Y / Triangle |
| Dodge | Shift | B / Circle |
| Save current progress | E | Right shoulder |
| Toggle numerical bench | Q | Left shoulder |
| Pause / resume | Escape | Start |
| Return to active checkpoint | R | Back / Select |

The opening room is safe. Hold Space to cross its short gap and reach the original east checkpoint, then continue east to the first crawler. Climb the three steps, avoid the turret's locked aim line, and reach the relay beyond it. The relay restores health and saves automatically. The next corridor combines both enemy types; its upper passage contains an optional shard and rejoins the main route. Cross the final gap, defeat the last crawler, and enter the mint-coloured EXIT.

Tap J again during late recovery to chain light attacks. K trades startup time for damage and reach. Dodge travels 92 pixels over 0.18 seconds, with 0.12 seconds of early invulnerability, 0.14 seconds of recovery and a 0.72-second cooldown. Walls stop both dodges and sword hits. Enemies telegraph attacks; there is no unavoidable contact damage.

Kael has 100 health. Hits grant 0.7 seconds of immunity; death disables gameplay for 0.9 seconds, then restores full health at the last checkpoint. Nonlethal falls cost 20 health and return immediately. Returning to a checkpoint resets enemies and removes projectiles. Shards, completion, discoveries and control preferences persist. Saving records the checkpoint, not exact position or transient enemy health. The bench remains a numerical preview; **Run sample** validates the existing SI model and records a discovery.

Pause → select an action → press a new key to remap the keyboard. Duplicate keys are rejected. Defaults can be restored from the same menu. Controller mappings are configured in `InputAdapter.install_defaults()`; a controller-remapping UI is deferred.

On Android and touch browsers, touch controls appear automatically. On desktop, enable **Show touch controls on desktop** in the pause menu. The left stick supports simultaneous jumping and attacking with other fingers; right-side buttons offer light, heavy, jump, dodge, save, scan and pause. Size and opacity are configurable and saved. The overlay uses real `InputEventScreenTouch`/`ScreenDrag` events, so ordinary desktop mouse clicks do not simulate a finger. Position customization is deferred.

**Android compatibility has not been certified.** The touch scene has been rendered on Windows and exercised with synthetic finger events. No APK or actual Android device run was produced in this environment.

## Validate

```powershell
# Import, numerical/repository checks, scene integration checks, headless boot:
.\tools\validate.ps1

# Also run the graphical scene checks and capture screenshots:
.\tools\validate.ps1 -Capture

# Use a separately installed matching engine:
.\tools\validate.ps1 -Godot 'C:\path\to\Godot_v4.7.2-stable_win64_console.exe'

# Optional independent Python reference calculation (Python 3):
python .\tools\verify_physics_reference.py
```

The test runners return nonzero for failed assertions. The PowerShell wrapper also rejects engine errors and missing completion summaries, since a script error does not always give Godot a failing exit status. Tests write unique, isolated saves under `artifacts/`, then remove their own files. Logs and screenshot evidence remain in that folder. CI configuration is provided in `.github/workflows/phase0.yml`; no remote CI run has been performed.

Raw engine commands are also available:

```powershell
$engine = '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $engine --headless --path . --editor --import --quit
& $engine --headless --path . --script res://tests/run_unit_tests.gd --quit-after 1200
& $engine --headless --path . --script res://tests/integration/run_scene_tests.gd --quit-after 1200
```

## Numerical contract

`PhysicsModel` is scene-independent GDScript. It accepts dictionaries of finite, named quantities in SI units, returns values with units and assumptions, and rejects unsupported input/model IDs. Gravitational acceleration is fixed at **9.81 m/s²**. Angles use explicitly named degree fields; friction coefficients are dimensionless.

| Model | Inputs and assumptions | Expected result | Fixture absolute tolerance |
| --- | --- | --- | --- |
| `ideal_projectile_v1` | 14 m/s, 45°; level landing, uniform gravity, no drag | 19.9796126402 m | 0.005 m about 19.98 m |
| `sliding_ramp_v1` | 30°, μk = 0.20; already sliding down, constant kinetic friction | 3.2058581578 m/s² down plane | 0.005 m/s² about 3.21 m/s² |
| `ideal_fall_v1` | 2 m drop from rest; negligible losses | 6.2641839053 m/s | 0.005 m/s about 6.26 m/s |
| `ohms_law_v1` | 12 V, 6 Ω; steady DC, ideal source, ohmic equivalent load | 2 A | 1e-12 A |

Additional tests use independently calculated, unrounded references, check energy conservation, reject NaN/infinity/invalid domains, and verify the SI/world conversion. The ramp model does not determine whether static friction prevents release; negative acceleration describes a body already sliding down and slowing.

Puzzle acceptance tolerance is content-specific: `projectile_bench.json` accepts a range within **20.0 ± 0.10 m**. It is separate from numerical test precision. The scanner displays evaluated values and declared assumptions. The bench is a preview, without a world launcher apparatus in Phase 0.

For future quantitative apparatus, **64 world pixels = 1 m**; thus 20 m must span 1280 world pixels. The small graybox pit is arcade traversal. Player speed/gravity/jump settings are deliberately in pixels and are not graded SI measurements.

## Modules and content

| Location | Responsibility |
| --- | --- |
| `scenes/boot/boot.tscn`, `scripts/core/boot.gd` | Composition, high-resolution UI, pause/lifecycle handling |
| `scenes/regions/graybox_room.tscn`, `scripts/core/graybox_room.gd` | Original room extended to a 3328-pixel dungeon; checkpoint/reward/completion coordination |
| `scenes/player/`, `scripts/player/player.gd`, `dodge_controller.gd` | Fixed-step movement, acceleration, variable jump, coyote time, buffer, dodge and action coordination |
| `scripts/combat/`, `content/combat/` | Reusable health, weapon timelines, directional hit queries, tunable attack/enemy resources, effects and original audio |
| `scripts/enemies/`, `scenes/enemies/` | Shared enemy life/LOS/reset, crawler AI, turret AI and swept projectiles |
| `scripts/level/` | Reusable collidable platform and checkpoint/relic/exit marker components |
| `scripts/presentation/`, `assets/` | Cached raster atlases, animation observers, pixel camera, parallax, lighting, UI theme and visual preferences |
| `scripts/platform/`, `scenes/ui/touch_overlay.tscn` | Keyboard/controller/touch adapter, finger ownership and safe-area layout |
| `scripts/core/save_repository.gd` | Versioned offline JSON, temp-file replacement, backup/recovery |
| `scripts/physics_models/physics_model.gd` | Four independent SI models and world conversion |
| `scripts/puzzle_runtime/puzzle_controller.gd` | Declarative puzzle bounds and evaluation signal |
| `scripts/player/gauntlet_scanner.gd` | Unit-tagged model presentation |
| `scripts/curriculum/concept_repository.gd` | Stable concepts and dynamic curriculum mappings |
| `content/concepts/`, `content/puzzles/`, `content/curricula/` | Hand-authored, versioned local JSON examples |
| `tests/`, `tools/`, `.github/workflows/` | Numerical/integration checks, export smoke check and CI definition |

**Semester 1** and **Semester 2** are fixed display identities. `SP015` and `SP025` are replaceable codes in a versioned mapping, not save identities. Topics are dynamic arrays, including an empty Semester 2 example. `foundation_example_v1` is illustrative and explicitly awaits an authoritative syllabus audit; it does not claim current curriculum alignment.

Saves retain `save_schema_version: 1`; new snapshots use `content_version: phase1.0`. Phase 0 saves load unchanged, including `room_start` and `east_checkpoint`. The new relay is `citadel_checkpoint`; optional reward and completion use existing `collected_crystals` and `unlocks` arrays. Old custom bindings take priority over new action defaults, with a free fallback key assigned to a conflicting default. Normal saves use Godot's `user://save_v1.json`; the last valid previous save is `.bak`. A same-directory `.tmp` file is flushed and renamed for replacement. Corrupt data can recover from backup; unsupported newer schemas are preserved and cannot be overwritten. Explicit migration is still required if schema 2 is ever introduced. Atomic rename does not guarantee protection from every OS/filesystem power failure.

Background/focus loss pauses the scene and saves locally. Resume remains paused until the player chooses to continue. Native Android lifecycle and storage behavior still need device testing.

## Exports and prerequisites

Install **4.7.2 stable export templates matching the engine** through Editor → Manage Export Templates. Presets contain no signing keys, credentials or absolute machine paths. JSON is explicitly included; tests/docs/tools/artifacts are excluded.

```powershell
# Windows x86_64 debug build and isolated packaged-content smoke test:
.\tools\export_windows.ps1

# Also check the exported executable's graphical startup:
.\tools\export_windows.ps1 -Graphical
```

The local portable editor uses `_sc_` self-contained mode. Its matching templates are under `.tools/godot-4.7.2/editor_data/export_templates/4.7.2.stable/`. Windows and single-threaded Web templates are provisioned locally; Android templates are still absent. The existing `builds/windows/Aetheria.exe` is a local, unsigned debug export. Windows release export/signing/distribution have not been validated.

For Android, the [Godot 4.7 Android export guide](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html) specifies OpenJDK 17 (recommended), platform-tools ≥35.0.0, build-tools 35.0.1, Android platform 35, current command-line tools, CMake 3.10.2.4988404 and NDK 28.1.13356709. Configure Java SDK Path and Android SDK Path in the editor. This machine has Java 25, no detected Android SDK/adb and no installed Android templates. Java 25 has not been validated for this project.

The Android preset targets a landscape, arm64 APK, with Internet/storage permissions disabled. For future installation tests, configure an existing local debug signing identity outside version control. No keystore was created. After prerequisites are installed, export the Android preset, install the debug APK on a selected device, and complete `docs/PHASE_1_HANDOFF.md`'s device checklist. APK export was intentionally not attempted without those prerequisites.

## Continue development

Read [the Phase 2 report](PHASE_2_VISUAL_OVERHAUL_REPORT.md) for current results and remaining validation. Earlier reports and the [original handoff](docs/PHASE_1_HANDOFF.md) remain historical records. Source copies of the starter prompt and GDD are preserved under `docs/`. The existing GitHub repository remains `pekchunhoe/chronicles-of-aetheria`, with production branch `main`. Phase 3 may introduce reviewed SI apparatus and Vector Sight through the existing independent physics interfaces, after real mobile and controller validation. No Phase 3 mechanics were added here.

## Export and run the Web game

The Web preset uses Godot 4.7.2 **Compatibility / WebGL 2**, single-threaded WebAssembly, no GDExtensions, and an adaptive canvas. Mobile texture imports are enabled for the Web preset's ETC2/ASTC option. Windows and Android retain their presets and renderer. Physics equations and save schema are unchanged.

```powershell
# Install matching Web templates in this project's portable editor (once):
python .\tools\install_web_templates.py

# Generate and validate a complete release; no manual asset assembly:
.\tools\export_web.ps1

# Or pass a separately installed matching engine:
.\tools\export_web.ps1 -Godot 'C:\path\to\Godot_v4.7.2-stable_win64_console.exe'

# Serve over HTTP, then open http://127.0.0.1:8060/ in a browser:
python .\tools\serve_web.py

# In another terminal, verify HTTP status, MIME types and hashes:
node .\tools\verify_web_export.mjs --url http://127.0.0.1:8060/

# Verify incomplete/corrupt/oversized/stale builds are rejected:
node .\tests\test_web_integrity.mjs
```

For a separately installed engine, use Editor → Manage Export Templates to install the complete official 4.7.2 package, or pass `--destination` to `install_web_templates.py` with that editor's template directory. The script reads only the official archive's single-threaded Web ZIPs, checks their version and outer/inner ZIP CRCs, and needs Python's standard library. No engine or templates are committed.

The export script builds into a new staging directory, validates it, then updates `web/` and a SHA-256 manifest. An export failure preserves the previous Web build. The validator checks the HTML shell, accompanying JS/worklets, WebAssembly validity, Godot PCK signature, configured sizes, source hash, file hashes and size limits. It rejects individual files ≥90 MiB and total exports ≥180 MiB as project guardrails; review current GitHub/Vercel limits before increasing these thresholds. The current complete export is about 43.93 MiB, with its largest file below GitHub's 100 MiB regular-file limit. No LFS or npm packages are required.

Keep **every generated file and its original name**: `index.html`, `index.js`, `index.wasm`, `index.pck`, both audio worklet files, the generated splash image, and `build-manifest.json`. The `.gdignore` prevents the export from being imported into the Godot project. Edit `web_shell/index.html`, then re-export; edits to generated `web/index.html` are overwritten next time. Opening the HTML with `file://` is unsupported.

The shell starts the actual Godot game, shows download progress and startup errors, and offers fullscreen from a user gesture where supported. Touch browsers automatically show the existing stick/buttons and use a smaller UI reference for readable controls. Browser safe-area CSS protects against insets; portrait touch screens show a landscape prompt. Page visibility/window blur pauses and saves the game. The Web pause menu's **Save progress** button keeps the game running; native Windows retains **Save and quit**.

Browser saves use Godot `user://` backed by the browser's IndexedDB. They are specific to the browser/profile/origin and separate from native Windows/Android saves. Site storage must be allowed; private browsing, quota restrictions or clearing site data can prevent persistence or remove saves. Allow writes to finish before closing the tab. Test checkpoint/discovery/preferences after a reload on each target browser. Native Android APK verification remains a separate requirement.

## Vercel and future updates

The existing project is **`pek-explains-physics/chronicles-of-aetheria`**, connected to **`pekchunhoe/chronicles-of-aetheria` → `main`**. Its production domain is [chronicles-of-aetheria-five.vercel.app](https://chronicles-of-aetheria-five.vercel.app/). Preserve this project and domain.

`vercel.json` in the repository root selects **Other** (`framework: null`), skips dependency installation, runs `node tools/verify_web_export.mjs` as an integrity check, and serves **`web`** as the output directory. Node is used only to verify the committed artifacts, not to implement the game or build a framework application. Vercel does not need Godot installed. The project Root Directory must stay the repository root (dashboard blank/default), with production branch `main`.

There are no catch-all rewrites: JS/WASM/PCK remain real files, missing assets remain 404, and WASM/PCK have explicit MIME types. Revalidation headers prevent fixed export filenames from retaining stale game data across deployments. Single-threaded Web export avoids a SharedArrayBuffer/COOP/COEP requirement. The existing GitHub integration should create the production deployment after a verified push; do not also launch a duplicate CLI production deployment.

For each gameplay update:

1. Make focused Godot changes. Run `tools/validate.ps1 -Capture` and `tools/export_windows.ps1 -Graphical`.
2. Run `tools/export_web.ps1`, then the validator and local HTTP server above. A source change without a fresh export deliberately fails the Vercel integrity check.
3. Test a real desktop browser: movement/jumps, light combo/heavy/dodge, crawler/turret fights, damage/death/relay respawn, upper-passage shard, exit, pause, bench, save/reload, resize and console/network errors. Test simultaneous touch actions and an actual mobile browser separately; neither certifies the native APK.
4. Review `git status`, `git diff` and staged files. Stage only the requested source/docs/configuration changes and the **complete** `web/` export. Keep `.tools/`, `.godot/`, `.vercel/`, `.env*`, caches, local builds and signing material excluded.
5. **Obtain explicit user authorization before committing, pushing or deploying Phase 2.** After approval, use the existing `origin/main` and its existing Vercel Git deployment.
6. Match its Git SHA to the pushed commit, then run `node tools/verify_web_export.mjs --url https://chronicles-of-aetheria-five.vercel.app/`. Also open the production URL and verify actual gameplay and the console; HTTP/asset checks alone do not establish playability.

The GitHub Actions workflow runs the Godot checks and verifies the committed Web export. It does not publish the game or create another Vercel project.

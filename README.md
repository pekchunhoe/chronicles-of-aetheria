# Chronicles of Aetheria — The Broken Laws / Phase 3

A playable, offline action RPG with the original **Mechanical Citadel — Combat Training Sector** and the new **Axiom Research Chambers**. Discover Vector Sight, operate physical friction, projectile, momentum and energy machinery, unlock Impulse Strike, and complete a combined sword-and-physics trial. Nine offline Codex entries and optional Scholar challenges use the same SI parameters as the apparatus. The approved Phase 2 artwork, animations, parallax, lighting, HUD and accessibility preferences are preserved. Bosses, shops and the seven-kingdom expansion remain outside this phase.

Windows, Android and Web share one GDScript codebase and separate export presets. The complete browser release is generated into `web/`. See [the Phase 3 implementation report](PHASE_3_PHYSICS_GAMEPLAY_REPORT.md) for exact validation, screenshots, performance and limitations. The [Phase 2 report](PHASE_2_VISUAL_OVERHAUL_REPORT.md), [Phase 1 report](PHASE_1_IMPLEMENTATION_REPORT.md) and [Web deployment report](GODOT_WEB_VERCEL_DEPLOYMENT_REPORT.md) are historical records. Phase 2 is committed at `52db0ca`. **Phase 3 remains local and uncommitted. Do not push or deploy it without the user's later authorization.**

**Engine: Godot 4.7.2 stable, standard GDScript edition.** The world renders into a fixed **640 × 360 SubViewport**. UI renders separately at a scalable 1280 × 720 reference size. Compatibility/OpenGL rendering is selected. Original raster masters and exact prompts are preserved locally; the bundled Cinzel heading font is SIL OFL licensed. See [asset provenance](assets/ASSET_PROVENANCE.md). No runtime network dependency is added.

Scientific text uses a bundled DejaVu Sans fallback for Greek letters, operators, SI superscripts and subscripts. It supplements the existing UI font and preserves Cinzel headings. The unmodified font and its full redistribution notices were sourced locally; see [font provenance](assets/fonts/DejaVu-NOTICE.txt). No runtime or build-time font download is required.

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
| Interact / tune nearby machine / save | E | Right shoulder |
| Vector Sight (research) / numerical bench (Citadel) | Q | Left shoulder |
| Impulse Strike (unlocked in Momentum Vault) | F | Left stick click |
| Physics Codex | Tab | Right stick click |
| Pause / resume | Escape | Start |
| Return to active checkpoint | R | Back / Select |

The opening room is safe. Hold Space to cross its short gap and reach the original east checkpoint, then continue east to the first crawler. Climb the three steps, avoid the turret's locked aim line, and reach the relay beyond it. The relay restores health and saves automatically. The next corridor combines both enemy types; its upper passage contains an optional shard and rejoins the main route. Cross the final gap, defeat the last crawler, and enter the mint-coloured EXIT.

Choose **Chambers** in the HUD for Mira's research expedition, or press Interact at the original east exit. At the Lost Laboratory, press E to install the diagnostic module. Walk to a machine and press E to adjust sliders; Q captures its measured state and shows force arrows. Release or fire, then watch the actual cargo/projectile contact its receiver. Failed experiments cost nothing; use Reset in the instrument or R to return to the checkpoint. F is the gauntlet default because E retains interaction and existing remappings. Lighter vault cargo gains more speed from the same strike. Raise the Energy Engine weight to deliver enough incident kinetic energy. The final trial requires a ramp relay, an elevated projectile relay and a defeated security machine. Return through either research portal or the HUD expedition button. The upper Momentum Vault passage hides an optional second Axiom Shard.

Open Tab / **Codex** for discoveries. Enable **Scholar Mode** in any apparatus panel to study its exact frozen settings. Type a rounded numerical answer in the specified unit; working and constructive feedback appear locally. Archive seals are cosmetic, and every story relay is solvable with Scholar Mode disabled. All menus scroll and have a close button; Escape resumes the instrument safely. The 20–35 minute initial-exploration target awaits human playtesting.

Tap J again during late recovery to chain light attacks. K trades startup time for damage and reach. Dodge travels 92 pixels over 0.18 seconds, with 0.12 seconds of early invulnerability, 0.14 seconds of recovery and a 0.72-second cooldown. Walls stop both dodges and sword hits. Enemies telegraph attacks; there is no unavoidable contact damage.

Kael has 100 health. Hits grant 0.7 seconds of immunity; death disables gameplay for 0.9 seconds, then restores full health at the last checkpoint. Nonlethal falls cost 20 health and return immediately. Returning to a checkpoint resets enemies, experiments and hostile projectiles. Saving records the checkpoint, current positive player health, shards, ability unlocks, chamber relays, discoveries, archive seals and preferences. Exact positions, transient enemies and unfinished experiment motion reset on loading; completed gates and bridges remain open. The original numerical bench remains available for legacy saves and regression checks.

Pause → select an action → press a new key or controller button. Duplicate bindings are rejected. Defaults can be restored from the same menu. Legacy saved keys take priority over newly introduced defaults; conflicting new actions receive an unused key. Keyboard and controller button mappings persist separately. Real controller hardware remains unverified.

On Android and touch browsers, controls appear automatically. On desktop, enable **Show touch controls on desktop** in the pause menu. Finger-owned controls support simultaneous movement, jumps and attacks, with dedicated **SIGHT**, **IMPULSE**, **CODEX** and **USE** buttons. Size and opacity are configurable and saved. Standard menus/sliders accept touch through mouse emulation; gameplay buttons retain independent finger ownership. Instruments hide the gameplay overlay while the world is paused. Position customization is deferred.

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

The original `PhysicsModel` retains its four scene-independent numerical contracts. `MechanicsModel` adds static/kinetic friction with signed stopping/reversal, analytic projectile states and unequal-height quadratic roots, vector impulse/momentum, and energy with explicitly modelled thermal transfer. Default gravity is **9.81 m s⁻²**; the launcher permits 8–12 m s⁻² as an experimental field setting. Angles use degrees in controls and radians internally; friction coefficients are dimensionless.

| Model | Inputs and assumptions | Expected result | Fixture absolute tolerance |
| --- | --- | --- | --- |
| `ideal_projectile_v1` | 14 m/s, 45°; level landing, uniform gravity, no drag | 19.9796126402 m | 0.005 m about 19.98 m |
| `sliding_ramp_v1` | 30°, μk = 0.20; already sliding down, constant kinetic friction | 3.2058581578 m/s² down plane | 0.005 m/s² about 3.21 m/s² |
| `ideal_fall_v1` | 2 m drop from rest; negligible losses | 6.2641839053 m/s | 0.005 m/s about 6.26 m/s |
| `ohms_law_v1` | 12 V, 6 Ω; steady DC, ideal source, ohmic equivalent load | 2 A | 1e-12 A |

Additional tests use independent references, check energy and work, signed impulses, static thresholds, upward motion and stopping, unreachable elevations, invalid domains, and SI/world conversion. The legacy `sliding_ramp_v1` is still an already-sliding preview; the new apparatus uses the complete static/kinetic state model. A 10 N s impulse gives Δv = 5 m s⁻¹ at 2 kg and 2 m s⁻¹ at 5 kg. Later guide friction is a separate external impulse.

Puzzle acceptance tolerance is content-specific: `projectile_bench.json` accepts a range within **20.0 ± 0.10 m**. It is separate from numerical test precision. The scanner displays evaluated values and declared assumptions. The bench is a preview, without a world launcher apparatus in Phase 0.

All quantitative apparatus uses **64 world pixels = 1 m**; a 20 m launcher receiver is 1280 world pixels away. `ExperimentState` uses exact motion at the fixed 60 Hz physics clock; swept payload collisions determine contact. Trajectory predictions are cached when inputs change. Player traversal and enemy knockback remain arcade rules in pixels, with no calibrated SI claim. See the Phase 3 report for collision geometry, numerical tolerances and idealizations.

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

Saves retain `save_schema_version: 1`; new snapshots use `content_version: phase3.0`. Phase 0–2 data loads with safe defaults for research. Legacy checkpoint, collectible and discovery IDs remain unchanged. Research uses `research_a` through `research_f` checkpoints and `citadel.research.*` progression IDs; the nine journal IDs start with `mechanics.`. Missing research state means an untouched expedition. Unfinished experiments reset safely, and completed relays reopen the correct colliders. Old custom bindings keep priority. Normal saves use Godot's unchanged `user://save_v1.json`; the last valid previous save is `.bak`. Same-directory temporary replacement, corruption recovery and unsupported-newer-schema protection remain. Atomic rename does not guarantee protection from every OS/filesystem power failure.

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

Read [the Phase 3 report](PHASE_3_PHYSICS_GAMEPLAY_REPORT.md) for current results, numerical assumptions, screenshots and remaining validation. Earlier reports and the [original handoff](docs/PHASE_1_HANDOFF.md) remain historical records. The GitHub repository remains `pekchunhoe/chronicles-of-aetheria`, with branch `main`. Phase 4 should prioritize first-time playtesting, independent physics review, real mobile/controller testing, Android prerequisites and broader encounter/visual polish.

## Export and run the Web game

The Web preset uses Godot 4.7.2 **Compatibility / WebGL 2**, single-threaded WebAssembly, no GDExtensions, and an adaptive canvas. Mobile texture imports are enabled for the Web preset's ETC2/ASTC option. Windows and Android retain their presets and renderer. Physics equations and save schema are unchanged.

The HTML shell owns canvas sizing with export resize policy 0. It fits an exact 16:9 canvas inside the area below the 44 px header and safe-area padding, with letterboxing on wider screens. A resize observer updates the drawing buffer and Godot's input transform. Drawing-buffer scaling stays uniform, with device-pixel ratio capped at 2; the 640 × 360 world retains nearest filtering. The fullscreen button remains available in fullscreen. Landscape touch emulation, resizing, fullscreen entry/exit, symbols and reload persistence have automated browser evidence; physical mobile hardware still needs testing.

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

The export script builds into a new staging directory, validates it, then updates `web/` and a SHA-256 manifest. An export failure preserves the previous Web build. The validator checks the HTML shell, accompanying JS/worklets, WebAssembly validity, Godot PCK signature, configured sizes, source hash, file hashes and size limits. It rejects individual files ≥90 MiB and total exports ≥180 MiB as project guardrails; review current hosting limits before increasing these thresholds. `web/build-manifest.json` records the exact fresh byte counts and hashes. No LFS or npm packages are required.

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
5. **Obtain explicit user authorization before committing, pushing or deploying Phase 3.** After approval, use the existing `origin/main` and its existing Vercel Git deployment.
6. Match its Git SHA to the pushed commit, then run `node tools/verify_web_export.mjs --url https://chronicles-of-aetheria-five.vercel.app/`. Also open the production URL and verify actual gameplay and the console; HTTP/asset checks alone do not establish playability.

The GitHub Actions workflow runs the Godot checks and verifies the committed Web export. It does not publish the game or create another Vercel project.

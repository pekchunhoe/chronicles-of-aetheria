# Phase 0 validation report

Validation date: **23 October 2026, Asia/Kuala_Lumpur**.

## Outcome

The Phase 0 desktop foundation is implemented and verified with **Godot 4.7.2.stable.official.ed1daf0bf**. Editor import, numerical/repository tests, scene tests, graphical rendering, and an actual Windows debug export passed. **Android export and actual device compatibility remain unverified**, with prerequisites listed below. This is a graybox foundation, not the action prototype or vertical slice.

## Initial inspection and safe changes

- `E:\Chronicles of Aetheria` was empty. Neither it nor the supplied-document folder was a Git repository; no `AGENTS.md`, README, existing assets or unrelated work was found in the inspected locations.
- Both supplied Markdown files were read in full. The starter prompt's Phase 0 requirements governed implementation; the GDD's later phases were not expanded into this task.
- Source documents in `E:\Chronicles of Aetheria - Zeliard-inspired Physics Action RPG` were preserved. Exact copies were placed in `docs/`.
- A Git repository was initialized. Its initially sandbox-owned, empty metadata was preserved under `.tools/initial-git-metadata-backup` and recreated under the user's account so normal Git inspection works. There are no staged files, commits or remotes.
- No engine was initially on PATH. The official portable standard Godot 4.7.2 engine was downloaded into ignored `.tools/`, verified by its runtime version, and put into self-contained editor mode. Matching Windows debug/release templates were selectively read from the official 4.7.2 template archive and ZIP CRC-verified. No Android templates were installed.

## Implemented behavior

| Requirement | Implementation / evidence |
| --- | --- |
| World and UI | Fixed 640 × 360 world SubViewport, separate scalable UI, Compatibility renderer, nearest-filtered world texture |
| Traversal | Original graybox room, placeholder player, elevated platform, jumpable gap, bounded horizontal movement and following camera |
| Movement | Keyboard/controller adapter, fixed 60 Hz physics, variable jump, coyote time and jump buffer |
| Checkpoint | Collision-activated east checkpoint, saved stable ID, fall/restart recovery, checkpoint restored on relaunch |
| Pause/settings | Pause freezes the world, keyboard remapping with duplicate protection, reset defaults, touch visibility/size/opacity saved |
| Touch | Authored overlay scene, finger-owned stick/buttons, simultaneous fingers, hidden/focus-loss release, safe-area inset calculation |
| Offline persistence | Schema/content versions, same-directory temporary write + rename, previous-valid backup, corruption recovery, newer-schema overwrite protection |
| SI modules | Independent `PhysicsModel`, `PuzzleController`, `ConceptRepository`, `SaveRepository` and `GauntletScanner` |
| Local content | One projectile puzzle, one stable concept record, illustrative versioned mapping with fixed semester names and replaceable syllabus codes |
| Exports | Windows x86_64 and Android arm64 landscape presets, JSON inclusion, development files excluded, no Internet/storage permissions requested |
| Automation | Version-checking PowerShell validation/export scripts, headless test runners and a GitHub Actions workflow definition |

The model bench is explicitly a numerical preview. Its target is 20.0 ± 0.10 m; it does not claim that the short arcade gap represents that distance. Quantitative apparatus must use 64 world pixels per metre. Arcade movement parameters are in pixels/second and separate from graded SI calculations.

## Files added

All project content is new; no existing application files were replaced.

| Area | Files |
| --- | --- |
| Project | `project.godot`, `export_presets.cfg`, `.godot-version`, `.gitignore`, `.gitattributes` |
| Scenes | `scenes/boot/boot.tscn`, `scenes/regions/graybox_room.tscn`, `scenes/player/player.tscn`, `scenes/ui/touch_overlay.tscn` |
| Composition/world/save | `scripts/core/boot.gd`, `graybox_room.gd`, `save_repository.gd` |
| Player/scanner | `scripts/player/player.gd`, `gauntlet_scanner.gd` |
| Input/platform | `scripts/platform/input_adapter.gd`, `safe_area.gd`, `touch_button.gd`, `touch_stick.gd`, `touch_overlay.gd` |
| Educational modules | `scripts/physics_models/physics_model.gd`, `scripts/puzzle_runtime/puzzle_controller.gd`, `scripts/curriculum/concept_repository.gd` |
| Content | `content/concepts/projectile_range.json`, `content/puzzles/projectile_bench.json`, `content/curricula/foundation_example_v1.json` |
| Tests | `tests/test_checks.gd`, `tests/run_unit_tests.gd`, `tests/unit/test_physics.gd`, `tests/unit/test_repositories.gd`, `tests/integration/run_scene_tests.gd` |
| Tooling/CI | `tools/validate.ps1`, `tools/export_windows.ps1`, `tools/verify_physics_reference.py`, `.github/workflows/phase0.yml` |
| Documentation | `README.md`, this report, `docs/PHASE_1_HANDOFF.md`, both supplied Markdown documents copied under `docs/` |
| Metadata | Godot-generated `.gd.uid` companions for the 18 scripts, `artifacts/.gitkeep`, `artifacts/.gdignore` |

Engine/import caches, downloaded tools/templates, logs/screenshots and executable builds are ignored by Git. `.gdignore` keeps validation screenshots out of the asset import pipeline.

## Commands and actual results

Commands were run from the project directory. The PowerShell scripts detect the local pinned console executable or accept `-Godot` with an explicit path. The final logs contain no `SCRIPT ERROR`, `ERROR` or `FAIL` lines.

| Command / check | Result | Evidence |
| --- | --- | --- |
| Engine `--version` | PASS: `4.7.2.stable.official.ed1daf0bf` | Executed local official standard binary |
| `tools/validate.ps1 -Capture` | PASS, exit 0 | Version pin and all checks below completed |
| Editor `--headless --editor --import --quit` | PASS | `artifacts/editor-import.log` |
| `--headless --script res://tests/run_unit_tests.gd` | **52 passed, 0 failed** | `artifacts/unit-tests.log` |
| `--headless --script res://tests/integration/run_scene_tests.gd` | **26 passed, 0 failed** | `artifacts/scene-tests.log` |
| Main scene `--headless --quit-after 10` | PASS | `artifacts/headless-boot.log` |
| Graphical scene tests with `-- --capture` | **29 passed, 0 failed** | `artifacts/graphical-scene-tests.log`; three PNG captures |
| `python tools/verify_physics_reference.py` | PASS: four independent Python references | Same values as the GDScript results below |
| `tools/export_windows.ps1 -Graphical` | PASS, exit 0 | `artifacts/windows-export.log` |
| Exported executable, isolated debug self-check | PASS: standalone package, JSON data, scene, collision, model solve and local save | `artifacts/windows-export-smoke.log` |
| Exported executable, graphical startup | PASS, exit 0 | `artifacts/windows-export-graphical-smoke.log` |
| Git staging/remote inspection | PASS: nothing staged, no commits or remote | Local `git status`, `git diff --cached --name-only`, `git remote -v` |
| Android APK export | **NOT RUN: prerequisites absent** | No SDK/adb or Android templates detected |
| Actual Android/controller hardware playtest | **NOT RUN** | Synthetic input only; no hardware claim |
| Hosted CI | **NOT RUN** | Workflow provided locally; nothing pushed |

The editor prints `Unable to open Android 'build-tools' directory.` while enumerating the Android preset. This reflects the missing SDK; Windows import/export still completes successfully. It is not a verified Android build.

Validation caught and corrected an unavailable Input API call, test initialization before autoload registration, a mistyped flight-time reference, and synthetic input/numeric comparison assertions. Save parsing was changed to handle intentionally corrupt JSON without engine error output. Export templates do not support the editor's `--script` option, so packaged verification uses an opt-in debug-only `--foundation-smoke` self-check with a new isolated save path; normal play is unchanged.

## Numerical fixtures

All calculations use g = **9.81 m/s²**. Rounded-fixture tolerances below are absolute, in the named output unit. Unrounded values are additionally checked at tighter precision against independent Python references.

| Fixture | Actual | Rounded reference | Tolerance | Assumptions |
| --- | --- | --- | --- | --- |
| Projectile, 14 m/s at 45° | 19.979612640163 m | 19.98 m | 0.005 m | Level landing, uniform gravity, no drag; positive right/up |
| Ramp, 30°, μk = 0.20 | 3.205858157775 m/s² | 3.21 m/s² | 0.005 m/s² | Already sliding down, kinetic friction; positive down plane |
| Ideal fall from 2 m | 6.264183905346 m/s | 6.26 m/s | 0.005 m/s | Initially at rest, negligible losses; potential energy becomes kinetic |
| 12 V across 6 Ω | 2.000000000000 A | 2 A | 1e-12 A | Steady DC, ideal source and ohmic equivalent load |

The flight-time reference is 2.0182456547628265 s. Tests also cover energy conservation, unit metadata, invalid/nonfinite inputs, the ramp sign convention, SI/pixel round trips, declarative acceptance bounds, concept mappings, save recovery/version protection, and asymmetric safe-area arithmetic.

## Visual and input evidence

Graphical checks used Windows OpenGL 3.3 Compatibility on **NVIDIA GeForce MX250**, driver reported as **511.69**. This establishes rendering/startup on that machine, not performance targets.

- `artifacts/phase0-touch.png`: rendered room, placeholder, platform and touch overlay; the starting position is clear of the stick.
- `artifacts/phase0-bench.png`: readable high-resolution numerical values, SI units, target tolerance and assumptions.
- `artifacts/phase0-pause.png`: readable pause/remapping UI with scrolling for additional settings.

All three captures were visually inspected. Scene assertions send synthetic keyboard/controller events through Godot Input, synthetic finger events to the authored controls, and a touch press/release through Godot's viewport dispatch. Injection converts UI coordinates into window pixels, including headless viewport scaling. They verify simultaneous move/jump, independent finger release, physical-key preservation, pause freeze, traversal, fall recovery, checkpoint saves, simulated background pause, and restoration of checkpoint/puzzle/discovery/key preferences in a new scene session. A physical controller and an Android touchscreen were not tested.

## Build produced

- `builds/windows/Aetheria.exe`: **103,231,288 bytes**, Windows x86_64, debug, embedded resource pack, unsigned.
- SHA-256: `D3079681A848AE754E30176476E94260447B8F493FB8F991CDD70CCAD0215C30`.
- The standalone self-check verifies that source tests are absent from the pack and required JSON content is present.
- No APK, release export, signing key, publication or deployment was produced.

## Unverified gates and next work

1. **Android toolchain:** no SDK, adb or Android templates were installed. `ANDROID_HOME`, `ANDROID_SDK_ROOT` and `JAVA_HOME` were unset. Java 25 is present; its compatibility here was not tested. The official Godot 4.7 guide recommends JDK 17 and lists platform-tools ≥35.0.0, build-tools 35.0.1, Android platform 35, current command-line tools, CMake 3.10.2.4988404 and NDK 28.1.13356709. Configure editor paths and an existing local debug signing identity before export.
2. **Actual devices:** verify export/install, simultaneous touch, real safe areas/notches, wider landscape layouts, menu navigation, storage and lifecycle behavior on named hardware. No device soak, frame-rate or heat claim is made.
3. **Input polish:** controller remapping UI and configurable touch positions are deferred. Keyboard remapping and touch size/opacity are implemented. Synthetic controller events do not validate hardware drivers or controller-specific behavior.
4. **Save evolution:** schema 1 and corruption recovery are covered. No previous schema exists; future migrations need explicit implementation and fixtures. Atomic rename does not guarantee every filesystem's power-loss durability.
5. **Content/production:** illustrative curriculum alignment needs authoritative review; finished assets, combat, physical puzzle apparatus, release validation and accessibility/localization polish remain later work.

Follow `docs/PHASE_1_HANDOFF.md` for the next concrete steps. All runtime content remains offline. No backend, credentials, question-bank diagrams, third-party Zeliard content, account system, API integration, signing-key generation or cloud synchronization was added.

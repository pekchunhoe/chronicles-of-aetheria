# Chronicles of Aetheria — Phase 0

A small, offline Godot foundation for an original 2D action adventure. It contains one graybox room, a controllable placeholder, an elevated platform, a jumpable pit, a checkpoint, a camera, pause/settings UI, and an idealized physics model bench. Combat, a dungeon, bosses, shops and the seven kingdoms belong to later phases.

**Engine: Godot 4.7.2 stable, standard GDScript edition.** The world renders into a fixed **640 × 360 SubViewport**. UI renders separately at a scalable 1280 × 720 reference size. Compatibility/OpenGL rendering is selected. There are no third-party art/audio assets or game dependencies.

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
| Save current progress | E | X / Square |
| Toggle numerical bench | Q | Left shoulder |
| Pause / resume | Escape | Start |
| Return to active checkpoint | R | Back / Select |

Jump onto the platform, then cross the pit to reach the east checkpoint. Walking through its flag saves it automatically. Falling returns to the active checkpoint. Saving records the checkpoint, not the player's exact position. The bench opens a numerical preview; use its **Run sample** button to validate the sample and record a local discovery.

Pause → select an action → press a new key to remap the keyboard. Duplicate keys are rejected. Defaults can be restored from the same menu. Controller mappings are configured in `InputAdapter.install_defaults()`; a controller-remapping UI is deferred.

On Android, the touch overlay is enabled automatically. On desktop, enable **Show touch controls on desktop** in the pause menu. The left stick supports simultaneous jumping with another finger; right-side controls offer jump, save, scan and pause. Size and opacity are configurable and saved. The overlay uses real `InputEventScreenTouch`/`ScreenDrag` events, so ordinary desktop mouse clicks do not simulate a finger. Position customization is deferred.

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
| `scenes/regions/graybox_room.tscn`, `scripts/core/graybox_room.gd` | Original graybox geometry, checkpoint, safe respawn |
| `scenes/player/`, `scripts/player/player.gd` | Fixed-step, variable jump, coyote time and jump buffer |
| `scripts/platform/`, `scenes/ui/touch_overlay.tscn` | Keyboard/controller/touch adapter, finger ownership and safe-area layout |
| `scripts/core/save_repository.gd` | Versioned offline JSON, temp-file replacement, backup/recovery |
| `scripts/physics_models/physics_model.gd` | Four independent SI models and world conversion |
| `scripts/puzzle_runtime/puzzle_controller.gd` | Declarative puzzle bounds and evaluation signal |
| `scripts/player/gauntlet_scanner.gd` | Unit-tagged model presentation |
| `scripts/curriculum/concept_repository.gd` | Stable concepts and dynamic curriculum mappings |
| `content/concepts/`, `content/puzzles/`, `content/curricula/` | Hand-authored, versioned local JSON examples |
| `tests/`, `tools/`, `.github/workflows/` | Numerical/integration checks, export smoke check and CI definition |

**Semester 1** and **Semester 2** are fixed display identities. `SP015` and `SP025` are replaceable codes in a versioned mapping, not save identities. Topics are dynamic arrays, including an empty Semester 2 example. `foundation_example_v1` is illustrative and explicitly awaits an authoritative syllabus audit; it does not claim current curriculum alignment.

Saves use separate `save_schema_version: 1` and `content_version: phase0.1`, stable checkpoint/concept/puzzle IDs, discoveries, puzzle state, mode choices and control preferences. Normal saves use Godot's `user://save_v1.json`; the last valid previous save is `.bak`. A same-directory `.tmp` file is flushed and renamed for replacement. Corrupt primary data can recover from backup; an unsupported newer schema is preserved and cannot be overwritten by this version. No older schema exists yet: implement explicit, tested migrations when introducing schema 2. Atomic rename is not a guarantee against every OS/filesystem power-loss failure.

Background/focus loss pauses the scene and saves locally. Resume remains paused until the player chooses to continue. Native Android lifecycle and storage behavior still need device testing.

## Exports and prerequisites

Install **4.7.2 stable export templates matching the engine** through Editor → Manage Export Templates. Presets contain no signing keys, credentials or absolute machine paths. JSON is explicitly included; tests/docs/tools/artifacts are excluded.

```powershell
# Windows x86_64 debug build and isolated packaged-content smoke test:
.\tools\export_windows.ps1

# Also check the exported executable's graphical startup:
.\tools\export_windows.ps1 -Graphical
```

The local portable editor uses `_sc_` self-contained mode. Its matching Windows debug/release template files are under `.tools/godot-4.7.2/editor_data/export_templates/4.7.2.stable/`. Only Windows templates were provisioned here; use the complete official template package on another machine. The existing `builds/windows/Aetheria.exe` is a local, unsigned debug export. Release export/signing/distribution have not been validated.

For Android, the [Godot 4.7 Android export guide](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html) specifies OpenJDK 17 (recommended), platform-tools ≥35.0.0, build-tools 35.0.1, Android platform 35, current command-line tools, CMake 3.10.2.4988404 and NDK 28.1.13356709. Configure Java SDK Path and Android SDK Path in the editor. This machine has Java 25, no detected Android SDK/adb and no installed Android templates. Java 25 has not been validated for this project.

The Android preset targets a landscape, arm64 APK, with Internet/storage permissions disabled. For future installation tests, configure an existing local debug signing identity outside version control. No keystore was created. After prerequisites are installed, export the Android preset, install the debug APK on a selected device, and complete `docs/PHASE_1_HANDOFF.md`'s device checklist. APK export was intentionally not attempted without those prerequisites.

## Continue development

Read [the validation report](PHASE_0_VALIDATION_REPORT.md) for actual results and [the Phase 1 handoff](docs/PHASE_1_HANDOFF.md) for the next work. Source copies of the supplied starter prompt and GDD are preserved under `docs/`; their source files in the adjacent folder were unchanged. The repository has been initialized; nothing has been staged, committed, pushed or published.

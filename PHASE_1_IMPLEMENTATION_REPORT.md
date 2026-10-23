# Phase 1 implementation report

Validated on **24 October 2026 (Asia/Kuala_Lumpur)** with **Godot 4.7.2.stable.official.ed1daf0bf**.

## Outcome and release status

The Phase 1 source and playable Windows debug build are implemented and validated locally. The fresh Godot Web release passes source/asset integrity, local HTTP checks and the existing Vercel build. **Interactive browser gameplay, real controller/mobile hardware and native Android remain unverified.** Those acceptance checks are listed below; HTTP validation alone does not establish browser playability.

No commit, push or production deployment was performed. The existing production page returned HTTP 200 and its public manifest still matched the original main-branch Phase 0 release. Phase 1 is available in this workspace, not on the production domain.

## Inspection and reuse

The starting working tree was clean on `main` at `aec19a2` (`Record verified live Web deployment and manual gameplay checks`), with the expected `pekchunhoe/chronicles-of-aetheria` remote. The README, GDD, Phase 0 validation, Web deployment report, handoff, scene tree, input adapter, saves, player, touch controls, export scripts and tests were inspected before changes. No applicable AGENTS.md was found.

The original **52 unit tests and 28 scene tests executed successfully before implementation**. The installed engine and matching Windows/single-threaded Web templates were present. The historical live-browser verification and Vercel READY status belong to the previous release; no new live gameplay or dashboard deployment status is inferred from them.

Preserved interfaces include `FoundationPlayer`, `reset_to()`, `fell`, the boot/player/graybox scene paths, `set_checkpoint()`, `respawn()`, the input adapter, numerical bench, safe-area controls and schema-1 saves. The initial platform, pit and east checkpoint remain where the existing tests expect them. The single-threaded Compatibility Web renderer, export ownership/staging, Vercel project and domain are preserved.

## Gameplay and architecture

| Module | Responsibility |
| --- | --- |
| `scripts/player/player.gd` | Fixed-step movement and action coordination; acceleration, turning, jump cut, coyote/buffer, hurt/death states |
| `scripts/player/dodge_controller.gd` | Travel duration/distance, early immunity, recovery and cooldown |
| `scripts/combat/health_component.gd` | Shared maximum/current health, healing, immunity, damage/death signals |
| `scripts/combat/combat_controller.gd` | Weapon timelines, combo buffer, locked attack direction, hit queries and per-swing target tracking |
| `scripts/combat/attack_data.gd`, `content/combat/*.tres` | Reusable tunable moves and enemy profiles |
| `scripts/combat/combat_audio.gd`, `impact_burst.gd` | Original synthesized cues, short-lived shape particles and damage numbers |
| `scripts/enemies/enemy_base.gd` | Shared life, line of sight, hurt/death, reset and distant-AI early return |
| Crawler / turret scripts and scenes | Platform-aware patrol/chase/bite; limited-arc aim, locked telegraph and projectiles |
| `scripts/enemies/security_projectile.gd` | Swept circle collision, lifetime and first-impact consumption |
| `scripts/level/` | Reusable solid platforms and checkpoint/relic/exit triggers |
| `scripts/core/graybox_room.gd` | Dungeon composition and persistent progression coordination |
| `scripts/core/boot.gd` | Health/combat HUD, death/completion feedback, pause/settings and persistence |

The player script delegates health, weapon timing and dodge state rather than owning enemy AI or scientific calculations. Attack visuals and collision queries read the same timeline. Solid geometry blocks sword queries; each target is recorded once per swing. Taking damage cancels the current attack. Expired or colliding projectiles are freed even when a player is invulnerable.

### Current tuning

Movement uses 180 px/s run speed, 2000 px/s² acceleration, 2400 deceleration, 2800 reversal acceleration and 1400 air acceleration. Jump speed is 360 px/s with 1000 px/s² arcade gravity, 0.10 s coyote time and 0.12 s buffering. Jump consumption prevents repeated air jumps. All are exported controller parameters, separate from SI solvers.

Dodge covers **92 px over 0.18 s**, with **0.12 s** early immunity, **0.14 s** recovery and a **0.72 s** cooldown from activation. Partial final-step movement bounds its distance; recovery no longer adds uncontrolled coasting. Collision resolution stops it at walls.

| Move | Damage | Startup | Active | Recovery | Reach |
| --- | ---: | ---: | ---: | ---: | ---: |
| Cut I | 14 | 0.07 s | 0.10 s | 0.16 s | 40 px |
| Cut II | 17 | 0.06 s | 0.11 s | 0.18 s | 44 px |
| Cut III | 23 | 0.10 s | 0.13 s | 0.24 s | 48 px |
| Breaker | 34 | 0.25 s | 0.15 s | 0.34 s | 54 px |

Light input during late recovery can queue the next cut. Holding attack does not generate repeated press edges. The combo continuation window is 0.30 s and recovery input buffer is 0.20 s. Heavy attacks have greater knockback and a stronger movement restriction.

Kael has 100 health, 0.7 s post-hit immunity and a 0.9 s death-feedback interval. Death disables movement/combat, then respawns at the latest checkpoint with full health. Nonlethal falls cost 20 health and return immediately, preserving the existing fall-recovery API. Checkpoints heal; checkpoint returns reset the existing enemy instances and clear projectiles. Damage, death and completion have distinct visual/audio feedback.

Crawler states are Idle, Patrol, Alert, Chase, Attack, Hurt and Dead. Forward ground queries prevent patrol/chase from stepping off edges; knockback can intentionally knock a crawler off. Crawlers have 40 health and telegraph their 12-damage bite. Turrets have 52 health, a 270 px detection range, a 70-degree half aiming arc and a 0.65 s locked telegraph. Their 16-damage bolts travel at 210 px/s and expire after 2.7 s. Enemy tuning is centralized in profiles. Dead actors finish feedback, hide and stop their AI; checkpoint reset reuses them.

### Dungeon and progression

The 3328 px sector contains the safe start, original traversal, original east checkpoint, first crawler, three-step ascent, first turret, new relay, combined crawler/turret corridor, optional upper shard passage, final gap, last crawler and clearly marked exit. The upper passage rejoins the main corridor. Every ascent step and both required gaps have executed traversal checks. Exit completion is reachable without a permanent kill gate, so bypassing an enemy cannot softlock progression.

Ground uses blue-gray solids, enemies warm metal colours, telegraphs amber, checkpoints mint/teal, the optional shard violet and the exit mint with an arrow. These are original coherent placeholders, not final art.

### Saves and inputs

`save_schema_version: 1` remains unchanged. New snapshots use `content_version: phase1.0`; old `phase0.1` data loads without migration or lost fields. `room_start` and `east_checkpoint` remain valid; `citadel_checkpoint` is new. The shard uses `collected_crystals` with ID `citadel.training.axiom_shard`; completion uses `unlocks` with ID `citadel.training.complete`.

The original Godot application identity is deliberately retained so the default **user:// directory remains the same**. The visible window title is set separately to The Broken Laws. A regression assertion protects that identity. Save backups, corruption recovery and newer-schema overwrite protection still pass. Transient health/enemy state is intentionally reset on loading a checkpoint; reward/completion/discoveries/preferences persist.

Keyboard: A/D or arrows, Space jump, J light, K heavy, Shift dodge, E save, Q bench, Escape pause, R checkpoint return. Controller: stick/D-pad, A jump, X light, Y heavy, B dodge, right shoulder save, left shoulder bench, Start pause, Back return. Keyboard remapping includes all ten actions. Old custom bindings take priority over new defaults; conflicting defaults receive a free fallback key. Controller hardware remapping remains deferred.

Touch adds light, heavy and dodge to the existing jump/save/scan/pause controls. Separate finger ownership supports simultaneous move/jump/attack; hiding/focus loss releases owned inputs. Existing size, opacity, landscape safe-area handling and smaller browser UI reference remain. Synthetic touch/controller dispatch passed; actual hardware ergonomics are not certified.

## Actual validation

| Executed check | Result | Local evidence |
| --- | --- | --- |
| Editor import and headless boot | PASS | `artifacts/editor-import.log`, `headless-boot.log` |
| Unit/repository/science/component tests | **74 passed, 0 failed** | `artifacts/unit-tests.log` |
| Preserved Phase 0 scene tests | **28 passed, 0 failed** | `artifacts/scene-tests.log` |
| Movement/combat/AI/progression/input tests | **88 passed, 0 failed** | `artifacts/action-tests.log` |
| Continuous start-to-exit run with live AI | **6 passed, 0 failed** | `artifacts/dungeon-route.log` |
| Graphical legacy scene tests / captures | **31 passed, 0 failed** | `artifacts/graphical-scene-tests.log` |
| Graphical action tests / captures | **93 passed, 0 failed** | `artifacts/graphical-action-tests.log` |
| Graphical continuous route | **6 passed, 0 failed** | `artifacts/graphical-dungeon-route.log` |
| Independent Python scientific reference calculation | PASS: all four fixtures | `python tools/verify_physics_reference.py` executed |
| Windows debug export | PASS | `artifacts/windows-export.log` |
| Actual packaged Windows gameplay, headless | PASS: 11 named action checks plus original content/save smoke | `artifacts/windows-export-smoke.log` |
| Actual packaged Windows gameplay, graphical | PASS: 12 named checks including executable screenshot | `artifacts/windows-export-graphical-smoke.log` |
| Fresh official single-threaded Web release | PASS | `artifacts/web-export.log`, `web/build-manifest.json` |
| Local HTTP 200 / MIME / hash / missing asset 404 | PASS | `artifacts/web-http-validation.log`; localhost port 8061 |
| Web validator acceptance and rejection cases | **6 passed, 0 failed** | `artifacts/web-validator-tests.log` |
| Generated engine/worklet JavaScript syntax | PASS | `node --check` executed against all generated JS files |
| Existing Vercel local production-mode build | PASS; static output separately hash-verified | `artifacts/vercel-phase1-build.log`, `.vercel/output/static` |
| Existing production read-only page/manifest check | PASS: baseline Phase 0 remains served | `artifacts/phase1-production-readonly.log` |
| Interactive browser engine/gameplay/storage | **NOT VERIFIED** | Browser control stopped; manual checklist below |
| Actual mobile browser / physical controller | **NOT RUN** | Synthetic input is the available evidence |
| Native Android APK/device/soak | **NOT RUN** | Missing prerequisites below |
| Hosted CI / Phase 1 production deployment | **NOT RUN** | Nothing pushed or deployed |

The headless source suite totals **196 assertions**. Graphical suites repeat gameplay checks and add captures; their counts should not be represented as additional distinct features.

Coverage includes acceleration/deceleration, reversal, variable jump, coyote expiry, landing buffer, no double jump, dodge distance/walls/immunity/recovery/cooldown, all three cuts, heavy timing, directional hitboxes, one-hit protection, sword wall occlusion, damage immunity/knockback, crawler state changes/edge guard/bite cooldown/death/reset, turret telegraph/aim lock/fire interval/arc/destruction, high-speed player and terrain projectile impacts, expiry, invulnerable impacts, checkpoint healing/save, controlled death/respawn, duplicate actor prevention, projectile cleanup, reward/completion idempotence, reload, remapping migration, simultaneous touch and pause.

The continuous run uses normal movement/jump/heavy action inputs with live AI, normal stats, no teleports and no direct damage calls. It defeats all three crawlers and both turrets, activates the relay and finishes alive. Separate focused fixtures test the optional branch, light combo, dodge and death. Automated background checks suppress focus-loss pausing only in their test context; normal gameplay retains lifecycle pausing, which the legacy scene suite tests separately.

Detected issues were corrected before these final results: dodge recovery coasting; an application-name save-directory risk; audio references still releasing at immediate test shutdown; and hidden-window/fixed-frame assumptions in packaged tests. The packaged turret check now waits for an actual shot and impact within a bounded timeout. Final validation/export logs contain no script errors, failed checks or object-leak reports. The Android build-tools enumeration warning remains attributable to the missing SDK. Sandboxed Godot startup could not read the Windows certificate store; engine checks ran successfully with approved access outside that restriction.

## Performance and stability observations

On the NVIDIA GeForce MX250 / OpenGL 3.3 Compatibility setup, the rendered continuous run recorded **1433 observed physics steps over 23.88 s, 59.97 rendered FPS average**, mean process-monitor time 16.963 ms and p95 17.695 ms. These are Godot timing monitors, including scheduling/render synchronization, not isolated CPU benchmarks. The physics monitor averaged 2.995 ms in that run. Headless rendered FPS is intentionally zero and is not performance evidence for graphics.

Only one projectile was active at the observed peak. Actors remain bounded at one player/five enemies, distant AI returns early, impacts expire after 0.45 s, projectiles sweep/expire/consume, and scene teardown verifies empty player/enemy/projectile groups. Explicit audio stop/release and a short test teardown drain avoid pending mix-thread references at engine exit. No pooling was introduced. These short tests do not establish long-session memory stability, browser FPS or Android thermal performance.

The educational physics sources, fixtures, concept/curriculum files and puzzle runtime were unchanged. The original SI references still yield approximately 19.9796126402 m, 3.2058581578 m/s², 6.2641839053 m/s and 2 A. No scientific model was retuned to make arcade movement feel different.

## Builds, screenshots and reproduction

- Play Windows: [builds/windows/Aetheria.exe](builds/windows/Aetheria.exe), unsigned x86_64 debug build with embedded pack.
- Play local Web: [http://127.0.0.1:8061/](http://127.0.0.1:8061/). A local static server was left running. If stopped, run `python tools/serve_web.py --port 8061` from the project root.
- Complete Web release: `web/` contains HTML, engine JS, WASM, PCK, two audio worklets, splash PNG and manifest. All are required; unchanged engine/support assets remain included.
- Local Vercel output: `.vercel/output/static/`. The executed `vercel build --prod` command builds locally and does not deploy.
- Build hashes/sizes are recorded below and in `artifacts/phase1-build-evidence.json`.

Local screenshots were rendered and inspected: [sword impact](artifacts/phase1-combat.png), [turret telegraph](artifacts/phase1-turret.png), [touch controls and relay](artifacts/phase1-touch-relay.png), [completion](artifacts/phase1-completion.png), [pause](artifacts/phase1-pause.png), and [actual Windows executable](artifacts/phase1-windows.png). These are native Godot images, not browser screenshots. Logs, screenshots and native builds remain ignored local evidence rather than Git additions.

Reproduce with:

```powershell
.\tools\validate.ps1 -Capture
.\tools\export_windows.ps1 -Graphical
.\tools\export_web.ps1
node tools/verify_web_export.mjs --url http://127.0.0.1:8061/
node tests/test_web_integrity.mjs
vercel build --prod --yes --scope pek-explains-physics
node tools/verify_web_export.mjs --directory .vercel/output/static
```

### Browser verification still required

No controllable browser was exposed by the browser surface inventory. The Windows computer-use helper then stopped because it could not establish Chrome's current URL confidently enough to enforce its policy. No further UI automation was issued.

The [computer-use SKILL.md](<C:/Users/User/.codex/plugins/cache/openai-bundled/computer-use/26.1016.62342/skills/computer-use/SKILL.md>) requires its [guidance](<C:/Users/User/.codex/plugins/cache/openai-bundled/computer-use/26.1016.62342/docs/guidance.md>), which states: "If Computer Use reports that the turn ended or that the user stopped Computer Use, stop issuing app input." The helper's stop notice ended browser interaction; terminal validation continued within the authorized scope. This is a tooling limit, not evidence that the Web game failed or passed interactive play.

1. Open localhost port 8061 in a current WebGL 2 browser; confirm the TRAINING SECTOR HUD, health bar and new combat controls appear.
2. Move/jump across the opening gap. Test J combo, K heavy and Shift dodge; verify crawler and turret feedback, health loss and invulnerability.
3. Activate the relay, die and respawn there, collect the upper shard, reach the exit, pause/resume and use the unchanged numerical bench.
4. Save/reload on the same origin and verify checkpoint, shard, completion and remapped keys persist. Inspect Console/Network for critical errors or missing JS/WASM/PCK requests.
5. Resize/fullscreen, background/resume, and test simultaneous movement/jump/attack/dodge on an actual landscape touch browser. Record browser/device versions; verify storage and safe areas.

### Native Android status

The landscape arm64 preset and existing package identity remain. Matching Android templates, SDK/build-tools and adb were absent; the configured SDK location did not exist. Java 25 is installed but has not been validated for this project, and no local debug signing identity was present at the configured location. No APK export, install or device FPS claim is made.

Install matching **4.7.2 Android templates**, a supported Java setup (Godot recommends **JDK 17**), SDK platform-tools >=35.0.0, build-tools 35.0.1, platform 35, current command-line tools, CMake 3.10.2.4988404 and NDK 28.1.13356709; configure editor SDK paths and a local debug signing identity outside version control. These requirements were checked against the [official Godot 4.7 Android guide](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html). Then export/install an APK and test touch, save/lifecycle, insets and sustained performance on named hardware. Missing native tooling did not block Phase 1 development.

### Final artifact identity

- Windows: 103,289,200 bytes; SHA-256 `3eaf7c91587c3e10008ade40ebe4bbb60750dc3c5a896db6400ce9cb843aeefb`.
- Web: 39,944,850 bytes (38.09 MiB).
- Web source SHA-256: `9744b97fd8b9d20b4125157e242476ea27102c00bf9c6e40c8608a687c302cd4`.
- Web PCK SHA-256: `701a54479b43a6b7d1d7c93798d8dcd8a4b5802e1ec5fbb1b9b906ebac1ea33f`.

## Exact changed files

The following list is relative to the repository root and includes every modified/new Git-visible path, including this report. No pre-existing unrelated edits were present. Generated native builds and local evidence are listed separately above.

- Modified: `.gitattributes`
- Modified: `.github/workflows/phase0.yml`
- Modified: `README.md`
- Modified: `export_presets.cfg`
- Modified: `project.godot`
- Modified: `scenes/player/player.tscn`
- Modified: `scenes/ui/touch_overlay.tscn`
- Modified: `scripts/core/boot.gd`
- Modified: `scripts/core/graybox_room.gd`
- Modified: `scripts/core/save_repository.gd`
- Modified: `scripts/platform/input_adapter.gd`
- Modified: `scripts/player/player.gd`
- Modified: `tests/run_unit_tests.gd`
- Modified: `tools/export_windows.ps1`
- Modified: `tools/validate.ps1`
- Modified: `tools/verify_web_export.mjs`
- Modified: `web/build-manifest.json`
- Modified: `web/index.html`
- Modified: `web/index.pck`
- Modified: `web_shell/index.html`
- Added: `PHASE_1_IMPLEMENTATION_REPORT.md`
- Added: `content/combat/crawler.tres`
- Added: `content/combat/heavy.tres`
- Added: `content/combat/light_1.tres`
- Added: `content/combat/light_2.tres`
- Added: `content/combat/light_3.tres`
- Added: `content/combat/turret.tres`
- Added: `scenes/enemies/defensive_turret.tscn`
- Added: `scenes/enemies/mechanical_crawler.tscn`
- Added: `scripts/combat/attack_data.gd`
- Added: `scripts/combat/attack_data.gd.uid`
- Added: `scripts/combat/combat_audio.gd`
- Added: `scripts/combat/combat_audio.gd.uid`
- Added: `scripts/combat/combat_controller.gd`
- Added: `scripts/combat/combat_controller.gd.uid`
- Added: `scripts/combat/health_component.gd`
- Added: `scripts/combat/health_component.gd.uid`
- Added: `scripts/combat/impact_burst.gd`
- Added: `scripts/combat/impact_burst.gd.uid`
- Added: `scripts/core/packaged_smoke.gd`
- Added: `scripts/core/packaged_smoke.gd.uid`
- Added: `scripts/enemies/defensive_turret.gd`
- Added: `scripts/enemies/defensive_turret.gd.uid`
- Added: `scripts/enemies/enemy_base.gd`
- Added: `scripts/enemies/enemy_base.gd.uid`
- Added: `scripts/enemies/enemy_profile.gd`
- Added: `scripts/enemies/enemy_profile.gd.uid`
- Added: `scripts/enemies/mechanical_crawler.gd`
- Added: `scripts/enemies/mechanical_crawler.gd.uid`
- Added: `scripts/enemies/security_projectile.gd`
- Added: `scripts/enemies/security_projectile.gd.uid`
- Added: `scripts/level/modular_platform.gd`
- Added: `scripts/level/modular_platform.gd.uid`
- Added: `scripts/level/progression_marker.gd`
- Added: `scripts/level/progression_marker.gd.uid`
- Added: `scripts/player/dodge_controller.gd`
- Added: `scripts/player/dodge_controller.gd.uid`
- Added: `tests/integration/run_action_tests.gd`
- Added: `tests/integration/run_action_tests.gd.uid`
- Added: `tests/integration/run_dungeon_route.gd`
- Added: `tests/integration/run_dungeon_route.gd.uid`
- Added: `tests/unit/test_action_components.gd`
- Added: `tests/unit/test_action_components.gd.uid`

## Remaining limits and Phase 2

Interactive browser/storage acceptance, actual mobile/controller hardware, APK export, device ergonomics and long-duration performance still need execution. Windows is a local unsigned debug build. Art/audio are original placeholders; combo/enemy balance is validated through automation and still needs human feel testing. Controller remapping and movable touch layouts remain future work. Checkpoint returns restore enemies; persistent enemy-by-enemy dungeon state is not part of this prototype. Exit completion has no boss/kill gate.

Finish the remaining platform acceptance first. Phase 2 can then introduce Vector Sight and one reviewed physical ramp/launcher/energy apparatus through the existing SI model interfaces, with measured world geometry and explicit assumptions. Keep the seven kingdoms, bosses, economy and broad curriculum integration outside that next focused slice until separately scoped.

**Release boundary:** review the local changes and browser evidence, then obtain explicit authorization before any GitHub push or production deployment. The existing repository, Vercel project and domain remain in place.

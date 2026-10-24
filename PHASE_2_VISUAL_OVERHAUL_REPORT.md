# Phase 2 visual overhaul report

Date: 2026-10-24. Baseline: `main`, commit `62efe3d` (accepted Phase 1). Work remains local and uncommitted. No push, deployment, history rewrite, credential change, production-domain change or Vercel project replacement was performed.

## Implemented presentation

The Mechanical Citadel now uses original AI-assisted pixel artwork: a brown-haired salvager in dark leather and bronze, an ochre scarf, a jade Axiom gauntlet, articulated bronze machines, weathered masonry, carved arches, suspended chains, ruined machinery and amber lamps. Cool distant architecture contrasts with brighter bronze collision surfaces, jade interactives and amber enemy telegraphs. The featured level's old rectangle characters, grid background, flat terrain, flag checkpoints and simple exit have been replaced.

The original 640 x 360 world remains separate from the high-resolution UI. Characters use `AnimatedSprite2D` and cached `SpriteFrames`; measured `AtlasTexture` regions normalize feet and the turret barrel pivot. Camera tracking and shake use whole world pixels. Nearest filtering, clipped atlas sampling and disabled mipmaps retain sharp world pixels. UI headings use bundled Cinzel; readable body text retains Godot's fallback font.

The HUD has an iron-and-brass panel, health flask/bar, sword/dodge/shard icons, readable combat status and remapping-aware help. Status wraps at the 960 x 540 landscape reference. The scrollable pause menu retains resume, checkpoint return, all ten bindings, defaults, touch sizing/opacity, save and quit. Presentation controls add reduced/standard/enhanced effects, reduced motion and optional camera shake. Web/mobile default to reduced effects and zero shake. Reduced motion suppresses shake, dodge ghosts, immunity blinking, lamp flicker and ambient drift, and caps hit-flash intensity. Essential action animations remain active.

## Asset specifications and provenance

| Master | Actual size | Runtime use |
| --- | --- | --- |
| `assets/characters/kael_atlas.png` | 1254 x 1254 RGBA | 64 measured regions, 14 Kael animations |
| `assets/enemies/machines_atlas.png` | 1254 x 1254 RGBA | 64 regions: crawler, turret base/barrel, effects |
| `assets/environment/citadel_atlas.png` | 1254 x 1254 RGBA | 64 terrain/prop/interactive/icon/VFX regions |
| `assets/backgrounds/citadel_depths.png` | 1536 x 1024 | Distant vault backdrop |
| `assets/fonts/Cinzel.ttf` | Official variable TTF | SIL OFL 1.1 headings; license bundled in exports |

All raster masters were generated for this project with the built-in image tool from original descriptions, without commercial game references or an external paid AI API integration. Exact prompts are in [generation_prompts.json](assets/source/generation_prompts.json). These are AI-assisted assets; they are not described as hand-drawn. The generator supplied uneven gutters and different dimensions from the requested grid. The original pixels remain unchanged; [build_art_metadata.gd](tools/build_art_metadata.gd) measures explicit row bands and alpha bounds into [atlas_layout.json](assets/source/atlas_layout.json), which is explicitly packaged for every platform.

Character frames use a 192 x 192 virtual canvas at quarter scale (48 x 48 world pixels), with standing bodies approximately 26-36 pixels tall. Environment modules are drawn at 32 x 32, with the last partial tile cropped to the exact existing collider dimensions. The turret has separate rotating barrel artwork. The source images, import settings, shader, metadata, generation prompts and font license are retained in the working tree.

The sole external artwork-related dependency is the [official Cinzel font](https://github.com/google/fonts/tree/main/ofl/cinzel), copyright 2020 The Cinzel Project Authors, distributed under the SIL Open Font License 1.1. [Full provenance and license details](assets/ASSET_PROVENANCE.md) are included locally. Original synthesized Phase 1 sound effects remain unchanged.

## Animation and combat alignment

| Kael state | Atlas frames (zero-based) | Playback |
| --- | --- | --- |
| Idle / run | 0-7 / 8-15 | 6 / 12 FPS loops |
| Jump start / rise / fall / land | 16-17 / 18-19 / 20-21 / 22-23 | Existing floor/vertical-velocity transitions; brief landing response |
| Light I / II / III | 24-27 / 28-31 / 32-35 | Anticipation held during startup, contact frames during active window, follow-through during recovery |
| Heavy Breaker | 36-39 | Same authoritative phase alignment, preserving the longer windup |
| Dodge | 40-47 | Sampled from existing dodge elapsed time and latched direction |
| Hurt / recovery | 48-51 / 52-55 | Existing hurt timer / explicit checkpoint reset signal |
| Death | 56-63 | Sampled from existing 0.9-second respawn countdown |

Crawler art covers idle, patrol, faster chase, alert, attack anticipation/lunge/recovery, hurt and disassembly. Turret presentation combines a pulsing base, aiming/charging barrel, locked dashed telegraph, shot-triggered muzzle flash, hit flash and destroyed base. Resetting its shot counter cannot create a false muzzle flash.

`ActorPresentation` observes gameplay state. It does not change actor position, velocity, health, hitboxes, AI, attack timers or cooldowns. Sword accents follow the existing directional reach/height during the active window. Damage numbers and impact stars follow accepted damage signals; they are not generated by visual contact alone. Effects include bounded sparks, landing dust, death fragments, short dodge ghosts, shard orbit/bob, relay activation rings and a subtle portal. Particle bursts expire after 0.45 seconds. No hit-stop or gameplay slowdown was added.

## Environment and performance choices

The unchanged three original floor/platform colliders and thirteen extension platforms are skinned with masonry or metal grating. Decorative pillars, gears, chains, crystal clusters and lamps have no new collision. The same checkpoint, shard and exit triggers remain in use.

Two camera-relative decorative layers use 0.18 and 0.48 motion ratios, behind static props, walkable terrain, interactives and actors. Distant arches are deliberately dark; the upper lips of walkable surfaces remain bright. Ambient modulation and seven lightweight local lights add atmosphere. Lights outside a 440-pixel camera radius are disabled; reduced effects disable them all. There are no dynamic shadows, full-screen shaders, bloom or screen-space postprocessing. Static terrain draw commands are retained; moving motes draw separately. Atlas textures and animation resources are shared and cached.

| Preset | Ambient motes | Sparks per impact | Dodge ghosts | Dynamic lights |
| --- | --- | --- | --- | --- |
| Reduced | 8 | 3 | 1 | Off |
| Standard | 20 | 7 | 2 | Nearby, no shadows |
| Enhanced | 36 | 10 | 3 | Nearby, no shadows |

These settings are presentation-only and live inside the existing `control_preferences` dictionary. Save schema, application identity and `content_version: phase1.0` remain unchanged.

## Before/after visual evidence

Open the [interactive comparison gallery](artifacts/phase2-comparison.html). It switches between matching direct Godot captures without modifying the screenshots. The baseline was rendered from a read-only `git archive` of `62efe3d`, under ignored `artifacts/phase2-baseline-project`; the active working tree was not reset or switched. A common deterministic capture harness stages review poses. These captures demonstrate appearance; gameplay correctness is separately exercised by the live-AI route and action tests.

| Review | Before | After |
| --- | --- | --- |
| Idle / native world | [Idle](artifacts/phase2-before/idle.png) | [Idle](artifacts/phase2-after/idle.png), [640 x 360](artifacts/phase2-after/idle-native.png) |
| Run / jumping | [Run](artifacts/phase2-before/run.png), [jump](artifacts/phase2-before/jump-rise.png) | [Run](artifacts/phase2-after/run.png), [start](artifacts/phase2-after/jump-start.png), [rise](artifacts/phase2-after/jump-rise.png), [fall](artifacts/phase2-after/jump-fall.png), [land](artifacts/phase2-after/land.png) |
| Three light cuts | [Light I](artifacts/phase2-before/light-1.png) | [I](artifacts/phase2-after/light-1.png), [II](artifacts/phase2-after/light-2.png), [III](artifacts/phase2-after/light-3.png) |
| Heavy | [Heavy](artifacts/phase2-before/heavy.png) | [Windup](artifacts/phase2-after/heavy-windup.png), [contact](artifacts/phase2-after/heavy.png) |
| Dodge | [Before](artifacts/phase2-before/dodge.png) | [After](artifacts/phase2-after/dodge.png) |
| Hurt / death / recovery | [Death](artifacts/phase2-before/death.png) | [Hurt](artifacts/phase2-after/hurt.png), [death](artifacts/phase2-after/death.png), [recovery](artifacts/phase2-after/respawn.png) |
| Crawler / turret | [Crawler](artifacts/phase2-before/crawler.png), [turret](artifacts/phase2-before/turret.png) | [Crawler](artifacts/phase2-after/crawler.png), [turret](artifacts/phase2-after/turret.png) |
| Checkpoint / shard / exit | [Checkpoint](artifacts/phase2-before/checkpoint.png), [shard](artifacts/phase2-before/collectible.png), [exit](artifacts/phase2-before/exit.png) | [Checkpoint](artifacts/phase2-after/checkpoint.png), [shard](artifacts/phase2-after/collectible.png), [exit](artifacts/phase2-after/exit.png) |
| Pause / touch | [Pause](artifacts/phase2-before/pause.png), [touch](artifacts/phase2-before/touch.png) | [Pause](artifacts/phase2-after/pause.png), [settings](artifacts/phase2-after/presentation-settings.png), [960 x 540 touch](artifacts/phase2-after/touch-landscape.png) |
| Environment | [Before](artifacts/phase2-before/environment.png) | [After](artifacts/phase2-after/environment.png), [native](artifacts/phase2-after/environment-native.png) |

There are 23 matching full-size review states, two native-resolution world captures per version, and two additional Phase 2 settings/touch captures. Captures were inspected at native 640 x 360 and at 1280 x 720; the smaller touch view was also inspected. This revealed and corrected an unsupported HUD separator, responsive text overflow and an incorrectly placed checkpoint capture. Walkable edges, feet, enemy telegraphs, the shard and the exit remain distinct. The player is drawn in front of the exit artwork.

## Gameplay preservation

The movement/physics functions are unchanged apart from adding a presentation reset signal. Crawler and turret AI changes only remove their old `_draw()` placeholders. Combat hit queries, attack resources, damage, knockback, i-frames, dodge distances/cooldowns and death timing remain unchanged. The original level collision scene, all combat/content resources, input adapter, save repository, scientific models, puzzle controller and curriculum modules have no diff against the baseline. Checkpoint/relic code adds visual children and a cosmetic pickup burst while retaining the existing trigger rules and stable save IDs.

No Vector Sight, Impulse Strike, new physics apparatus, new kingdom, encounter, economy or online service was implemented. The numerical bench remains the existing explicitly labelled preview. A direct [source-function audit](artifacts/phase2-gameplay-preservation.json) also matched 32 gameplay functions against the baseline, allowing only the cosmetic reset signal in `reset_to`.

## Automated validation

Executed locally with Godot 4.7.2 stable, Compatibility/OpenGL, on Windows with an NVIDIA GeForce MX250. Final assertion summaries are retained in `artifacts/`:

| Runner | Headless | Graphical |
| --- | ---: | ---: |
| Unit/numerical/repository/component tests | 74 | -- |
| Legacy scene integration | 28 | 31 |
| Action/combat/enemy/progression/input integration | 88 | 93 |
| Continuous live-AI dungeon route | 6 | 6 |
| New presentation contracts | 74 | 74 |
| Total | 270 | 204 |

Total: **474 passing Godot assertions**, zero final failures. Graphical counts include existing screenshot-save assertions. The presentation suite tests all 192 resource regions, all 14 hero animations, real jump phases, combo/heavy startup-active-recovery frames, locked facing, lack of gameplay mutation, dodge/hurt/death/recovery, real enemy damage feedback, turret firing/reset/destruction, relay/shard visual states, quality clamping, reduced-motion impulses, light disabling, parallax depth ordering, camera reset, small-screen HUD bounds and save/reload compatibility.

The full wrapper imports resources, checks boot, rejects missing summaries, engine errors and leaked-instance warnings, and captures the final showcase. Frame-count assertion runners and the showcase use Godot's `--fixed-fps 60` test clock; the live dungeon routes retain real-time synchronization for performance measurement. During development, the new SceneTree runner initially referenced autoload-dependent types too early; it now loads actors after autoload initialization. A transient teardown warning was corrected by releasing its observer/references and allowing queued destruction to complete. A graphical rerun interrupted by concurrent browser focus failed two movement checks; final graphical validation was run without browser interaction. A separate legacy startup check could also cross its sampled window when a slow process iteration ran multiple catch-up physics steps; the fixed assertion clock removes that test-clock ambiguity without changing gameplay resources or timings. These development runs are not included in the final passing counts.

Additional checks: the independent Python SI reference calculator passed four numerical examples; six adversarial Web validator fixtures passed; generated JS and both worklets passed `node --check`; `git diff --check` passed. No remote CI result is claimed.

## Windows and Web builds

The refreshed [Windows debug executable](builds/windows/Aetheria.exe) was exported locally (109,409,248 bytes). Packaged headless and graphical smoke checks passed, including actual movement/jump, sword damage, crawler death, turret projectile/destruction, relay save, death/respawn, shard/exit, persistence, pause, the SI bench, metadata/atlas/font availability and a packaged screenshot. There were 12 headless and 13 graphical packaged check lines. Logs: [headless](artifacts/windows-export-smoke.log), [graphical](artifacts/windows-export-graphical-smoke.log). This is an unsigned debug build; release signing/distribution is outside this validation.

The complete refreshed Web release is **46,064,899 bytes / 43.93 MiB**, including a 6,232,532-byte PCK and 39,514,754-byte WASM. It retains Compatibility/WebGL 2, the single-threaded template, existing shell and complete asset filenames. The source SHA-256 in [build-manifest.json](web/build-manifest.json) is `ad4dbf3d43b587a9bcf1563953d778962c417448a5beaa433e64c337c551c442`. Binary dependencies unchanged by Phase 2 remain byte-identical; the complete set is retained under `web/`.

`tools/export_web.ps1`, filesystem integrity checks, all eight local HTTP asset/manifest checks at `http://127.0.0.1:8061/`, generated-JS syntax checks and all six integrity rejection fixtures passed. `vercel build --prod --yes --scope pek-explains-physics` completed locally, and `.vercel/output/static` passed the same export verifier. This command built local output; it did not deploy. Existing hosting configuration and production domain were preserved.

Chrome loaded the refreshed release and visibly rendered the new terrain, character, artwork, font and HUD. The browser window was resized/maximized and the pause menu and lower presentation options were operated. The Web default was visibly reduced effects with zero shake. The reduced-motion option was toggled, saved, and visibly restored after a browser reload. Browser validation here is a loading/UI/presentation check; a full Phase 2 browser combat playthrough, browser FPS profiling, console audit, real multitouch and production-origin save testing are not claimed. The user supplied the earlier Phase 1 browser acceptance; that evidence is kept distinct from this local Phase 2 check.

## Performance findings

| Continuous rendered route | Phase 1 baseline | Phase 2 |
| --- | ---: | ---: |
| Rendered FPS | 59.93 | 59.49 |
| Wall time | 23.88 s | 23.94 s |
| Mean process interval | 16.795 ms | 20.033 ms |
| 95th percentile process interval | 17.917 ms | 31.344 ms |
| Peak live projectiles | 1 | 1 |

The route reaches the exit alive and defeats all five enemies using ordinary input and live AI. The table uses the final standalone repeat with the local Web game tab closed. An earlier standalone Phase 2 sample measured 59.94 FPS (17.011 ms mean, 17.921 ms p95). The final repeat stayed near 60 FPS but had higher interval outliers, as shown rather than hidden. A run with the Chrome Web game also open measured 40.73 FPS, 36.523 ms mean and 59.494 ms p95; its [full log is retained](artifacts/phase2-route-with-browser-open.log). Closing that tab restored 59.49 FPS, consistent with shared-resource contention. Running both versions together is a meaningful limitation on this MX250. These are short, vsync-limited route samples, not GPU benchmarks or guarantees for other hardware. Godot's separate physics monitor varied between runs and is not used to claim a solver speedup.

The graphical visual harness reported approximately 40.8 MiB of texture memory and 45 canvas draw calls at its sampled review view. Those are renderer-reported point samples including viewports/UI; draw calls vary with camera position, quality and effects. Headless texture/draw metrics are zero and are not treated as hardware results. No browser/mobile FPS is invented.

## Android and remaining limitations

No Android APK or device run was produced. The existing arm64 landscape preset, Compatibility renderer and offline permissions remain. This environment exposes Java 25, but no `adb`, Android SDK/build-tools or matching Android export templates. Matching Godot Android prerequisites and an actual device are required before certification. The 960 x 540 touch rendering, safe-area tests and synthetic two-/three-finger integration tests passed on Windows; they do not certify native Android or real mobile-browser performance.

The featured level has no remaining rectangle character/terrain/flag placeholders. Simple health bars, aim lines, collision lips and small particles are intentional interface/effect graphics. Audio remains the original synthesized Phase 1 placeholder set. The engine-generated Web splash image (`web/index.png`) still uses Godot branding. Generated artwork still has minor pose/proportion, sword-continuity and pixel-cluster variation; the short contact/recovery sets are less fluid than a dedicated hand-animated production sheet. Decorative architecture repeats, tiles have a limited variation set, and atmospheric lighting intentionally has no shadows or occlusion. A fixed 640 x 360 world may show letterboxing at unusual browser aspect ratios. Touch icons retain text captions so the small glyphs do not carry meaning alone.

Recommended next work: a reviewed manual sprite cleanup/animation cadence pass, broader modular tile/foreground variations, actual mobile/browser/controller profiling and playthroughs, and Android tooling/device validation. The independently reviewed physics-powered gameplay expansion remains Phase 3.

## Local handoff

Run `tools/validate.ps1 -Capture`, `tools/export_windows.ps1 -Graphical` and `tools/export_web.ps1` to reproduce the checks. Open `artifacts/phase2-comparison.html` for visual review or `builds/windows/Aetheria.exe` to play. The local HTTP server on port 8061 serves the refreshed Web build. Keep the generated `web/` set together when the user later chooses to publish.

The [pre-change inventory](docs/PHASE_2_VISUAL_INVENTORY.md), [asset provenance](assets/ASSET_PROVENANCE.md), [README](README.md) and [complete changed-file list](docs/PHASE_2_CHANGED_FILES.md) accompany this report. Screenshots, logs, baseline archive, local Windows build and local Vercel output are intentionally ignored by Git. **Nothing has been staged, committed, pushed or deployed.**

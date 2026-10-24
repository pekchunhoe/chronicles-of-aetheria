# Phase 3 — Physics gameplay and final browser validation

Validated locally on **24 October 2026, Asia/Kuala_Lumpur**, with **Godot 4.7.2.stable.official.ed1daf0bf**. Starting and final Git HEAD: `main`, `52db0ca` (`Phase 2: Premium pixel-art visual overhaul`).

## Outcome

The Phase 3 implementation is available for local user acceptance: Vector Sight, physical cargo/friction and projectile apparatus, Impulse Strike, the mechanical-energy engine, six connected Research Chambers, nine offline Codex entries, optional Scholar challenges, save compatibility, and dedicated touch controls. The interrupted browser defects are fixed and verified through actual rendered screenshots.

The final matrix contains **759 passing Godot assertions**, **24 passing browser assertions**, **13 independent Python reference checks**, and **6 Web-validator acceptance/rejection fixtures**. Windows packaged checks pass in headless and rendered modes. The complete local Web release and existing Vercel project's local production-mode build pass integrity checks. The final continuous rendered research route measured **59.96 FPS on the NVIDIA MX250**.

All changes remain **local and uncommitted**, with nothing staged. No push, deployment, history reset, credential change, environment-file deletion, Vercel project replacement or production-setting change was performed. Human acceptance, first-time pacing and actual Android/controller hardware remain separate checks.

## Initial inspection and preservation

The original GDD, Phase 0/1 reports, Phase 2 report, source architecture, input mappings, touch controls, saves, presentation assets, numerical modules, export scripts and Git history were inspected. The starting working tree was clean, with approved Phase 2 already committed. The preserved baseline reran **474 assertions** successfully; its rendered Citadel route measured **59.86 FPS**.

Direct Git comparison confirms the approved character/enemy/environment/background raster masters, atlas metadata, generation prompts, hit-flash shader, Cinzel font and original OFL license are unchanged from `52db0ca`. The original 3328 px Citadel sector, its authored platforms and existing gameplay remain covered by regression tests. New machinery assembles bronze/stone components from the approved atlas, with animated payloads, receivers, energy meters and teal effects.

The application/save-directory identity remains unchanged. Phase 0–2 reports remain historical records. No second repository or additional kingdom was created.

## Implemented adventure

Choose **Chambers** in the HUD, or Interact at the original Citadel's east exit. The research wing uses a 7040 world-pixel interconnected layout, six checkpoints, familiar enemies, a branching upper passage, an optional research Axiom Shard and recognizable return/exit portals.

| Chamber | Playable behavior |
| --- | --- |
| A — Lost Laboratory | Mira's pedestal interaction installs Vector Sight and introduces observation and three Codex discoveries. |
| B — Cargo Mechanism | An adjustable inclined guide demonstrates static release, kinetic friction and acceleration. Moving cargo must contact the weighted receiver. |
| C — Broken Crossing | A launcher fires a swept collision projectile toward a distant receiver. Actual receiver contact restores a physically walkable bridge. |
| D — Momentum Vault | Entry unlocks Impulse Strike. Cargo mass changes the response to the same impulse; a rough rail leads to a momentum latch. The optional upper passage contains the research shard. |
| E — Energy Engine | An adjustable raised counterweight descends along a vertical guide. Incident kinetic energy at real contact operates the receiver; selectable guide resistance demonstrates thermal transfer. |
| F — Integrated Trial | A second incline and an elevated projectile receiver combine with ordinary sword combat. Both physical relays and a defeated trial security machine are required to open the final seal. |

There are six apparatus instances and eight familiar enemies in the research wing. The continuous route uses normal player statistics, live AI, movement and sword/gauntlet inputs. It performs no position warps after expedition entry and applies no direct enemy damage. It completes every physical relay, defeats all eight enemies, unlocks all nine Codex records with Scholar Mode disabled, reaches the exit alive and verifies the saved completion.

The route supplies known apparatus settings programmatically through the same adjustment interface. Its approximately 56-second execution is a solved automated route, **not a first-time playtime estimate**. The 20–35 minute exploration target and intended 60/40 action/physics balance still need independent human playtesting; pacing/content expansion may be needed.

## Controls and interaction

| Action | Keyboard default | Controller default |
| --- | --- | --- |
| Interact / tune machine / save | E | Right shoulder |
| Vector Sight in research | Q | Left shoulder |
| Impulse Strike | F | Left stick click |
| Physics Codex | Tab | Right stick click |
| Checkpoint return / recover experiments | R | Back / Select |
| Existing movement, jump, light, heavy, dodge, pause | A/D, Space, J, K, Shift, Escape | Existing bindings preserved |

F avoids replacing the existing E interaction binding. Pause-menu remapping accepts keyboard keys or controller buttons, rejects duplicates and saves the two mapping types separately. Older custom keys have priority over new defaults.

Landscape touch adds **SIGHT**, **IMPULSE**, **CODEX** and **USE** buttons. Existing finger ownership still supports simultaneous movement/jump/attack. Standard menus, sliders and numerical input accept touch through mouse emulation. Instruments pause the world and hide the gameplay overlay. The mobile notification strip no longer covers the gauntlet row; compact research feedback is bounded and checked against maximum-size movement/impulse controls. Instrument panels scroll and provide a visible close button.

## Separation of responsibilities

| Layer | Implementation |
| --- | --- |
| Arcade traversal/combat | Existing player, weapon, dodge, health and enemy systems; enemy impulse stagger is explicitly an arcade rule. |
| Scientific SI mathematics | `MechanicsModel`, alongside the unchanged legacy `PhysicsModel` contracts. |
| Apparatus state | `ExperimentState`: SI parameters, exact motion, elapsed time, energy and captured measurements. |
| Scene contact | `AxiomApparatus`: reusable scenes, swept payload bodies, receiver geometry and contact thresholds. |
| Progression | `ResearchProgress` and `ResearchChambers`: stable relays, discoveries, gates, checkpoints and exit. |
| Education | `PhysicsCodex`, local JSON and `ScholarChallenges`: explanations, assumptions, examples, deterministic questions and tolerances. |
| Presentation | Apparatus art composition, vector diagram and `ResearchInterface`; approved Phase 2 atlases/animations remain in use. |

## Scientific contract

All quantitative apparatus uses SI internally. **64 world pixels = 1 m**. Projection flips SI-positive-up into Godot-positive-down. Browser/device pixels are presentation scaling, not metres. Player movement/gravity and enemy combat remain arcade values in pixels per second.

### Incline and friction

`W = mg`, `N = mg cos θ`, `W∥ = mg sin θ`, `ΣF = ma`.

At rest, static friction balances the required tangential force up to `|fₛ| ≤ μₛN`; maximum static friction is not applied automatically. Downhill release occurs when `mg sin θ > μₛmg cos θ`. For downhill sliding, `a = g(sin θ − μₖ cos θ)`. Kinetic friction reverses sign for uphill motion. Integration splits at zero speed, then checks whether the body remains static or starts moving downhill.

The straight guide has fixed length 4 m; its receiver is attached to the adjustable rail end. The simplified weighted latch requires cargo mass ≥ 8 kg and nonzero incident speed, evaluated only after actual receiver contact. It is not a quantitative pressure/deformation simulation.

### Projectile motion

`vₓ = u cos θ`, `vᵧ = u sin θ − gt`.

`x = x₀ + u cos θ t`, `y = y₀ + u sin θ t − ½gt²`.

`H = u²sin²θ / (2g)`. The equal-height range `R = u²sin(2θ)/g` applies only to equal elevations. Unequal elevations use the real positive roots of `½gt² − u sin θ t + Δy = 0`; the later positive root gives the descending elevation crossing. An elevation can be reachable while a receiver at a particular horizontal position is still missed.

Uniform selected gravity (8–12 m s⁻²), negligible drag and a deterministic analytic clock are assumed. Launch/receiver positions, speed, angle and gravity are adjustable. Predicted points use the same state function and are rebuilt only when inputs change. The receiver has a 24 × 48 world-pixel face; the projectile has a 4 px collision radius. Contact can therefore occur before reaching the receiver's centre-plane solution. Terrain and receiver contact use actual swept scene collisions. Camera follow keeps high arcs observable.

### Impulse and momentum

`p = mv`, `J = FₐᵥΔt = Δp`, `Δv = J/m`, with vector quantities where required.

The experimental strike delivers an ideal instantaneous horizontal net impulse of 10 N s, with other impulses negligible during that instant. Subsequent rough-guide friction uses `μ = 0.10`, so cargo momentum alone is not conserved during the later travel. The receiver captures cargo and latches for rightward incident momentum ≥ 4 N s, transferring momentum to the Citadel.

The ability has a 0.10 s windup, short Phase 2 pose/effect, target and obstruction checks, and a 2 s cooldown. It staggers crawlers without dealing sword damage. Anchored turrets return explicit resistance feedback. Enemy stagger is not labelled a calibrated mass/impulse experiment. Exported ability properties support later tuning/upgrades.

### Energy and work

`Eₚ = mgh`, `Eₖ = ½mv²`, `Eₛ = ½kx²`, `Wₙₑₜ = ΔEₖ`.

The playable engine is a **guided falling counterweight**, released from rest. The receiver height is the potential-energy datum. An optional constant upward guide resistance `λmg` transfers `E(thermal) = λmgd`, giving `a = g(1 − λ)` and `v = √[2gh(1 − λ)]` after the full descent. During motion, `mgh(initial) = Eₚ + Eₖ + E(thermal)`.

The receiver captures the weight; incident kinetic energy ≥ 20 J turns its latch. Incident velocity/energy are preserved as a labelled contact snapshot; subsequent kinetic energy transfers to the machinery and surroundings. Resetting supplies external lifting work. This is a simplified absorbing mechanism, not a complete coupled rigid-body collision solver. Spring energy is implemented and tested in the mathematics/Codex; an interactive spring or pendulum is a future apparatus variant.

### Required numerical benchmarks

Reference values below come from the independent numerical fixtures; rendered contact states have the separate tolerances documented below.

| Fixture | SI numerical reference | Rounded acceptance tolerance |
| --- | ---: | ---: |
| 10 kg, 30°, μₛ = 0.40, μₖ = 0.20, g = 9.81 | Downhill `a = 3.205858157775 m s⁻²` | ±0.005 about 3.21 m s⁻² |
| 14 m s⁻¹, 45°, equal heights | `R = 19.979612640163 m`; `t = 2.018245654763 s` | ±0.005 about 19.98 m |
| +10 N s, 2 kg, initially at rest | `Δv = +5 m s⁻¹` | 1e-9 in the numerical check |
| +10 N s, 5 kg, initially at rest | `Δv = +2 m s⁻¹` | 1e-9 in the numerical check |
| Ideal 2.0 m descent from rest | `v = 6.264183905346 m s⁻¹` | ±0.005 about 6.26 m s⁻¹ |

Additional checks cover static hold at 15°, limiting equality, signed uphill friction/stopping/reversal, timestep independence at 30/60/120 Hz, unequal/unreachable elevations, vector impulses, spring storage, work/energy, guide heat, invalid/nonfinite inputs and original DC calculations. Independent Python references include a +2 m descending projectile time of 1.790520091265 s and a 20% loss descent speed of 5.602856414366 m s⁻¹.

### Integration and tolerances

The runtime physics clock is fixed at **60 Hz**. Constant-acceleration intervals are integrated analytically, with exact stopping-time splits for friction. Payload movement is swept between successive analytic states. At contact, the incident state is truncated to the collision travel fraction; progression is driven by the actual collider.

The maximum projectile chord sag at g = 12 and 60 Hz is `gΔt²/8 ≈ 0.000417 m`, or 0.0267 world pixels. Observed unobstructed payload/prediction agreement is tested within 0.002 world px; incline contact distance within 0.003 m; energy incident speed within 0.01 m s⁻¹; energy balance within 1e-5 J and guide heat within 0.02 J. Numerical fixtures additionally use tighter unrounded tolerances. Scalar mathematics and Godot vector/collision precision are distinguished; no hidden success trajectory is substituted.

## Vector Sight, Codex and Scholar Mode

Vector Sight captures the selected apparatus before pausing the whole world. Velocity, time, forces, momentum and energy read from that snapshot. Resume restores ordinary processing without changing the measured velocity, replaying input edges or advancing combat timers during inspection. The inspection camera puts the object/diagram below the HUD. Force arrows distinguish weight, normal reaction, friction and resultant; the display labels **0.65 world px per N**. The resultant is identified as a sum, not another interaction force. Zero forces are not drawn.

All nine Codex entries contain explanation, equations, symbol definitions, SI units, assumptions, a worked example and the related discovery. Semester 1 and Semester 2 remain permanent identities. Existing syllabus codes are version metadata, and official learning-outcome alignment remains explicitly unverified because an authoritative curriculum specification is not bundled.

Scholar Mode copies exact apparatus parameters into deterministic local challenges. It accepts numerical rounding (absolute tolerance `max(0.01, 0.005 × |answer|)`), decimal comma and finite scientific notation, gives working/constructive feedback, and saves cosmetic archive seals. It never gates story progression or grants a mandatory combat advantage. There is no online question service or paid AI dependency.

## Browser defects fixed

### Missing scientific glyphs

Desktop system fallback fonts masked missing glyphs in the Web export. The resumed work audited actual font glyph maps, not just declared Unicode ranges. Installed Roboto, Ubuntu and local Noto candidates still lacked required characters. **DejaVu Sans** from the already installed Matplotlib package covers every non-ASCII Codex character and the required Greek, subscript, superscript, degree and operator glyphs.

The unmodified 756,072-byte font is bundled as an additional fallback; existing UI base text and Cinzel headings remain. Full Bitstream Vera/Arev redistribution notices and acquisition/hash details are included in every export. No blocked font-download command was retried. See [asset provenance](assets/ASSET_PROVENANCE.md), [font notice](assets/fonts/DejaVu-NOTICE.txt) and [license](assets/fonts/DejaVu-LICENSE.txt).

Godot's TextServer checks the bundled font's own character map without depending on system fallback. Rendered Codex equations, measurement panels and Scholar units were inspected. [Browser friction](artifacts/phase3-browser/06-friction-glyphs.png) shows θ, μ, subscripts, ≤ and the downward arrow; [reload evidence](artifacts/phase3-browser/04-codex-after-reload.png) shows correct SI superscripts and retained discoveries.

### Canvas/header clipping

The previous full-window resize policy sized the canvas to the entire browser height even though a separate header occupied space. The shell now uses policy **0**, a bounded flex container below the **44 px** header and safe-area padding, and a ResizeObserver that owns CSS/drawing-buffer dimensions. Canvas dimensions are integer 16:9 blocks, with uniform device-pixel scaling capped at 2 and nearest/pixelated world presentation. Wider screens letterbox the complete canvas. Fullscreen keeps an accessible exit button.

The final browser checks validate viewport/container bounds, aspect ratio and drawing-buffer scaling on desktop, wide resize, fullscreen, landscape touch emulation and restored desktop. Mobile notification placement also avoids the added gauntlet row. Screenshots show the complete floor/status area, readable interfaces and unobscured controls.

## Exact validation results

| Godot runner | Headless passed | Graphical passed |
| --- | ---: | ---: |
| Unit, repository, scientific and glyph checks | 181 | — |
| Existing scene integration | 28 | 31 |
| Existing action/combat/AI/input integration | 88 | 93 |
| Continuous original Citadel route | 6 | 6 |
| Existing Phase 2 presentation contracts | 74 | 74 |
| Research apparatus/UI/progression/reload/touch | 73 | 83 |
| Continuous live-AI research route | 11 | 11 |
| **Total** | **461** | **298** |

**759 passed, zero assertion failures.** Graphical differences include screenshot-save assertions. The original 474-assertion matrix is preserved within the expanded checks. The final complete wrapper passed; targeted research reruns additionally checked maximum-size touch controls. An intermittent pre-existing fast-test audio teardown warning was traced to mixer-held WAV/playback references. The combat test now waits 120 ms of actual wall time after node teardown, with successful headless/graphical reruns; gameplay audio code was unchanged.

Additional executed validation:

- **13** independent Python numerical/condition references passed.
- **6** Web-validator fixtures passed: valid export, missing JS, invalid WASM, modified PCK, oversized asset, stale manifest.
- **24** headless Edge assertions passed, including real WebAssembly/WebGL startup, canvas bounds/aspect/scaling, resize/fullscreen/touch capability and zero JavaScript exceptions/console errors.
- Browser keyboard/UI actions exercised laboratory unlock, Codex navigation, movement/jump/sword, pause and reload. Screenshots confirm **3/9 discoveries retained after reload**. This is automated browser evidence, not a human full-dungeon browser playthrough.
- Local HTTP checks passed all seven generated assets plus the manifest, expected MIME types/hashes and missing-asset 404 handling.
- Generated engine JavaScript and both audio worklets passed `node --check`.
- `vercel build --prod --yes --scope pek-explains-physics` completed locally; `.vercel/output/static` passed the same source/file-hash validator. No deployment was invoked.
- Windows packaged headless checks: **12 legacy + 13 research = 25 named conditions**, plus the overall export summary. Graphical package: **13 legacy + 14 research = 27 named conditions**, including captures. These counts are separate from the 759 Godot matrix.

Primary evidence: [full wrapper](artifacts/phase3-final-validation-console.log), [summary](artifacts/phase3-final-summary.json), [research checks](artifacts/research-tests.log), [rendered research checks](artifacts/graphical-research-tests.log), [research route](artifacts/graphical-research-route.log), [browser measurements](artifacts/phase3-browser/results.json), [HTTP verification](artifacts/phase3-final-http-validation.log), [Vercel local build](artifacts/vercel-phase3-final-build.log).

## Performance comparison

Windows Compatibility/OpenGL 3.3, NVIDIA GeForce MX250, driver reported as 511.69. Browser tests were closed for the continuous rendered native measurements.

| Run | Rendered FPS | Wall time | Mean process interval | p95 interval |
| --- | ---: | ---: | ---: | ---: |
| Historical Phase 2 report, Citadel route | 59.49 | 23.94 s | 20.033 ms | 31.344 ms |
| Preserved Phase 2 baseline rerun | 59.86 | 23.89 s | 17.815 ms | 23.359 ms |
| Earlier Phase 3 research samples | 59.78–59.91 | ~56 s | See prior logs | See prior logs |
| **Final Phase 3 research route** | **59.96** | **55.97 s** | **16.700 ms** | **17.763 ms** |
| Final original Citadel route | 59.92 | 23.88 s | 16.864 ms | 18.037 ms |

These short, vsync-limited runs show no material observed regression from the font/UI changes. They do not establish a statistically significant speedup or guarantee other hardware. Headless FPS is zero and is not a rendering measurement. Browser/mobile FPS and device heat/soak performance were not measured. Prediction caching, shared atlas/font resources, bounded effects and existing quality/reduced-motion settings remain in place.

## Final local builds

| Artifact | Result |
| --- | --- |
| [Windows debug executable](builds/windows/Aetheria.exe) | x86_64, unsigned, embedded PCK; **109,924,152 bytes** |
| Windows SHA-256 | `ff4394d95ae611b4181a84de2303f999a0af66e0a7af20f636e3395e61be56b1` |
| [Complete Web release](web/index.html) | Seven generated files retained together; **46,581,112 bytes / 44.42 MiB**, excluding manifest |
| Web PCK / WASM | **6,747,432 / 39,514,754 bytes** |
| Web source SHA-256 | `2f8ac2126d5f169c874c69a3f17c15d8f69f5e48ddb8ae30b9a6c2619da0c454` |
| Local preview | `http://127.0.0.1:8062/` while the supplied HTTP server remains running |
| Local Vercel output | `.vercel/output/static`, independently hash-verified |

Open the browser build over HTTP, not `file://`. Browser evidence used isolated **headless Edge 156.0.4314.42**, with a fresh test profile and no access to the user's normal browser data. IndexedDB saves remain origin/profile-specific. No production-origin persistence or live production build claim is made.

## Screenshots and gameplay evidence

Open the [local evidence gallery](artifacts/phase3-gallery.html) for 23 captures: ten native research states, twelve browser states and one packaged executable capture. Captures were visually inspected after the final fixes.

| Evidence | Link |
| --- | --- |
| Laboratory and story unlock | [Native laboratory](artifacts/phase3-screenshots/laboratory.png) |
| Captured velocity and proportional force arrows | [Vector Sight](artifacts/phase3-screenshots/vector-forces.png) |
| Launcher sliders | [Launcher controls](artifacts/phase3-screenshots/launcher-controls.png) |
| Physical impulse cargo and ability effect | [Impulse](artifacts/phase3-screenshots/impulse-cargo.png) |
| Potential/kinetic/thermal readouts | [Energy](artifacts/phase3-screenshots/energy-inspection.png) |
| Numerical working and SI units | [Scholar Mode](artifacts/phase3-screenshots/scholar-working.png) |
| Nine recovered entries | [Codex](artifacts/phase3-screenshots/codex.png) |
| Completed research exit | [Exit](artifacts/phase3-screenshots/research-complete.png) |
| Landscape controls and instrument | [Touch](artifacts/phase3-screenshots/touch-landscape.png), [instrument](artifacts/phase3-screenshots/touch-instrument.png) |
| Fixed Web symbols and saved discoveries | [Friction](artifacts/phase3-browser/06-friction-glyphs.png), [reload](artifacts/phase3-browser/04-codex-after-reload.png) |
| Browser resizing/fullscreen/touch | [Wide](artifacts/phase3-browser/08-wide-resize.png), [fullscreen](artifacts/phase3-browser/09-fullscreen.png), [landscape](artifacts/phase3-browser/10-landscape-touch.png) |
| Actual exported Windows package | [Packaged render](artifacts/phase3-packaged.png) |

Component captures stage repeatable positions. Continuous route logs separately prove ordinary-input completion with live AI. Neither automated route nor screenshot inspection is presented as a human fun/clarity evaluation.

## Saves, recovery and compatibility

`save_schema_version` remains **1**; snapshots use `content_version: phase3.0`. Existing application identity, legacy checkpoint IDs, collectibles and discoveries remain. New research checkpoints are `research_a` through `research_f`; progression IDs use `citadel.research.*`, journal IDs use `mechanics.*`.

Missing research data gives safe defaults for older saves. Vector/Impulse unlocks, completed chambers, research shard, Codex discoveries, Scholar seals, learning preference, controller/keyboard preferences and positive player health persist. Future-schema overwrite protection, backup recovery and temporary-file replacement remain covered. A corrupt/newer unreadable save is preserved rather than silently overwritten.

Unfinished experiments reload at a safe ready state with default parameters. Completed relays restore their gates/bridge colliders. Reset/respawn never removes acquired progress or consumes puzzle resources. Tests use unique isolated save files and remove only their own fixtures; normal user saves were not deleted.

## Remaining limitations and Phase 4 recommendations

1. **Human acceptance:** conduct first-time keyboard and browser playthroughs with action players and physics learners. Measure pacing, hint clarity, puzzle enjoyment and the intended action/physics balance. The 20–35 minute target remains unverified.
2. **Actual hardware:** native Android export/device testing, real mobile-browser multitouch, controller hardware, cutouts, soft-keyboard ergonomics, background/resume and thermal/soak tests remain unverified. No configured/detected Android SDK/build-tools or adb was found, and matching Android export templates are absent; the editor reports the missing build-tools directory. No APK/device certification is claimed.
3. **Independent scientific review:** a physics educator should review explanations, notation, idealizations and curriculum mapping before publication. Automated fixtures are evidence of consistency, not an independent syllabus audit.
4. **Apparatus scope:** the engine uses guided descent. Interactive pendulum/spring variants, detailed contact deformation/transfer, multiple-body collisions, rolling resistance and drag are future model extensions. The current assumptions are exposed in the Codex and instrument.
5. **Production polish:** extend encounter variety and environmental storytelling as playtests require; refine atlas pose continuity and repeated scenery, improve audio, add localization and broader accessibility/device testing. Preserve the approved art direction.
6. **Release gates:** validate an intended signed release build, physical target devices and a human full browser route before requesting release authorization. Production hosting remains unchanged.

## Files and reproduction

The [complete changed-file list](docs/PHASE_3_CHANGED_FILES.md) includes source, reusable scenes, local content, font/license notices, tests, export tooling, README and regenerated Web artifacts. Godot-generated UID companions are included. Local builds, screenshots, logs, browser profiles and Vercel output remain ignored by Git.

```powershell
.\tools\validate.ps1 -Capture
python .\tools\verify_physics_reference.py
.\tools\export_windows.ps1 -Graphical
.\tools\export_web.ps1
python .\tools\serve_web.py --port 8062
# In another terminal:
node .\tools\verify_web_export.mjs --url http://127.0.0.1:8062/
node .\tests\test_web_integrity.mjs
node .\tools\verify_browser.mjs http://127.0.0.1:8062/
vercel build --prod --yes --scope pek-explains-physics
node .\tools\verify_web_export.mjs --directory .vercel/output/static
```

The browser checker uses an installed Edge executable by default; `AETHERIA_BROWSER` can point to another installed compatible Chromium browser. It creates its own profile under `artifacts/`. **Leave this Phase 3 work local for the user's review; do not commit, push or deploy.**

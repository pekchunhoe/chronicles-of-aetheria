# Chronicles of Aetheria: The Broken Laws
## Game Design Document — Version 1.0 (11 October 2026)

**Status:** Proposed design, not implemented. **Working title:** subject to name/trademark clearance before publication.

**Genre:** Original 2D side-scrolling action-adventure RPG with interconnected dungeons and physics-powered exploration.  
**Platforms:** Windows PC and Android (one shared Godot project; platform-specific controls/UI).  
**Visual direction:** modern, detailed, original pixel art with parallax layers and restrained lighting.  
**Engine baseline:** Godot 4.7.2 stable, GDScript, version pinned for production.  
**Audience:** action-RPG fans aged ~13+, particularly Malaysian matriculation / pre-university physics learners.  
**Experience target:** roughly 60% action/exploration and 40% interactive physics puzzles/experiments; this varies by area.  
**Connectivity:** offline-first; no API, cloud account, or tokens required for gameplay.  
**Reference inspiration:** exploration, shops, combat, and progression associated with classic side-scrolling adventure games; all narrative, art, music, dialogue, world layouts, enemies, names, and code must be independently original.

## 1. Vision and non-negotiable design pillars
1. **Fun first:** running, jumping, fighting, exploring, upgrading and mastering bosses must be intrinsically satisfying.
2. **Physics as agency:** learn a law to overcome a believable environmental obstacle or exploit a combat mechanism, not as an unrelated quiz gate.
3. **Scientific integrity:** quantitative educational puzzles use real equations, SI units, documented approximations, consistent measurements and explicit assumptions.
4. **Accessibility:** an adventure path with visual clues, experimentation, hints and approachable timing; optional Scholar challenges deepen calculation.
5. **Cross-platform from week one:** Windows keyboard/controller and Android touchscreen; test both continuously.
6. **Maintainability:** separate engine combat physics, audited educational models, curriculum metadata, puzzle data and platform UI.
7. **Curriculum independence:** stable Semester 1/Semester 2 display identities, syllabus-version codes such as SP015/SP025 only as mappings; never hard-code fixed topic counts.

### Core loop
Explore hub -> choose route -> fight/traverse -> encounter physics situation -> observe/measure with Axiom Gauntlet -> hypothesize/predict -> adjust apparatus -> test -> receive immediate visual and numeric feedback -> advance/unlock/reward -> return to hub to upgrade and study discoveries.

## 2. World fiction and narrative
Aetheria's seven Axiom Engines power orbital bridges, mines, elevators, cities, resonators and enormous protective circuits. Their energy source, the Aether Core, was exploited beyond its designed safe capacity. The kingdom-wide control intelligence, the Null Sovereign, initiated an emergency shutdown; public records portray it as the destroyer of the civilization. Local control systems suffered damage and now produce dramatic field forces and dangerous machine behaviours, making nature *seem* broken, but conservation laws remain intact.

**Act I — The Discovery:** Salvager Kael finds the diagnostic Axiom Gauntlet in the ruins of a town observatory. It reveals forces, speeds and energies in machinery. Mechanist Mira repairs its first module. A mentor sends Kael into the Mechanical Citadel. The first crystal restores electricity to a village.

**Act II — The Fracture:** Across the remaining kingdoms, Kael encounters reactivated wardens, displaced people and the rival Oren, who wants immediate restoration. Recovered logbooks show the founding engineers ignored heat buildup, mechanical stress and energy losses. The Sovereign's shutdown may have been protective.

**Act III — The Choice:** At the Fractured Nexus, the team discovers a dangerous load imbalance in the old grid. Restoring all engines blindly would trigger failure. Kael uses evidence gathered through gameplay to redesign load sharing and choose a supported ending: distributed, safer reconstruction; or temporary partial restoration with unresolved costs. Avoid a simplistic right/wrong multiple-choice finale; each outcome has clear consequences.

### Character roster
| Character | Function | Personal conflict | Gameplay role |
|---|---|---|---|
| **Kael** | Playable salvage explorer | Brave but initially impatient with analysis | Sword, dodge, jumps, Axiom Gauntlet |
| **Mira Vey** | Mechanist ally | Her family helped build unreliable engines | Upgrades, tool crafting, accessible hints |
| **Dr. Senna Oris** | Physics archivist | Wishes to correct flawed scientific records | Codex, theory, worked examples |
| **Oren Vale** | Rival expedition leader | Believes rapid restoration outweighs careful testing | Recurring rival encounters and ethical contrast |
| **Nix** | Small nonhuman probe companion | Fragmented memory of pre-collapse network | Scanning, map clues, concise tutorial cues |
| **Null Sovereign** | Ancient control intelligence | Protects the world through severe, opaque intervention | Final opposing force; nuanced reveal |

## 3. World structure: seven kingdoms, not seven fixed syllabus chapters
| Region | Fantasy identity | Traversal/combat mechanics | Main conceptual anchors | Boss |
|---|---|---|---|---|
| 1. Mechanical Citadel | Industrial ruins, gears, elevators | forces, friction, projectiles, springs | measurements, vectors, kinematics, Newton's laws | Iron Warden |
| 2. Ember Forge | Heated foundries, waterfalls of molten metal | gravitational/spring energy, mechanical losses | work, energy, power, thermodynamics annex | Furnace Colossus |
| 3. Momentum Mines | Mines and rail transport | mine-cart coupling, recoil, impulses | momentum, collisions, deformation annex | Railbreaker Titan |
| 4. Celestial Spires | Floating sky machinery | swinging anchors, rotating disks and lifts | circular motion, rotation, gravitation | Orbit Sentinel |
| 5. Resonance Depths | Caverns and submerged research halls | wave timing, harmonic oscillators, optical paths | oscillations, waves, sound, optics annex | Echo Leviathan |
| 6. Storm Dominion | Lightning towers and coil installations | circuits, charge storage, electromagnetic machinery | electrostatics, capacitors, DC, magnetism, induction, AC | Thunder Wyrm |
| 7. Fractured Nexus | Core of energy network | interconnected mechanics/electrical/thermal systems | integrative reasoning; modern physics via archives/labs | Null Sovereign |

**Topic coverage rule:** seven regions are narrative categories, not a declaration that the syllabus has seven chapters. Add dedicated optional laboratories and study terminals for heat, gases, thermal expansion, deformation, optics, quantization, waves of matter and nuclear/particle physics. Do not fabricate a direct gameplay analogy when physics is quantum or nuclear; clearly label imaginative elements.

### Hub: Ashbridge Village
- Quest board, map, repair bench, merchants, equipment comparison, laboratory archive, training arena, checkpoint portal.
- NPC conversation reflects restored engine states and player discoveries.
- Return paths reveal shortcuts when new Gauntlet powers unlock.
- No stamina or currency penalty for experimenting with puzzles.

## 4. Mechanics: action, physics and progression
### Core movement
Responsive walking, sprint, variable-height jump, coyote-time, jump buffering, short air correction, ladders, ledge interactions; later air dash and tether swing. Character controller must be consistent at fixed update rates and usable with touchscreen input. Game-scale movement can be tuned for fun; it is not itself a graded physical simulation.

### Combat
- Light/heavy melee combo, dash/dodge, guard/parry, short-range tool attack.
- Enemy classes: crawler, archer turret, shield sentry, shock drone, heavy golem, mobile boss.
- Tell before attack, distinct collision layer, fair invincibility frames, accessibility settings.
- Weapon tiers upgrade damage/reach/animations; armour mitigates damage; Gauntlet module upgrades add interactions.
- Bosses alternate action phases and one or two physically motivated system interactions. Never force equation input during high-pressure combat; time pauses in Scholar overlays.

### Axiom Gauntlet tools
| Tool | Start/upgrade | Mechanic | Science guarantee |
|---|---|---|---|
| Vector Sight | Starting tool | freeze/slow observation, show motion arrows and measured quantities | directions/scales/units reflect simulation or model state |
| Impulse Strike | Kingdom 3 | pushes or stops selected objects | impulse `J = Δp`; `Δv = J/m` for modeled collisions |
| Kinetic Leap | Kingdom 2 | launcher and spring interaction | potential to kinetic with losses specified |
| Gravity Anchor | Kingdom 4 | hook tether to approved mounts | centripetal acceleration and tension consistent in dedicated challenges |
| Resonance Pulse | Kingdom 5 | tune oscillator to machinery frequency | distinguish resonance response from energy creation |
| Magnetic Grip | Kingdom 6 | operate designated magnetic loads | actual magnetic machinery with an explicit power/field source |
| Circuit Link | Kingdom 6 | place wired components in sockets | Kirchhoff/Ohm checks in puzzle models; no arbitrary circuit animations |

**Resource design:** Gauntlet power cells recharge by world machinery/checkpoints; no battery drain during explanatory overlays. Experiments should be retryable at no cost.

### Difficulty and learning modes
**Adventure:** no compulsory typed math; graphical meters, previews, gradual hint tiers and broad success tolerances where educational intent allows.  
**Scholar:** optional numeric calculations with answer tolerance, equations, SI units, feedback and worked solutions; can activate per puzzle; not a separate campaign.  
**Accessibility:** adjustable combat difficulty independent of physics challenge settings; optional aim assist/touch button layout, font scale, reduced flashing, remapping, color-independent indicators, and pause during calculations.

### XP and economy
XP from quests/combat/exploration; Axiom knowledge points from discoveries rather than repeated rote grinding. Currency buys gear and cosmetics, not exam answers. No premium currency, gambling loot boxes, forced login or pay-to-win.

## 5. Worked mission: the Iron Warden
**Goal:** restore a broken mechanical lift and defeat its defensive guardian in a ~20–30 minute early dungeon.

1. Kael arrives at a locked entrance and fights two machine crawlers. He discovers a blocked workshop.
2. Vector Sight reveals a crate of 10.0 kg on a ramp inclined at 30.0° with kinetic friction coefficient 0.20. The effective motion model is disclosed as *sliding down the ramp with constant kinetic friction; neglect air resistance*. Player may adjust a gate and place the crate.
3. The crate moves downward. Expected acceleration: `a = g(sin θ − μ_k cos θ) = 9.81[0.500 − 0.20(0.866)] = 3.21 m/s²`. If released from rest and allowed to travel 6.0 m, expected `v = √(2as) ≈ 6.27 m/s`. A weighted flywheel mechanism turns if the cart/crate arrives above the designated threshold; the game visualizes speed on impact. Values are fictional puzzle conditions, not a claim about free-body forces of any complex cart assembly.
4. The lift moves; Kael reaches a temporary checkpoint and is shown an optional annotated free-body diagram in the Codex (only if the player opens that study view).
5. Warden Phase 1: normal sword/dodge combat. Phase 2: a suspended wrecking ball can be released from height `h = 2.0 m`, initially at rest. In a clearly labeled idealized model with negligible air resistance and pivot losses, `mgh = ½mv²`, so `v = √(2gh) ≈ 6.26 m/s` at its lowest point. Releasing it at the correct time damages the armour.
6. Warden Phase 3: sword finish. Kael obtains the first crystal and a partial archival log exposing unreliable safety tests.
7. Completion shows summary: forces, friction, kinetic energy, conservation assumptions, personal best/optional Scholar outcomes; no grades broadcast to external servers.

**Failure design:** mistakes reset only the apparatus or latest checkpoint, do not delete items or punish misconceptions. Layered hints: (1) observe motion (2) highlight forces/equations (3) offer guided setup (4) show solved explanation after repeated attempts. Completion accessible in Adventure without tedious numeric entry.

### Second sample: projectile crossing
Ideal same-height launch, no air drag: `R = (u² sin 2θ)/g`. With `u = 14.0 m/s`, `θ = 45°`, `g = 9.81 m/s²`, `R ≈ 19.98 m`. Target center 20.0 m away with declared tolerance permitting 19.98 m; ensure collisions and scene geometry actually match equation. Show time of flight if Scholar requests: `t = 2u sinθ/g ≈ 2.02 s`. A failed launch should return the character safely to the launcher, not cause a long reset.

### Third sample: boss electrical shield
A machine rated for target current `2.0 A` receives regulated potential difference `12.0 V`. Equivalent resistance must be `R = V/I = 6.0 Ω`. Real puzzle slots accept components that yield the target total resistance, including correct series/parallel options if stage is advanced. UI labels source, resistance and current, and validates circuit topology; avoid short-circuit mechanisms that teach wrong DC behavior.

## 6. Educational system
### Learning workflow
**Notice -> Measure -> Predict -> Manipulate -> Observe -> Explain -> Transfer.** A concept is recognized only after a valid interaction; success can occur in Adventure through discovery; Scholar offers optional problem solving with numeric feedback.

### Syllabus mapping model
Fixed UI semester identities: **Semester 1** and **Semester 2**. Curriculum *versions* own one or more codes (e.g., SP015, SP025) and any number of chapters/topics/subtopics with explicit ordering. `concept_id` is globally stable in game; curricula map to concepts using versioned records. Changing official syllabus does not invalidate old saves.

Example data (illustrative only):
```json
{
  "concept_id": "physics.mechanics.linear_motion.projectile_range",
  "display_name": "Projectile motion on level ground",
  "quantities": ["u_m_per_s", "theta_deg", "g_m_per_s2", "range_m"],
  "learning_objective": "Predict horizontal range under constant downward gravitational acceleration without air resistance",
  "model_id": "ideal_projectile_v1",
  "assumptions": ["same launch and landing height", "uniform g", "negligible drag"],
  "puzzle_ids": ["citadel.bridge_launcher.01"],
  "curriculum_mappings": [
    {"version": "EXAMPLE_VERSION", "semester": "Semester 1", "syllabus_code": "SP015", "topic_id": "TO_BE_MAPPED"}
  ]
}
```
Replace EXAMPLE_VERSION/TO_BE_MAPPED with authoritative curriculum records after syllabus audit. Do **not** claim exact current alignment from incomplete or outdated third-party topic lists. Allow multiple mappings across versions.

### Codex (in-game journal)
For every concept: title, discoverable physical phenomenon, measurement log, diagram **only when explicitly chosen in this game educational UI**, LaTeX/MathML-rendered equation, symbol definitions, assumptions, one worked answer, common misconception, optional practice challenge, per-curriculum tags. This game's educational Codex may have interactive diagrams as part of deliberately designed gameplay; do not infer blanket permission to add diagrams to the user's separate Physics Question Generator project.

### Question-bank integration (future, separate module)
- Initial version: hand-authored offline local content only, versioned JSON or Godot Resources.
- Later: optional import of reviewed JSON question-bank content with stable IDs, licensing/permission checks, sanitization, schema validation, local caching and syllabus-version mapping.
- No direct runtime queries to a write-capable Turso database; never ship database admin/write tokens in app.
- No LLM/API dependency for real-time questions, mathematical checking or PDF generation.
- Any external educational question shown in the game is a bonus quest, not a mandatory combat gate.

## 7. Quantitative correctness and tests
**Two-model principle:** arcade platformer physics may prioritize responsive feel, whereas graded educational puzzles use a verified SI-unit model. Each puzzle explicitly declares when it uses an idealization rather than full rigid-body numerical physics.

**Scale:** design coordinate conversion, e.g. 64 world pixels = 1 m for puzzle scenes. Represent calculations in SI internally; convert for sprites/cameras only. Physics actions have fixed-step updates and bounded numeric precision. Rendering is interpolated independently of physics steps when available.

**Scientific test fixtures:**
- Projectile: `14 m/s`, `45°`, `g = 9.81`, `R ≈ 19.98 m`, tolerance declared.
- Ramp: `θ = 30°`, `μ_k = .20`, `g = 9.81`, `a ≈ 3.21 m/s²` down plane, in a sliding state.
- Energy: `h = 2.0 m`, zero initial velocity, negligible dissipation -> `v ≈ 6.26 m/s`.
- Electrical: `12 V / 6 Ω = 2 A`.
- Momentum: total momentum before = after for closed collision model, with kinetic energy separately tested for collision type.
- Rigid motion: correctly distinguish angular from linear quantity and rad/s from rpm.
- Thermal and electrical models: assert conservation and boundary conditions in separate fixtures.

**Guardrails:** make world arrows agree with sign convention; define positive direction, zero reference, SI units and significant figures in Scholar; use correct vector notation, no phantom forces in free-body diagrams, no incorrect electrical series/parallel shortcuts. Have physics content independently reviewed before release.

## 8. UI/UX and art direction
### Visual specification
- Internal game-world viewport target **640 x 360** (16:9), pixel-art tiles typically 32 x 32 reference pixels; sprite sizes vary.
- Source art should be purpose-made, detailed, with coherent palette per region; foreground characters remain readable over backgrounds.
- Layered parallax, light shafts, atmosphere and subtle shader glow, with low-end Android fallback.
- Rich scenery without relying on photorealistic sprites; readable silhouettes and telegraphed hazards.
- Do not use Zeliard sprites, audio, level layouts, names or copyrighted character designs; use uniquely made art/audio.
- Math overlays should be high-resolution vector text/UI, not blurry pixel font. Support localized English/Bahasa Melayu text; translations reviewed by educators.

### Windows controls (proposed)
| Action | Keyboard | Controller |
|---|---|---|
| Move | A/D or arrows | left stick/D-pad |
| Jump | Space | A / Cross |
| Attack | J | X / Square |
| Heavy attack | K | Y / Triangle |
| Dodge | Shift | B / Circle |
| Interact | E | shoulder/context button |
| Vector Sight | Q | left trigger |
| Gauntlet tool | R | right trigger |
| Inventory/Codex | Tab | menu/select |

Remapping required; avoid making default PC binds essential to levels.

### Android controls
Landscape orientation; left virtual stick; right jump/attack/dodge/interact/gauntlet; configurable positions, size and opacity; tap targets safe from notches/insets; touch sliders/dials for physics apparatus; on-screen math keyboard only in optional Scholar input; controller supported on Android where possible. Pause/resume must preserve puzzle state across calls/app backgrounding.

## 9. Technical architecture
**Baseline:** Pin Godot 4.7.2 stable and matching exports, use GDScript. Avoid unstable Godot 4.8 snapshots and engine upgrades mid-sprint without regression checks. Android exports are supported, but mobile tests are mandatory.

```text
project.godot
addons/                     # only vetted dependencies
assets/
  characters/ enemies/ tilesets/ backgrounds/ ui/ audio/
scenes/
  boot/ hub/ regions/citadel/ combat/ ui/ experiments/
scripts/
  core/                      # game state, events, saving, settings
  player/                    # character controller and gauntlet
  enemies/ combat/
  physics_models/            # independently tested SI math
  puzzle_runtime/            # interactions and accepted bounds
  curriculum/                # concepts, dynamic mappings
  platform/                  # input adapter, resolution, resume
content/
  game_data/ concepts/ puzzles/ curricula/ localization/
tests/
  unit/ integration/ playtests/
export_presets.cfg
```

**Key interfaces:** `PhysicsModel` accepts named inputs in SI and returns expected state with assumptions, unit metadata and tolerances; `PuzzleController` translates the physical outcome to success/fail and signals the world; `GauntletScanner` displays known state; `ConceptRepository` resolves curriculum labels; `InputAdapter` unifies keys/controller/touch; `SaveRepository` writes versioned user data atomically with backup/recovery. Stage content is declarative, never `eval` arbitrary user-provided code.

**Performance targets:** design for stable 60 fps on a selected midrange Android test phone and typical Windows PC (30 fps optional fallback with physics timestep maintained). Targets are goals to verify, not claims about unspecified hardware. Texture atlases, draw-call budgeting, low-cost lighting, culling and audio streaming; performance profiling on actual devices. Start Android builds during first month, not at the end.

**Save data:** separate `save_schema_version` and `content_version`, track checkpoint, unlock flags, collected crystals, equipment, puzzle state, discoveries, mode choices and control preferences; tolerate old curriculum mappings and provide migrations with backup. Local/offline by default; later cloud sync optional with explicit consent.

**Security/privacy:** no student accounts in MVP; no personal academic data transmitted; no hard-coded write credentials; sanitize imported content; keep dependencies licensed, avoid embedding proprietary question-bank contents without rights.

## 10. Vertical slice specification (first release gate)
**Playable scope:** Ashbridge village (small area), Mechanical Citadel (one branching dungeon ~20–30 minutes), 2 basic enemy types, 1 boss (Iron Warden), 2 integrated physics puzzles (ramp/friction and mechanical energy), Vector Sight, shops/one upgrade, a checkpoint/save, Codex entries and completion feedback.

**Required acceptance gates:**
- Start-to-finish possible on Windows keyboard and controller and actual Android touchscreen.
- Movement/combat responsive; no softlocks; recovery on death and failed experiments.
- Scientific fixtures pass with specified numeric tolerances; apparatus visuals agree with model.
- Both learning modes complete identical story; text readable on a 6-inch Android display.
- 30-60 minute soak on selected Android test hardware without crashes or excessive heat.
- Save persists through quit/resume/app background, and controls accommodate screen insets.
- No network access necessary after installation.

**Explicitly postponed:** 6 further kingdoms, multiplayer, online leaderboards, auto-generated AI questions, question-bank synchronization, cloud saves, extra locales and game-store publishing.

## 11. Development roadmap (approximate; adjust after first prototype)
| Phase | Weeks (rough estimate) | Deliverables | Go/no-go check |
|---|---|---|---|
| 0. Foundations | 1–2 | Git repo, GDD, Godot pinned, CI/headless boot, placeholder PC + Android project | Starts without errors on Windows & device |
| 1. Action prototype | 3–5 | Player movement, enemy AI, melee, camera, damage, simple platform room | Both input schemes playable; 60-fps target profiled |
| 2. Verified physics | 6–8 | PhysicsModel tests, ramp, launcher/energy puzzle, Vector Sight, HUD | Outputs match independent calculations and displayed motion |
| 3. Vertical-slice content | 9–12 | Town, dungeon, Iron Warden, checkpoints, Codex, upgrade | A new tester finishes the loop without guidance |
| 4. Cross-platform polish | 13–16 | Touch ergonomics, performance optimization, save migration, audio, accessibility | Android 30-60 min stability and regression suite passes |
| 5. Pilot / iterate | 17–20 | Playtest with game players and matriculation students; fix priorities | Action fun and learning comprehension measured independently |
| 6. Full production | After gate | Remaining kingdoms and systems, content authoring, external review | Scope/budget reapproved per kingdom |

Timelines assume steady solo/very-small-team work with Codex assistance and ready access to original art; art/audio and device issues can extend the schedule substantially. The first vertical slice may take 4–6 months, not necessarily the full seven-kingdom game.

### Definition of done, per kingdom
1. Narrative beats, original visuals, enemy roster and one meaningful boss.
2. At least two integrated, observable physics mechanics and one optional Scholar challenge.
3. Equations/assumptions independently tested and reviewed.
4. PC + Android runs; large/small landscape aspect-ratio safe areas; save checkpoint.
5. Playtesting shows challenge clarity, no softlocks and meaningful feedback.

## 12. Risks and mitigations
| Risk | Mitigation |
|---|---|
| Massive scope from 7 kingdoms | Prove one 20–30 minute dungeon before mass asset creation |
| Physics feels like homework | Player action first; equations optional until Scholar overlay |
| Arcade engine contradicts equations | Separate audited SI models from platformer motion; communicate idealizations |
| Android interface too crowded | Input UX validated from week one; editable button arrangement |
| Pixel art too expensive | Graybox levels first; reusable tilesets and curated palettes |
| Syllabus changes | Stable concepts and semester identities, versioned curriculum adapters |
| Wrong mathematical solutions | Independent fixtures, teacher content review, unit/sign checks |
| Copyright/confusion with inspirations | Entirely original world, art, enemy types, level geometry and music |
| Question-bank integration security | Offline hand-authored MVP; read-only optional imports and never ship admin tokens |

## 13. Next Codex task (strictly phase 0, not entire game)
**Goal:** inspect current folder, then scaffold a runnable Godot 4.7.2 GDScript project, cross-platform baseline and tests with clear report, without inventing finished features. Initial scene: a simple graybox room and controllable placeholder player, dummy UI overlays that compile, keyboard + touch input setup (actual Android device smoke test where the environment supports it), and explicit milestones in docs.

**Codex implementation rules:**
1. Audit existing files and `AGENTS.md` before editing; preserve unrelated work.
2. Implement minimal, modular code, not the seven kingdoms at once.
3. Keep physics educational logic independent of pixel art and engine collision code.
4. Add simple headless tests for projectile, friction ramp, energy and DC circuit equations with SI units and given numeric fixtures.
5. Implement platform input abstraction and a touch-control test scene.
6. Add Windows and Android export presets, but report missing SDK/keystore/export templates honestly; do not claim APK exists without actual successful build.
7. Provide setup instructions, validation report, next development tasks and known gaps.
8. Do not add AI APIs, backend, authentication, online features or proprietary Zeliard content.
9. Avoid committing secrets, credentials or signing keys; no commit/push without explicit approval.
10. Return actual tests and smoke-test results, not unverified success claims.

## Reference and source notes
- Godot stable release archive: https://godotengine.org/download/archive/ (4.7.2 stable released 18 Aug 2026).
- Godot 4.7 Android export guidance: https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html
- Godot 4.7 Windows/export guidance: https://docs.godotengine.org/en/4.7/tutorials/export/exporting_projects.html
- 2026/27 tutorial topic outline from Kolej Matrikulasi Johor: https://sites.google.com/moe-dl.edu.my/physicsunitkmj/sds/physics-1-sp015/tutorial-sp015
- The precise authoritative curriculum specification must be obtained and reviewed before claiming exhaustive SP015/SP025 learning-outcome alignment.

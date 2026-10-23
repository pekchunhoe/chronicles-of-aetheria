# CODEX TASK — AETHERIA PHYSICS ACTION RPG: PHASE 0 FOUNDATION ONLY

Read `Aetheria_Physics_Action_RPG_GDD_v1.md` in full. Treat its proposed design and scope limits as requirements, but inspect the repository first; existing project conventions and `AGENTS.md` take precedence where they don't contradict explicitly approved goals.

Build ONLY a clean, runnable **Godot 4.7.2 stable + GDScript** foundation for an original 2D PC/Android physics-powered action adventure. Do not attempt to build seven kingdoms, a polished combat game, or a curriculum backend.

## Required implementation
1. Inspect existing files, Git status, `AGENTS.md`, README and existing assets, and explain safe changes.
2. Initialize or adapt the Godot project with a 640 x 360 pixel-art world viewport, scalable readable UI and configurable input mapping. Add one graybox room, placeholder player, platform, checkpoint and camera. Ensure movement, jumping and pausing work on desktop.
3. Add an input adapter designed for keyboard, controller and Android touch. Add an actual touch overlay scene and safe-area-aware layout. Do not assert Android compatibility without a device/export test.
4. Create minimal modules for SaveRepository, ConceptRepository, PuzzleController, PhysicsModel and GauntletScanner, with unit-safe interfaces and no invented backend.
5. Implement and TEST an independent numerical physics module with g=9.81 m/s²: projectile range 14 m/s at 45° on level ground (~19.98 m), ramp acceleration at 30° and μ=0.20 (~3.21 m/s²), ideal falling 2 m energy conversion (~6.26 m/s), and 12 V across 6 Ω (2 A). Specify assumptions, tolerances and units in the tests.
6. Create a sample data-driven physics puzzle definition, one concept metadata record and a versioned curriculum mapping. Store Semester 1 and Semester 2 as fixed display identities; treat SP015/SP025 as replaceable syllabus codes. Make no assumption of a fixed topic count.
7. Set up matching Windows/Android export presets and document toolchain prerequisites. Attempt actual export/smoke tests only when SDK/templates are installed; otherwise report exactly what remains unverified. Avoid Google Play publishing, signing key creation or cloud features.
8. Add a clean README and `PHASE_0_VALIDATION_REPORT.md` detailing implemented features, files changed, commands/tests run, pass/fail and unresolved issues.

## Constraints
- No third-party Zeliard art/audio/story/text or copied level layouts; all artwork may initially be placeholders.
- No AI API, cloud calls, DB credentials, authentication, tokens or synchronization. Offline-first.
- No educational diagrams generated automatically for the user's separate question-bank project.
- Consistency between UI measurements and physics model is essential; gameplay movement feel may be tuned separately from graded numerical models.
- Don't stage, commit, push, deploy or publish without explicit approval.
- Respect existing repository content; do not overwrite unrelated work.
- Keep scope small and verify all claimed outcomes.

## Acceptance criteria
- Godot opens the project without errors; graybox room can be played using keyboard.
- Tests for all four numerical fixtures pass.
- Initial touch-control scene renders and responds; record whether it was verified on actual Android hardware.
- Windows export works if templates are present, and Android export status is reported accurately.
- Files are modular and include clear instructions for starting Phase 1.

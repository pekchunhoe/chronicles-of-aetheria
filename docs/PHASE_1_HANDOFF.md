# Phase 1 handoff

## First development steps

1. Open the project with the pinned standard Godot 4.7.2 engine and run `tools/validate.ps1 -Capture`. Inspect the room, bench, touch and pause screenshots. Preserve the independent SI fixtures when tuning the arcade player.
2. Complete the Android prerequisite/device gate below before adding more content. Record a device model, OS, screen insets and exact engine/template version in the validation report.
3. Refine movement and touchscreen ergonomics with actual players. Add configurable touch positions and controller remapping as needed. Profile the selected Windows/Android hardware before making frame-rate claims.
4. Introduce one basic enemy, melee/damage feedback and a small camera/combat room. Keep combat settings separate from physics challenge settings. Keep the seven-region campaign outside this prototype.
5. Promote one reviewed numerical definition into a physical apparatus. Convert metres to pixels through `PhysicsModel`, document positive direction/reference height, and test geometry and displayed measurements against the model. The graybox pit is not the 20 m projectile fixture.
6. Audit the authoritative curriculum before replacing the illustrative mapping. Keep stable concept IDs and fixed semester display identities; a changed syllabus code must not invalidate old saves.
7. Add save schema migrations with fixtures for old, corrupt and newer saves. No schema older than 1 is supported yet.

## Android prerequisite and device gate

- Install complete matching 4.7.2 export templates and the SDK/JDK packages described in the README. Configure editor paths and an existing local debug signing identity. Keep signing material out of the repository.
- Export the Android preset to an APK. Record its command, output, path/hash and warnings; install on the chosen landscape device.
- Verify simultaneous stick + jump, drag outside/release, pause/menu touch, controller if present, and key/touch combinations. Desktop synthetic events do not establish device input behavior.
- Verify notch/navigation-bar safe areas, 16:9 and wider landscape screens, minimum/maximum touch size and opacity, readable text and reachable pause controls. Confirm the overlay does not hide the player or overlap itself.
- Reach the checkpoint, fall, restart and relaunch. Validate the saved checkpoint, preferences, model solve and discovery. Interrupt/resume/background the app; verify it returns paused without losing state.
- Confirm offline play and no Internet permission. Profile frame time, memory and heat on that named device; do not infer 60 fps from the fixed 60 Hz physics tick.

## Deliberately outside the foundation

Combat/enemies/bosses, NPCs/shops, a dungeon, finished art/audio, full Codex study views, localization review, physical ramp/launcher/energy apparatus, exhaustive curricula, release builds, Android certification, device soak tests, accessibility polish and performance targets remain future work. CI has a workflow definition but no hosted execution yet. No cloud/backend/question-bank integration or store publishing is part of this handoff.

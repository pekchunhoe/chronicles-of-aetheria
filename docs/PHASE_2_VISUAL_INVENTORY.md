# Phase 2 visual inventory and art direction

Baseline: clean `main`, `62efe3d` (Complete Phase 1 - Combat, Enemies and Dungeon). This inventory was written before visual implementation. The user's nine manual Phase 1 browser checks are accepted as user-provided evidence; the Phase 1 report remains a historical record.

## Replace and preserve

| Existing presentation | Planned treatment | Gameplay boundary |
| --- | --- | --- |
| Kael: beige/white rectangles and line sword in `_draw()` | Original brown-haired salvager, weathered traveling armour, teal Axiom gauntlet and ochre scarf; expressive sprite atlas | Same 18 x 28 collision, facing and authoritative combat/dodge times |
| Crawler: orange block, line legs, simple eye | Segmented bronze machine, articulated legs, luminous core, anticipation/hurt/destruction poses | Same AI, health, edge probes, attack range and collider |
| Turret: rectangle base and line barrel | Dark iron/bronze pedestal, aiming assembly, targeting crystal, charge/fire/destruction presentation | Same permitted arc, locked aim, projectile spawn and timing |
| Gray grid, flat blocks and pillars | Modular stone/metal terrain, carved supports, pipes, chains, collapsed machinery, inscriptions and debris | Preserve all platform rectangles and paths |
| Flat background | Distant cavern/ruin panorama plus separately repeated architecture, mechanical silhouettes and foreground details | Decorative layers have no collision |
| Flag checkpoints and diamond shard | Axiom pedestal/crystal activation states, animated fragment and pickup burst | Preserve stable checkpoint/reward IDs and collection persistence |
| Mint rectangle exit | Ancient mechanical gateway and restrained Axiom core | Same trigger and completion rules; player remains readable |
| Line swings, circles and seven-line impacts | Timed directional trails, sharp sparks, heavy impact, dust, afterimages and destruction | Effects follow actual attack/damage events; no damage or invulnerability changes |
| Generic rounded UI and permanent long control string | Dark iron framing, restrained bronze trim, teal accents, readable health/ability/shard hierarchy, refined pause/settings | Preserve remapping, save, bench, touch settings, focus navigation and pause |
| Flat touch controls | Cohesive outlined action buttons and stick, clear pressed states | Same finger ownership, dimensions, safe areas and shared actions |

## Art direction

Original dark fantasy industrial ruins: deep navy/charcoal, desaturated slate, oxidized bronze, restrained teal Axiom energy, amber lamps and small coral danger accents. Characters and collision edges receive the strongest value contrast. Decorative detail is secondary to attack tells and traversal.

World resolution remains 640 x 360. Terrain uses a 32-pixel module with cropped 12/16-pixel platforms. Sprite masters use a uniform atlas grid, nearest filtering, disabled mipmaps and clipped atlas regions. Camera presentation snaps to the world pixel grid; UI text remains high-resolution. Non-integer windows retain nearest-filtered scaling rather than blurry textures.

Original project-specific generated raster masters, exact prompts, atlas layouts and provenance will be retained locally in the project. Any external font must carry its redistribution license and source. Generated imagery will be inspected in the actual game; unpolished frames or assets will be identified honestly in the final report.

## Validation and evidence

Fresh baseline captures are copied to `artifacts/phase2-before/` before editing presentation. Matching after captures will cover combat, turret, relay/touch, completion and pause. Existing physics/gameplay suites, scene geometry, save compatibility, Windows package checks and Web integrity/local Vercel build remain required. Added visual tests will check resources, animation coverage, timeline/facing alignment, quality preferences and UI layouts. Actual browser/device tests will be distinguished from native rendering and HTTP checks.

No new powers, scientific apparatus, enemy types, regions, story chapters or gameplay rules are in scope. All work stays local and uncommitted.

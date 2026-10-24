# Phase 2 asset provenance

Created locally on 2026-10-24 for Chronicles of Aetheria. The four raster masters were generated specifically for this project with Codex's built-in image generation tool, from original character, machine and citadel descriptions. No commercial game artwork or reference image was supplied. These are AI-assisted assets, not a claim of hand-drawn animation.

| Asset | Actual master | Use |
| --- | --- | --- |
| `characters/kael_atlas.png` | 1254 x 1254 RGBA, 64 measured regions | Kael's 14 animation states |
| `enemies/machines_atlas.png` | 1254 x 1254 RGBA, 64 measured regions | Crawler, articulated turret, projectiles and effect accents |
| `environment/citadel_atlas.png` | 1254 x 1254 RGBA, 64 measured regions | Stone/metal modules, props, interactives, HUD icons, sword effects |
| `backgrounds/citadel_depths.png` | 1536 x 1024 | Distant vault architecture |

The original prompts are preserved verbatim in [source/generation_prompts.json](source/generation_prompts.json). The tool did not expose a model version, seed or stable public asset URL. Generated dimensions and gutters differ from the requested exact grid; runtime uses measured alpha bounds, explicit row bands and foot/barrel pivots from [source/atlas_layout.json](source/atlas_layout.json). `tools/build_art_metadata.gd` rebuilds that metadata without changing image pixels. The raster masters are preserved unchanged. No Python image editing or external AI API was used.

Characters use a virtual 192 x 192 frame at 0.25 scale: a 48 x 48 world-pixel canvas, with the visible standing body approximately 26-36 pixels tall. Foot positions are normalized to the existing actor bodies. Terrain is drawn in 32 x 32 modules, with cropped final modules matching the original collision rectangles. Images use nearest filtering and clipped atlas sampling; no mipmaps, pixel blur or full-screen postprocessing is added.

The art direction uses deep navy/slate, patinated bronze, ochre cloth, jade Axiom energy and amber hazards. Generated pose silhouettes and material details vary somewhat between frames. A hand cleanup and dedicated animation pass would improve consistent pixel clusters, weapon continuity and loop cadence. This limitation is recorded rather than describing the output as hand-polished production animation.

## External font

`fonts/Cinzel.ttf` is the official Cinzel variable font, downloaded from the [Google Fonts Cinzel directory](https://github.com/google/fonts/tree/main/ofl/cinzel), file `Cinzel[wght].ttf`. Copyright 2020 The Cinzel Project Authors, [upstream project](https://github.com/NDISCOVER/Cinzel). It is distributed under the SIL Open Font License 1.1; the complete license is retained in [fonts/OFL.txt](fonts/OFL.txt) and included in exports. The font is bundled locally, with no runtime download or system installation.

Existing Godot fallback UI/body text and the original synthesized Phase 1 audio are retained. New theme borders, health bars, aim indicators, bounded particle motion, camera tracking and the small hit-flash shader are original project code. There are no other external asset packs or runtime dependencies.

## Phase 3 scientific glyph supplement

`fonts/DejaVuSans.ttf` supplements the existing UI base font for missing Unicode glyphs. It was copied unmodified from the already installed Matplotlib font package, avoiding the blocked font-download operation. Its accompanying license permits redistribution with the required notices. Godot's own font character map verified the actual scientific glyphs; candidate Roboto, Ubuntu and local Noto fonts lacked some required subscript/superscript characters.

The full Bitstream Vera and Arev notices are in [DejaVu-LICENSE.txt](fonts/DejaVu-LICENSE.txt); DejaVu changes are public domain. Acquisition details and verification are in [DejaVu-NOTICE.txt](fonts/DejaVu-NOTICE.txt). Both notices are included in all exports. Godot tests inspect the bundled font's own character map for all non-ASCII Codex characters, Greek letters, SI superscripts/subscripts, degree signs and operators. Windows and Web screenshots verify the resulting text. Cinzel, all original raster masters, metadata, shaders and animation resources remain unchanged.

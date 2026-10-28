# Brain Quest — Production direction (Godot 4)

## Product standard
The previous 7x7 cube maze is a technical smoke test, NOT an acceptable game release. Build a polished, original mobile-first 3D puzzle adventure. Never present a successful export as proof of visual or gameplay quality.

## Inspiration (mechanics only; no copying protected art, level layouts, characters, music or branding)
- Monument Valley: strong visual composition and spatial revelation.
- The Room: tactile object interactions, layered mechanisms and satisfying feedback.
- Portal: teach a rule safely, combine rules, then subvert expectations.
- Captain Toad: compact readable dioramas, camera clarity and discovery.

## First vertical slice: The Sunken Observatory
Landscape, third-person isometric exploration with animated robot Pip, one visually cohesive environment and 3 interdependent puzzles:
1. Rotate a three-ring stone dial to align light channels (clear visual feedback).
2. Redirect a beam with two rotatable mirrors onto a receiver; receiver powers bridge.
3. Move a stone weight onto a pressure plate to open the final observatory gate.
Finish with an animated gate, short celebration, rating based on optional discoveries (not speed), and unlock screen.

## Required architecture
- scenes/levels/observatory.tscn: authored level with composition, collision and navigation.
- scenes/characters/pip.tscn and scripts/characters/pip_controller.gd: CharacterBody3D, AnimationTree, camera-relative movement and interactions.
- scripts/puzzles/rotary_dial.gd, light_beam.gd, mirror.gd, pressure_plate.gd: reusable signals, reset states and visual/audio feedback.
- scripts/systems/game_state.gd: save/unlock, localization, accessibility and settings.
- scenes/ui/mobile_hud.tscn: responsive touch joystick, interact button, pause, objective prompts and safe areas.
- tests: headless scene import and automated puzzle-state checks.

## Visual production
- One cohesive stylized art direction: warm sandstone, turquoise luminescence, foliage and bronze trim.
- Use original Pip design; rigged animation (idle, walk, interact, celebrate).
- Prefer curated and LICENSE-VERIFIED CC0 asset packs (Kenney modular dungeon, nature; Quaternius where verified) rather than primitive boxes; preserve credits/license metadata.
- Lighting: mobile-safe baked/static where possible; one directional key light, limited transparencies, LOD and instancing.
- Import glTF/GLB meshes into Godot. Use material overrides, authored landmarks, fog/sky gradient and low-cost particle effects.

## Device / release criteria
- Godot Compatibility renderer for WebGL2 on Samsung Android Chrome; optimize resolution and draw calls.
- Responsive landscape camera, no clipped board; minimum 48dp interactive targets and readable typography.
- Touch controls must work; web audio unlocked after interaction; no mandatory keyboard.
- Manual mobile QA: load, play all 3 puzzles, complete, restart, refresh saved state, rotate device, and verify errors.
- GitHub Actions exports on a dedicated branch and publishes isolated preview without touching existing production game.
- A green CI check means export succeeded; game is not approved until tested on-device.

## References
- https://docs.godotengine.org/en/4.3/tutorials/performance/optimizing_3d_performance.html
- https://docs.godotengine.org/en/4.3/about/list_of_features.html
- https://kenney.nl/assets/modular-dungeon-kit
- https://kenney.nl/assets/nature-kit

## Implementation order
1. Build the actual authored observatory scene and verify correct portrait/landscape viewport behavior.
2. Implement Pip locomotion, camera, touch input, collision and interaction.
3. Implement three puzzles, progression and reset.
4. Integrate licensed assets, animation, audio and polish.
5. Run automated export and human mobile QA; only then offer preview.

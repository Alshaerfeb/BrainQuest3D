# Asset sourcing for the NEW Brain Quest (not previous prototype)

The rebuild begins from main on branch brainquest-rebuild; do not copy scripts/main.gd or the cube-maze scene from godot-3d-prototype.

## Approved candidate model libraries

1. **Kenney Modular Dungeon Kit** — https://kenney.nl/assets/modular-dungeon-kit — CC0; 40 modular dungeon pieces; ideal for walls, pillars, flooring and gates. Source verifies license. Prefer glTF for Godot 4.
2. **Kenney Nature Kit** — https://kenney.nl/assets/nature-kit — CC0; foliage, stones, and environmental props.
3. **Quaternius** — https://quaternius.com — choose specific packs whose individual pages verify CC0; potential rigged character and fantasy props. Download only the free licensed subset unless separately authorized to purchase.
4. **Kenney Mobile Controls** — https://kenney.nl/assets/mobile-controls — CC0; readable touch HUD icons.

## Import quality gate
- Download original author-hosted packages, retain included licenses and source URLs in assets/THIRD_PARTY.md.
- Import GLB/glTF into Godot; inspect mesh scale, normals, collision, material colors and draw calls.
- Use cohesive materials and art direction; do not combine mismatched models without reworking them.
- Never claim an asset has been integrated until it is committed in the project and rendered in a running scene.
- No unauthorized copies of recognizable commercial game characters, exact level layouts, textures, or music.

## Build target
New landscape-first Godot 4 game, original Sunken Observatory level with 3 mechanics, mobile touch input, animated Pip, saved progress and isolated web preview.

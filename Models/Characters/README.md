# Rust Mobile Survival — character skins

This folder contains the eight generated, rigged player skins used by the Godot gallery.

- SKIN_01.glb to SKIN_08.glb: medium-detail GLB characters with a game skeleton and animation clips.
- The gallery normalizes every model to the same 1.75 m in-game height using manifest.json.
- Men start shirtless with plain survival shorts.
- Women start with an opaque sports bra and plain survival shorts; all four use long hairstyles.
- No armour, backpacks, shoes, helmets or gameplay bonuses are included in the starter appearance.
- All eight player choices share the same collision capsule.

## Provenance and licence

The models are generated with Ara 3D Gen (MIT-licensed generator code) using MakeHuman core character assets released under CC0 1.0. The project adds its own sports-bra and plain-shorts garment definitions. Ara 3D Gen states that exported characters may be used in commercial and non-commercial projects without attribution.

- Generator: https://github.com/olatunde85/3d-gen
- MakeHuman asset licence: https://github.com/makehumancommunity/mpfb2/blob/master/LICENSE.md
- CC0 1.0: https://creativecommons.org/publicdomain/zero/1.0/

See manifest.json for each skin's exported height, triangle count and file size.

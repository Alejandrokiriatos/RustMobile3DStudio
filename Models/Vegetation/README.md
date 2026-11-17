# Vegetation library — Godot 4.4.1

The independent studio contains 17 reusable 3D assets: 15 trees and two
harvestable bushes. Every model is a real Godot mesh hierarchy, not an image:
trunks, branches, foliage, palm fronds, fruit/berries, plus collision proxies.
The automated workflow also exports each asset as a standalone GLB and imports
it again to verify that the file is readable.

## Trees
Pine, oak, birch, willow, palm, dead tree, autumn maple, banana, cypress,
acacia, snow pine, cherry blossom, jungle tree, fruit tree and desert tree.
Asset IDs are TREE_01_PINE through TREE_15_DESERT.

## Harvestable bushes
- BUSH_01_FIBER: cloth/fiber resource, 2–5 units per harvest.
- BUSH_02_FOOD: food/berries resource, 3–6 units per harvest.

Both bushes expose `harvestable`, `resource_type`, `resource_label`,
`yield_min` and `yield_max` metadata. Tree collision proxies cover trunks;
the bushes use compact spherical collision proxies.

## Reuse in Godot
```gdscript
var factory = preload("res://Scripts/Vegetation/vegetation_factory.gd").new()
var pine = factory.create_tree("TREE_01_PINE")
var fiber_bush = factory.create_bush("BUSH_01_FIBER")
add_child(pine)
add_child(fiber_bush)
```

The workflow validates all 17 models, exports and re-imports their individual
GLB files, renders a real Godot 4.4.1 gallery screenshot, and uploads the GLBs
and screenshot together as a downloadable artifact.

Art direction: stylized, mobile-oriented low-poly models. This is a solid
first asset pass, not photorealistic final art. Baked textures, LODs, wind
animation and harvesting/regrowth gameplay hooks remain future polish.

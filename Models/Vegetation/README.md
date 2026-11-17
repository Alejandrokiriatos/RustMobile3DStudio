# Vegetation library — Godot 4.4.1

This module adds 17 reusable procedural 3D assets to the independent studio:
15 tree variants and two harvestable bushes. They are built from actual Godot
MeshInstance3D geometry (trunks, branches, foliage, fronds, fruit and berries),
not sprites or generated catalog pictures.

## Assets
TREE_01_PINE, TREE_02_OAK, TREE_03_BIRCH, TREE_04_WILLOW, TREE_05_PALM,
TREE_06_DEAD, TREE_07_MAPLE, TREE_08_BANANA, TREE_09_CYPRESS, TREE_10_ACACIA,
TREE_11_SNOW_PINE, TREE_12_CHERRY, TREE_13_JUNGLE, TREE_14_FRUIT,
TREE_15_DESERT, BUSH_01_FIBER, BUSH_02_FOOD.

## Use
Open DemoScenes/Vegetation/vegetation_gallery.tscn to see all 17 models.
The factory script exposes create_tree(asset_id) and create_bush(asset_id).
Bushes carry metadata: harvestable, resource_type, yield_min and yield_max.
Fiber bush yields 2–5 fiber; food bush yields 3–6 berries.
Trees are decorative/resource candidates and are marked harvestable=false until
the game defines wood harvesting and regrowth rules.

The gallery uses a fixed random seed for repeatable previews. Meshes are
low-poly and intended as a mobile-friendly first production pass; they can
later receive authored bark/leaf textures, LODs, collision proxies and wind.

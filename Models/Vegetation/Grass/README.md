# Grass Clump 01

Procedural low-poly grass clump for Godot 4.4.1.

- Geometry: four crossed, tapered blade meshes per clump.
- Rendering: vertex-color material, double-sided, rough, no texture dependency.
- Placement: MultiMeshInstance3D in the demo for efficient instancing.
- Intended use: ground cover in small and medium vegetation patches.
- Mobile target: one shared mesh/material with GPU instancing.

The demo currently generates terrain and grass procedurally in
`Scripts/GrassTerrain/grass_test.gd`. Once approved, this asset can be
extracted into a standalone scene/resource with configurable density,
height, color variation and wind response.

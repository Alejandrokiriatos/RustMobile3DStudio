# RustMobile3DStudio

Independent 3D asset laboratory for **Rust Mobile Survival**.

**Engine:** Godot 4.4.1  
**Purpose:** Build, test and package reusable 3D assets without modifying the main game repository.

## First prototype: Grass + terrain

Open this folder in Godot 4.4.1 and run the project. The main scene creates:
- A small undulating soil terrain.
- A reusable four-blade low-poly grass clump.
- 1,150 grass instances using MultiMesh.
- Directional sunlight, ambient lighting and a showcase camera.

No external textures, plugins or asset packs are required.

## Project layout

- `Models/` — reusable model assets
- `Materials/` — shared materials
- `Textures/` — texture sources
- `Animations/` — animation resources
- `DemoScenes/` — visual test scenes
- `Scripts/` — procedural construction and helper scripts
- `Screenshots/` — real captures from Godot runs
- `Documentation/` — integration notes

## Run

1. Install/open with Godot 4.4.1.
2. Import this repository as a project.
3. Press F6 or F5 and inspect the grass patch from the showcase camera.

The main game repository is intentionally not modified.

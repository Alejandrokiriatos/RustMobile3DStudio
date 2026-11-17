# RustMobile3DStudio

Independent 3D asset laboratory for Rust Mobile Survival.

Engine: Godot 4.4.1  
Purpose: build, test and package reusable 3D assets without modifying the main game repository.

## Character laboratory

The character gallery imports eight rigged GLB human models instead of assembling bodies from primitive shapes. It displays the eight skins in a shared showroom and normalizes their appearance to a 1.75 m visual height.

The eight starter designs include four masculine and four feminine appearances. All four feminine designs have opaque sports-bras and long, varied hairstyles. Every skin uses simple survival shorts and starts without armour, shoes, backpacks or helmets. Future clothing and protective equipment will be replaceable visual slots.

The build pipeline generates human anatomy, hair and clothing using the open-source Ara 3D Gen workflow with MakeHuman CC0 base assets. It exports a game skeleton, facial blend shapes and animation clips to GLB, retains gameplay-relevant clips, compacts binary data for mobile packaging, validates all eight models and renders a real preview from Godot 4.4.1 in GitHub Actions.

All skins share a 1.75 m visual height and a 0.32 m radius / 1.75 m height collision capsule. Skin choice does not modify gameplay.

## Grass and terrain

The project also includes a small undulating soil terrain and a reusable low-poly grass demo using MultiMesh instancing.

## Project layout

- Models/Characters/ — eight rigged character GLBs and their manifest
- Models/Vegetation/ — reusable vegetation assets
- CharacterBuild/ — appearance parameters, exporter and mobile GLB optimizer
- Materials/ and Textures/ — shared visual resources
- Animations/ — shared animation resources
- DemoScenes/ — visual test scenes
- Scripts/ — construction and gallery scripts
- Screenshots/ — real captures from Godot runs
- Documentation/ — integration notes

## Run

1. Install/open with Godot 4.4.1.
2. Import this repository as a project.
3. Press F5 to open the current character gallery, or open the grass demo scene.

The main game repository is intentionally not modified.

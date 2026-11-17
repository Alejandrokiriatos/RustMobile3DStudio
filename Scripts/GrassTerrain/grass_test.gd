extends Node3D
## Procedural, reusable grass-clump and small terrain showcase.
## Built from real mesh geometry; no billboard images or external assets.

const TERRAIN_SIZE := 18.0
const TERRAIN_SUBDIVISIONS := 48
const GRASS_COUNT := 7600
const PATCH_RADIUS := 8.45

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 44117
	_build_environment()
	_build_terrain()
	_build_grass()
	_build_camera()
	if OS.get_environment("CAPTURE_PREVIEW") == "1":
		_capture_preview()

func _terrain_height(x: float, z: float) -> float:
	return 0.12 * sin(x * 0.62) * cos(z * 0.48) + 0.045 * sin(z * 1.35 + x * 0.3)

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.28, 0.43, 0.58)
	sky_material.sky_horizon_color = Color(0.72, 0.78, 0.76)
	sky_material.ground_bottom_color = Color(0.12, 0.16, 0.12)
	sky_material.ground_horizon_color = Color(0.48, 0.53, 0.43)
	environment.sky.sky_material = sky_material
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.78, 0.68)
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 35.0
	add_child(sun)

func _build_terrain() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := TERRAIN_SIZE * 0.5
	var step := TERRAIN_SIZE / float(TERRAIN_SUBDIVISIONS)
	for z in range(TERRAIN_SUBDIVISIONS):
		for x in range(TERRAIN_SUBDIVISIONS):
			var x0 := -half + x * step
			var x1 := x0 + step
			var z0 := -half + z * step
			var z1 := z0 + step
			var a := Vector3(x0, _terrain_height(x0, z0), z0)
			var b := Vector3(x1, _terrain_height(x1, z0), z0)
			var c := Vector3(x1, _terrain_height(x1, z1), z1)
			var d := Vector3(x0, _terrain_height(x0, z1), z1)
			for p in [a, c, b, a, d, c]:
				st.set_color(_soil_vertex_color(p.x, p.z))
				st.add_vertex(p)
	st.generate_normals()
	var mesh := st.commit()
	var ground := MeshInstance3D.new()
	ground.name = "UnevenSoilTerrain"
	ground.mesh = mesh
	var soil := StandardMaterial3D.new()
	soil.vertex_color_use_as_albedo = true
	soil.roughness = 1.0
	soil.cull_mode = BaseMaterial3D.CULL_DISABLED
	ground.material_override = soil
	add_child(ground)

func _soil_vertex_color(x: float, z: float) -> Color:
	var variation := 0.035 * sin(x * 3.1 + z * 1.7)
	return Color(0.30 + variation, 0.235 + variation, 0.145 + variation, 1.0)

func _make_grass_clump() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var blade_colors := [
		Color(0.17, 0.30, 0.085),
		Color(0.23, 0.39, 0.105),
		Color(0.30, 0.47, 0.13),
		Color(0.38, 0.53, 0.16),
		Color(0.25, 0.42, 0.105),
		Color(0.20, 0.36, 0.09)
	]
	for blade in range(6):
		var angle := float(blade) * TAU / 6.0 + 0.18
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		var side := Vector3(-direction.z, 0.0, direction.x)
		var height := 0.31 + 0.105 * float(blade % 4)
		var width := 0.065 + 0.012 * float(blade % 2)
		var lean := direction * (0.075 + 0.03 * float(blade % 2))
		var base := Vector3.ZERO
		var left := base - side * width * 0.5
		var right := base + side * width * 0.5
		var tip := Vector3(0.0, height, 0.0) + lean
		var middle_left := left.lerp(tip, 0.48) - side * width * 0.12
		var middle_right := right.lerp(tip, 0.48) + side * width * 0.12
		var color: Color = blade_colors[blade]
		_add_colored_triangle(st, left, middle_left, tip, color.lightened(0.06))
		_add_colored_triangle(st, middle_left, middle_right, tip, color)
		_add_colored_triangle(st, middle_right, right, tip, color.darkened(0.08))
	st.generate_normals()
	return st.commit()

func _add_colored_triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	st.set_color(color)
	st.add_vertex(a)
	st.set_color(color.lightened(0.04))
	st.add_vertex(b)
	st.set_color(color.darkened(0.05))
	st.add_vertex(c)

func _build_grass() -> void:
	var grass_mesh := _make_grass_clump()
	var grass_material := StandardMaterial3D.new()
	grass_material.vertex_color_use_as_albedo = true
	grass_material.roughness = 0.92
	grass_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	grass_material.metallic = 0.0

	var grass := MultiMeshInstance3D.new()
	grass.name = "InstancedGrassClumps"
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = grass_mesh
	multimesh.instance_count = GRASS_COUNT
	multimesh.visible_instance_count = GRASS_COUNT
	# Stratified placement: twice the previous clump count, with jitter to avoid
	# random bare patches while keeping the distribution visually organic.
	var grid_side := 88
	var cell_size := (PATCH_RADIUS * 2.0) / float(grid_side)
	var cell_indices: Array[int] = []
	for cell in range(grid_side * grid_side):
		cell_indices.append(cell)
	cell_indices.shuffle()
	for i in range(GRASS_COUNT):
		var cell := cell_indices[i]
		var cell_x := cell % grid_side
		var cell_z := int(cell / grid_side)
		var x := -PATCH_RADIUS + (float(cell_x) + 0.5 + rng.randf_range(-0.38, 0.38)) * cell_size
		var z := -PATCH_RADIUS + (float(cell_z) + 0.5 + rng.randf_range(-0.38, 0.38)) * cell_size
		var y := _terrain_height(x, z) + 0.012
		var scale := rng.randf_range(0.72, 1.28)
		var rotation := rng.randf_range(0.0, TAU)
		var basis := Basis(Vector3.UP, rotation).scaled(Vector3(scale, scale, scale))
		multimesh.set_instance_transform(i, Transform3D(basis, Vector3(x, y, z)))
	grass.multimesh = multimesh
	grass.material_override = grass_material
	# Dense grass keeps shadows disabled to reduce mobile GPU cost.
	add_child(grass)

func _build_camera() -> void:
	var camera := Camera3D.new()
	camera.name = "ShowcaseCamera"
	camera.position = Vector3(10.2, 7.6, 11.8)
	camera.fov = 48.0
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)

func _capture_preview() -> void:
	await get_tree().create_timer(2.5).timeout
	var image := get_viewport().get_texture().get_image()
	image.save_png("res://Screenshots/grass_terrain_godot.png")
	get_tree().quit()

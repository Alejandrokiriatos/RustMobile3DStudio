extends Node3D

# The gallery now displays exported, rigged GLB characters. Appearance is modular;
# the gameplay collision capsule stays identical for every cosmetic skin.
const PLAYER_HEIGHT := 1.75
const HITBOX_RADIUS := 0.32
const HITBOX_HEIGHT := 1.75

const SKINS := [
	{"name":"SKIN 01","path":"res://Models/Characters/SKIN_01.glb"},
	{"name":"SKIN 02","path":"res://Models/Characters/SKIN_02.glb"},
	{"name":"SKIN 03","path":"res://Models/Characters/SKIN_03.glb"},
	{"name":"SKIN 04","path":"res://Models/Characters/SKIN_04.glb"},
	{"name":"SKIN 05","path":"res://Models/Characters/SKIN_05.glb"},
	{"name":"SKIN 06","path":"res://Models/Characters/SKIN_06.glb"},
	{"name":"SKIN 07","path":"res://Models/Characters/SKIN_07.glb"},
	{"name":"SKIN 08","path":"res://Models/Characters/SKIN_08.glb"}
]

func _ready() -> void:
	print("CHARACTER_GALLERY_READY: loading eight rigged GLB skins")
	_build_stage()
	var manifest := _load_manifest()
	for i in range(SKINS.size()):
		var row: Dictionary = SKINS[i]
		var row_index := i / 4
		var col_index := i % 4
		var position := Vector3((col_index - 1.5) * 2.25, 0.0, (row_index - 0.5) * 2.35)
		_build_character(row, position, manifest)
	if OS.get_environment("CAPTURE_CHARACTERS") == "1":
		call_deferred("_capture_preview")


func _load_manifest() -> Dictionary:
	var path := "res://Models/Characters/manifest.json"
	if not FileAccess.file_exists(path):
		push_error("Character manifest is missing: " + path)
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Character manifest is not valid JSON.")
		return {}
	return parsed


func _build_character(data: Dictionary, origin: Vector3, manifest: Dictionary) -> void:
	var player := CharacterBody3D.new()
	player.name = str(data.name).replace(" ", "_")
	player.position = origin
	add_child(player)

	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = HITBOX_RADIUS
	capsule.height = HITBOX_HEIGHT
	collision.shape = capsule
	collision.position.y = HITBOX_HEIGHT * 0.5
	player.add_child(collision)

	var skin_metrics: Dictionary = manifest.get("skins", {}).get(str(data.name).replace(" ", "_"), {})
	var model_height := float(skin_metrics.get("height_m", PLAYER_HEIGHT))
	if model_height <= 0.01:
		model_height = PLAYER_HEIGHT
	var model_scale := PLAYER_HEIGHT / model_height

	var resource = load(str(data.path))
	if resource == null or not (resource is PackedScene):
		push_error("Could not load rigged character: " + str(data.path))
		return
	var character_scene := resource as PackedScene
	var character_model := character_scene.instantiate() as Node3D
	if character_model == null:
		push_error("GLB scene root is not Node3D: " + str(data.path))
		return
	character_model.name = "CharacterModel"
	character_model.scale = Vector3.ONE * model_scale
	player.add_child(character_model)

	var label := Label3D.new()
	label.text = str(data.name).replace("_", " ")
	label.position = Vector3(0, PLAYER_HEIGHT + 0.18, 0)
	label.font_size = 30
	label.pixel_size = 0.004
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("#f2eee5")
	player.add_child(label)

	print(str(data.name), " loaded | original_height=", model_height, " | scale=", model_scale, " | hitbox=", HITBOX_HEIGHT, " x ", HITBOX_RADIUS)


func _build_stage() -> void:
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(12.0, 8.5)
	floor.mesh = plane
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("#343b3b")
	floor_material.roughness = 0.92
	floor.material_override = floor_material
	floor.position = Vector3(0, -0.025, 0)
	add_child(floor)

	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#20282b")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#c6d0cf")
	environment.ambient_light_energy = 0.82
	world.environment = environment
	add_child(world)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48, -28, 0)
	key.light_energy = 1.55
	key.shadow_enabled = true
	add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-18, 145, 0)
	fill.light_energy = 0.52
	fill.shadow_enabled = false
	add_child(fill)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 4.0, 11.2)
	camera.rotation_degrees = Vector3(-20, 0, 0)
	camera.fov = 42
	camera.current = true
	add_child(camera)


func _capture_preview() -> void:
	print("CHARACTER_CAPTURE_WAITING")
	await get_tree().create_timer(3.0).timeout
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var output_path := ProjectSettings.globalize_path("res://Screenshots/eight_characters_godot.png")
	var error := image.save_png(output_path)
	print("CHARACTER_SCREENSHOT path=", output_path, " error=", error, " size=", image.get_size())
	get_tree().quit()

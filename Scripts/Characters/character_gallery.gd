extends Node3D

# Showcase for eight rigged human GLBs. Cosmetic selection never changes gameplay.
const PLAYER_HEIGHT := 1.75
const HITBOX_RADIUS := 0.32
const HITBOX_HEIGHT := 1.75
const SKIN_IDS := ["SKIN_01", "SKIN_02", "SKIN_03", "SKIN_04", "SKIN_05", "SKIN_06", "SKIN_07", "SKIN_08"]
const ROW_HEIGHT := 2.22
var _showcase_camera: Camera3D

func _ready() -> void:
	print("CHARACTER_GALLERY_READY; loading eight rigged GLB skins")
	_build_stage()
	var manifest := _load_manifest()
	var rows: Dictionary = manifest.get("skins", {})
	for i in SKIN_IDS.size():
		var row := i / 4
		var col := i % 4
		var x := (float(col) - 1.5) * 1.98
		var y := float(1 - row) * ROW_HEIGHT + 0.045
		var origin := Vector3(x, y, 0.0)
		_build_character(SKIN_IDS[i], origin, rows)
	if OS.get_environment("CAPTURE_CHARACTERS") == "1":
		call_deferred("_capture_preview")

func _load_manifest() -> Dictionary:
	var path := "res://Models/Characters/manifest.json"
	if not FileAccess.file_exists(path):
		push_error("Character manifest is missing: " + path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Character manifest is not a JSON object")
		return {}
	return parsed as Dictionary

func _build_character(skin_id: String, origin: Vector3, rows: Dictionary) -> void:
	var scene_path := "res://Models/Characters/" + skin_id + ".glb"
	var packed := ResourceLoader.load(scene_path) as PackedScene
	if packed == null:
		push_error("Unable to import character model: " + scene_path)
		return

	var record: Dictionary = rows.get(skin_id, {})
	var source_height := float(record.get("height_m", PLAYER_HEIGHT))
	if source_height <= 0.1:
		source_height = PLAYER_HEIGHT
	var uniform_scale := PLAYER_HEIGHT / source_height

	var player := CharacterBody3D.new()
	player.name = skin_id
	player.position = origin
	add_child(player)

	# The exact same collision capsule is assigned to all eight selectable skins.
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = HITBOX_RADIUS
	capsule.height = HITBOX_HEIGHT
	collision.shape = capsule
	collision.position.y = HITBOX_HEIGHT * 0.5
	player.add_child(collision)

	var visual := packed.instantiate() as Node3D
	if visual == null:
		push_error("Imported GLB root is not Node3D: " + scene_path)
		player.queue_free()
		return
	visual.name = "VisualModel"
	visual.scale = Vector3.ONE * uniform_scale
	player.add_child(visual)
	_play_idle(visual)
	_add_pedestal(origin)

	var label := Label3D.new()
	label.name = "SkinLabel"
	label.text = skin_id.replace("_", " ")
	label.position = Vector3(0.0, 1.91, 0.0)
	label.font_size = 32
	label.pixel_size = 0.0035
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("#f1eee6")
	label.outline_size = 7
	label.outline_modulate = Color("#172024")
	player.add_child(label)

	print(skin_id, ": imported; normalized height=", PLAYER_HEIGHT,
		"m; source height=", source_height,
		"; triangles=", int(record.get("triangles", 0)),
		"; package MB=", snappedf(float(record.get("bytes", 0)) / 1048576.0, 0.01))

func _play_idle(root: Node) -> void:
	var animation_player := _find_animation_player(root)
	if animation_player == null:
		push_warning("No AnimationPlayer found in " + root.name)
		return
	var clips := animation_player.get_animation_list()
	if clips.has("Idle"):
		animation_player.play("Idle")
	elif clips.size() > 0:
		animation_player.play(clips[0])

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

func _add_pedestal(origin: Vector3) -> void:
	var base := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.46
	cylinder.bottom_radius = 0.49
	cylinder.height = 0.075
	cylinder.radial_segments = 40
	base.mesh = cylinder
	base.material_override = _material(Color("#465054"), 0.72, 0.12)
	base.position = origin + Vector3(0.0, -0.04, 0.0)
	add_child(base)

func _material(color: Color, roughness := 0.84, metallic := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func _build_stage() -> void:
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(9.6, 5.4)
	floor.mesh = plane
	floor.material_override = _material(Color("#303a3d"))
	floor.position = Vector3(0.0, -0.06, 0.0)
	add_child(floor)

	# Raised rear shelf separates the second row without overlapping the figures.
	var shelf := MeshInstance3D.new()
	var shelf_mesh := BoxMesh.new()
	shelf_mesh.size = Vector3(8.7, 0.12, 2.0)
	shelf.mesh = shelf_mesh
	shelf.material_override = _material(Color("#3b464a"), 0.78, 0.08)
	shelf.position = Vector3(0.0, ROW_HEIGHT - 0.015, -0.12)
	add_child(shelf)

	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#1e292d")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#c3ccca")
	environment.ambient_light_energy = 0.44
	world.environment = environment
	add_child(world)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-28.0, -24.0, 0.0)
	key.light_energy = 0.82
	key.shadow_enabled = true
	add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-12.0, 145.0, 0.0)
	fill.light_energy = 0.16
	fill.shadow_enabled = false
	add_child(fill)

	_showcase_camera = Camera3D.new()
	var camera := _showcase_camera
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 4.48
	camera.position = Vector3(0.0, 2.18, 15.0)
	add_child(camera)
	camera.look_at(Vector3(0.0, 2.18, 0.0), Vector3.UP)
	camera.current = true

func _capture_preview() -> void:
	print("CHARACTER_CAPTURE_WAITING")
	await get_tree().create_timer(3.0).timeout
	await RenderingServer.frame_post_draw
	var front_image := get_viewport().get_texture().get_image()
	var front_path := ProjectSettings.globalize_path("res://Screenshots/eight_characters_godot.png")
	var front_error := front_image.save_png(front_path)
	print("CHARACTER_FRONT_SCREENSHOT path=", front_path, " error=", front_error, " size=", front_image.get_size())

	# A rear view is captured separately so the length and shape of the four women's
	# hairstyles can be verified rather than judged only from the front.
	_showcase_camera.position = Vector3(0.0, 2.18, -15.0)
	_showcase_camera.look_at(Vector3(0.0, 2.18, 0.0), Vector3.UP)
	await get_tree().create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	var rear_image := get_viewport().get_texture().get_image()
	var rear_path := ProjectSettings.globalize_path("res://Screenshots/eight_characters_back_godot.png")
	var rear_error := rear_image.save_png(rear_path)
	print("CHARACTER_BACK_SCREENSHOT path=", rear_path, " error=", rear_error, " size=", rear_image.get_size())
	get_tree().quit()

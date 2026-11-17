extends Node3D

# Eight selectable multiplayer cosmetics. Every skin shares the exact same
# player dimensions and collision capsule; appearance never changes gameplay.
const PLAYER_HEIGHT := 1.75
const HITBOX_RADIUS := 0.32
const HITBOX_HEIGHT := 1.75

const SKINS := [
	{"name":"SKIN 01","skin":Color("#b87954"),"hair":Color("#30231e"),"top":Color("#777b63"),"legs":Color("#393d39"),"trim":Color("#b7a27b"),"gear":Color("#51483a"),"style":0},
	{"name":"SKIN 02","skin":Color("#d49a70"),"hair":Color("#4b3025"),"top":Color("#526c59"),"legs":Color("#66513b"),"trim":Color("#b4a16e"),"gear":Color("#6c5941"),"style":1},
	{"name":"SKIN 03","skin":Color("#a96f50"),"hair":Color("#211e1b"),"top":Color("#414b43"),"legs":Color("#303831"),"trim":Color("#9a9b77"),"gear":Color("#292f2d"),"style":2},
	{"name":"SKIN 04","skin":Color("#c58b68"),"hair":Color("#382a22"),"top":Color("#a45e37"),"legs":Color("#414b5a"),"trim":Color("#d0b46b"),"gear":Color("#45494b"),"style":3},
	{"name":"SKIN 05","skin":Color("#e0b18f"),"hair":Color("#38251f"),"top":Color("#806b65"),"legs":Color("#4c4648"),"trim":Color("#c5a88b"),"gear":Color("#514044"),"style":4},
	{"name":"SKIN 06","skin":Color("#bd8768"),"hair":Color("#251c19"),"top":Color("#687b63"),"legs":Color("#514c3c"),"trim":Color("#b8a276"),"gear":Color("#4d5948"),"style":5},
	{"name":"SKIN 07","skin":Color("#9d684e"),"hair":Color("#211c1a"),"top":Color("#414b43"),"legs":Color("#303831"),"trim":Color("#a4a17b"),"gear":Color("#252b2b"),"style":6},
	{"name":"SKIN 08","skin":Color("#d8a17f"),"hair":Color("#67402d"),"top":Color("#a45e37"),"legs":Color("#414b5a"),"trim":Color("#d0b46b"),"gear":Color("#5a5144"),"style":7}
]

func _ready() -> void:
	print("CHARACTER_GALLERY_READY env=", OS.get_environment("CAPTURE_CHARACTERS"), " skins=", SKINS.size())
	_build_stage()
	for i in SKINS.size():
		var row := i / 4
		var col := i % 4
		_build_skin(SKINS[i], Vector3((col - 1.5) * 2.55, 0.0, (row - 0.5) * 2.65))
	if OS.get_environment("CAPTURE_CHARACTERS") == "1":
		call_deferred("_capture_preview")


func _material(color: Color, roughness := 0.88, metallic := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func _mesh(parent: Node3D, shape: PrimitiveMesh, material: Material, position: Vector3, scale := Vector3.ONE, rotation := Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = shape
	instance.material_override = material
	instance.position = position
	instance.scale = scale
	instance.rotation = rotation
	parent.add_child(instance)
	return instance

func _box(parent: Node3D, material: Material, position: Vector3, size: Vector3, rotation := Vector3.ZERO) -> void:
	var shape := BoxMesh.new()
	shape.size = size
	_mesh(parent, shape, material, position, Vector3.ONE, rotation)

func _sphere(parent: Node3D, material: Material, position: Vector3, radius: Vector3) -> void:
	var shape := SphereMesh.new()
	shape.radius = 1.0
	shape.height = 2.0
	_mesh(parent, shape, material, position, radius)

func _capsule(parent: Node3D, material: Material, position: Vector3, height: float, radius: float, rotation := Vector3.ZERO) -> void:
	var shape := CapsuleMesh.new()
	shape.radius = radius
	shape.height = height
	_mesh(parent, shape, material, position, Vector3.ONE, rotation)

func _build_skin(data: Dictionary, origin: Vector3) -> void:
	var player := CharacterBody3D.new()
	player.name = str(data.name).replace(" ", "_")
	player.position = origin
	add_child(player)

	# Identical collision for every cosmetic skin.
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = HITBOX_RADIUS
	capsule.height = HITBOX_HEIGHT
	collision.shape = capsule
	collision.position.y = HITBOX_HEIGHT * 0.5
	player.add_child(collision)

	var skin := _material(data.skin)
	var hair := _material(data.hair)
	var top := _material(data.top)
	var legs := _material(data.legs)
	var trim := _material(data.trim, 0.72)
	var gear := _material(data.gear)
	var dark := _material(Color("#252522"))
	var metal := _material(Color("#8b8d86"), 0.38, 0.55)
	var boot := _material(Color("#292a28"))
	var style: int = data.style

	# Boots, articulated-looking legs, knee pads and utility belt.
	for side in [-1.0, 1.0]:
		var x: float = float(side) * 0.115
		_capsule(player, legs, Vector3(x, 0.49, 0.0), 0.76, 0.105)
		_box(player, boot, Vector3(x, 0.105, 0.055), Vector3(0.205, 0.16, 0.32))
		_box(player, trim if style in [2, 6] else gear, Vector3(x, 0.48, 0.108), Vector3(0.19, 0.13, 0.055))
		_box(player, dark, Vector3(x, 0.20, -0.005), Vector3(0.13, 0.07, 0.22))
	_box(player, legs, Vector3(0, 0.91, 0), Vector3(0.39, 0.27, 0.24))
	_box(player, gear, Vector3(0, 0.99, 0.135), Vector3(0.42, 0.075, 0.045))
	_box(player, metal, Vector3(0, 0.99, 0.163), Vector3(0.095, 0.07, 0.025))

	# Torso with shaped shoulders, chest layer and visible clothing seams.
	_capsule(player, top, Vector3(0, 1.205, 0), 0.64, 0.205)
	for side in [-1.0, 1.0]:
		_sphere(player, top, Vector3(side * 0.205, 1.39, 0), Vector3(0.125, 0.12, 0.13))
		_capsule(player, top, Vector3(side * 0.255, 1.19, 0.0), 0.56, 0.083, Vector3(0, 0, side * -0.10))
		_capsule(player, skin, Vector3(side * 0.27, 0.855, 0.015), 0.20, 0.061)
		_sphere(player, skin, Vector3(side * 0.27, 0.765, 0.025), Vector3(0.067, 0.07, 0.065))
	# Vest/front panel and side seams.
	_box(player, gear, Vector3(0, 1.235, 0.187), Vector3(0.285, 0.39, 0.045))
	_box(player, trim, Vector3(0, 1.235, 0.214), Vector3(0.045, 0.36, 0.018))
	for side in [-1.0, 1.0]:
		_box(player, trim, Vector3(side * 0.115, 1.31, 0.218), Vector3(0.075, 0.075, 0.02))
		_box(player, dark, Vector3(side * 0.105, 1.10, 0.218), Vector3(0.085, 0.12, 0.025))

	# Neck and head remain inside the shared 1.75 m capsule.
	_capsule(player, skin, Vector3(0, 1.515, 0), 0.15, 0.068)
	_sphere(player, skin, Vector3(0, 1.595, 0), Vector3(0.132, 0.155, 0.125))
	# Hair, ears, nose, eyes and brows create a readable face at game distance.
	_sphere(player, hair, Vector3(0, 1.692, -0.012), Vector3(0.137, 0.075, 0.132))
	_sphere(player, skin, Vector3(0, 1.575, 0.126), Vector3(0.027, 0.035, 0.028))
	for side in [-1.0, 1.0]:
		_sphere(player, skin, Vector3(side * 0.132, 1.59, 0), Vector3(0.025, 0.045, 0.035))
		_sphere(player, dark, Vector3(side * 0.049, 1.615, 0.112), Vector3(0.014, 0.018, 0.009))
		_box(player, hair, Vector3(side * 0.05, 1.642, 0.113), Vector3(0.045, 0.012, 0.012))

	# Each outfit has its own recognizable silhouette and gear arrangement.
	match style:
		0: # Nomad: scarf, shoulder wrap and bedroll.
			_capsule(player, trim, Vector3(0, 1.48, 0.02), 0.18, 0.105)
			_box(player, gear, Vector3(0, 1.28, -0.205), Vector3(0.30, 0.30, 0.12))
			_box(player, trim, Vector3(0.0, 1.42, 0.225), Vector3(0.22, 0.045, 0.025))
		1: # Tracker: hood, chest harness and field pack.
			_sphere(player, gear, Vector3(0, 1.67, -0.025), Vector3(0.16, 0.12, 0.15))
			_box(player, trim, Vector3(0, 1.25, 0.242), Vector3(0.055, 0.34, 0.025))
			_box(player, gear, Vector3(0, 1.31, -0.20), Vector3(0.34, 0.42, 0.16))
			_box(player, trim, Vector3(0.18, 1.22, 0.18), Vector3(0.08, 0.18, 0.04))
		2: # Vanguard: reinforced shoulder plates and armored chest.
			for side in [-1.0, 1.0]:
				_sphere(player, trim, Vector3(side * 0.22, 1.40, 0.01), Vector3(0.15, 0.09, 0.15))
				_box(player, gear, Vector3(side * 0.16, 1.18, 0.245), Vector3(0.10, 0.22, 0.04))
			_box(player, metal, Vector3(0, 1.31, 0.245), Vector3(0.16, 0.11, 0.025))
		3: # Mechanic: work vest, tool belt and cap.
			_box(player, trim, Vector3(0, 1.70, 0), Vector3(0.25, 0.055, 0.24))
			_box(player, gear, Vector3(0, 1.665, 0.09), Vector3(0.28, 0.025, 0.12))
			_box(player, dark, Vector3(-0.17, 1.02, 0.17), Vector3(0.12, 0.14, 0.06))
			_box(player, metal, Vector3(0.17, 1.02, 0.17), Vector3(0.12, 0.14, 0.06))
			_box(player, trim, Vector3(0, 1.12, 0.245), Vector3(0.30, 0.08, 0.035))
		4: # Wanderer: hooded jacket and cross-body strap.
			_sphere(player, gear, Vector3(0, 1.67, -0.02), Vector3(0.16, 0.12, 0.15))
			_box(player, trim, Vector3(0, 1.24, 0.245), Vector3(0.055, 0.38, 0.03), Vector3(0, 0, -0.42))
			_box(player, gear, Vector3(0, 1.30, -0.20), Vector3(0.32, 0.38, 0.15))
		5: # Ranger: brimmed hat, binoculars and side pouch.
			_capsule(player, hair, Vector3(0, 1.70, 0), 0.07, 0.12)
			_box(player, trim, Vector3(0, 1.735, 0), Vector3(0.36, 0.025, 0.30))
			_box(player, gear, Vector3(0, 1.30, -0.20), Vector3(0.34, 0.42, 0.14))
			for side in [-1.0, 1.0]:
				_capsule(player, dark, Vector3(side * 0.055, 1.50, 0.20), 0.11, 0.035)
		6: # Operator: face covering, headset and tactical rig.
			_box(player, gear, Vector3(0, 1.555, 0.115), Vector3(0.20, 0.09, 0.045))
			_sphere(player, metal, Vector3(-0.145, 1.61, 0), Vector3(0.035, 0.07, 0.055))
			_box(player, trim, Vector3(0, 1.28, 0.245), Vector3(0.29, 0.17, 0.035))
			for side in [-1.0, 1.0]:
				_box(player, gear, Vector3(side * 0.18, 1.18, 0.18), Vector3(0.08, 0.20, 0.09))
		7: # Scavenger: goggles, patched coat and scrap shoulder pad.
			_box(player, dark, Vector3(0, 1.625, 0.12), Vector3(0.22, 0.055, 0.045))
			for side in [-1.0, 1.0]:
				_sphere(player, metal, Vector3(side * 0.055, 1.625, 0.15), Vector3(0.045, 0.035, 0.018))
			_sphere(player, trim, Vector3(0.22, 1.40, 0), Vector3(0.12, 0.10, 0.14))
			_box(player, gear, Vector3(0, 1.28, -0.20), Vector3(0.34, 0.40, 0.16))

	var label := Label3D.new()
	label.text = str(data.name)
	label.position = Vector3(0, 1.94, 0)
	label.font_size = 30
	label.pixel_size = 0.004
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("#f2eee5")
	player.add_child(label)

func _build_stage() -> void:
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(13.0, 9.0)
	floor.mesh = plane
	floor.material_override = _material(Color("#343b3b"))
	floor.position = Vector3(0, -0.025, 0)
	add_child(floor)

	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#20282b")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#b7c3c4")
	environment.ambient_light_energy = 0.7
	world.environment = environment
	add_child(world)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48, -28, 0)
	key.light_energy = 1.45
	key.shadow_enabled = true
	add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-18, 145, 0)
	fill.light_energy = 0.45
	fill.shadow_enabled = false
	add_child(fill)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 6.2, 13.4)
	camera.rotation_degrees = Vector3(-25, 0, 0)
	camera.fov = 47
	camera.current = true
	add_child(camera)

func _capture_preview() -> void:
	print("CHARACTER_CAPTURE_WAITING")
	await get_tree().create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var output_path := ProjectSettings.globalize_path("res://Screenshots/eight_characters_godot.png")
	var error := image.save_png(output_path)
	print("CHARACTER_SCREENSHOT path=", output_path, " error=", error, " size=", image.get_size())
	get_tree().quit()

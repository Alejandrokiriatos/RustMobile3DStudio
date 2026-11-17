extends Node3D

const BODY_HEIGHT := 1.75
const HITBOX_RADIUS := 0.32
const HITBOX_HEIGHT := 1.75

const PEOPLE := [
	{"name":"01  SUPERVIVIENTE","gender":"H","skin":Color("#b87954"),"hair":Color("#30231e"),"shirt":Color("#777b63"),"pants":Color("#393d39"),"accent":Color("#b7a27b"),"style":0},
	{"name":"02  EXPLORADOR","gender":"H","skin":Color("#d49a70"),"hair":Color("#4b3025"),"shirt":Color("#526c59"),"pants":Color("#66513b"),"accent":Color("#b4a16e"),"style":1},
	{"name":"03  TÁCTICO","gender":"H","skin":Color("#a96f50"),"hair":Color("#211e1b"),"shirt":Color("#414b43"),"pants":Color("#303831"),"accent":Color("#9a9b77"),"style":2},
	{"name":"04  TRABAJADOR","gender":"H","skin":Color("#c58b68"),"hair":Color("#382a22"),"shirt":Color("#a45e37"),"pants":Color("#414b5a"),"accent":Color("#d0b46b"),"style":3},
	{"name":"05  SUPERVIVIENTE","gender":"M","skin":Color("#e0b18f"),"hair":Color("#38251f"),"shirt":Color("#806b65"),"pants":Color("#4c4648"),"accent":Color("#c5a88b"),"style":0},
	{"name":"06  EXPLORADORA","gender":"M","skin":Color("#bd8768"),"hair":Color("#251c19"),"shirt":Color("#687b63"),"pants":Color("#514c3c"),"accent":Color("#b8a276"),"style":1},
	{"name":"07  TÁCTICA","gender":"M","skin":Color("#9d684e"),"hair":Color("#211c1a"),"shirt":Color("#414b43"),"pants":Color("#303831"),"accent":Color("#a4a17b"),"style":2},
	{"name":"08  TRABAJADORA","gender":"M","skin":Color("#d8a17f"),"hair":Color("#67402d"),"shirt":Color("#a45e37"),"pants":Color("#414b5a"),"accent":Color("#d0b46b"),"style":3}
]

func _ready() -> void:
	_build_stage()
	for i in PEOPLE.size():
		var row := i / 4
		var col := i % 4
		_build_person(PEOPLE[i], Vector3((col - 1.5) * 2.15, 0.0, (row - 0.5) * 2.5))
	if OS.get_environment("CAPTURE_CHARACTERS") == "1":
		_capture_preview()

func _mat(color: Color, roughness := 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m

func _part(parent: Node3D, shape: PrimitiveMesh, material: Material, pos: Vector3, scale := Vector3.ONE, rot := Vector3.ZERO) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.mesh = shape
	mesh.material_override = material
	mesh.position = pos
	mesh.scale = scale
	mesh.rotation = rot
	parent.add_child(mesh)
	return mesh

func _capsule(parent: Node3D, material: Material, pos: Vector3, height: float, radius: float, rot := Vector3.ZERO) -> void:
	var m := CapsuleMesh.new()
	m.radius = radius
	m.height = height
	_part(parent, m, material, pos, Vector3.ONE, rot)

func _build_person(data: Dictionary, origin: Vector3) -> void:
	var actor := CharacterBody3D.new()
	actor.name = str(data.name).replace(" ", "_")
	actor.position = origin
	add_child(actor)

	var collider := CollisionShape3D.new()
	var hitbox := CapsuleShape3D.new()
	hitbox.radius = HITBOX_RADIUS
	hitbox.height = HITBOX_HEIGHT
	collider.shape = hitbox
	collider.position.y = HITBOX_HEIGHT * 0.5
	actor.add_child(collider)

	var skin := _mat(data.skin)
	var hair := _mat(data.hair)
	var shirt := _mat(data.shirt)
	var pants := _mat(data.pants)
	var accent := _mat(data.accent)
	var dark := _mat(Color("#282522"))
	var is_female: bool = str(data["gender"]) == "M"
	var torso_width := 0.34 if is_female else 0.39
	var hip_width := 0.31 if is_female else 0.34

	# Legs: same overall height and foot placement for every character.
	var leg_gap := 0.105
	for side in [-1.0, 1.0]:
		_capsule(actor, pants, Vector3(side * leg_gap, 0.48, 0), 0.78, 0.105)
		_part(actor, BoxMesh.new(), dark, Vector3(side * leg_gap, 0.075, -0.035), Vector3(0.22, 0.12, 0.34))

	# Torso and pelvis; silhouettes vary subtly while the collider stays identical.
	_part(actor, BoxMesh.new(), pants, Vector3(0, 0.91, 0), Vector3(hip_width, 0.28, 0.22))
	_capsule(actor, shirt, Vector3(0, 1.19, 0), 0.66, torso_width * 0.5)
	_part(actor, BoxMesh.new(), accent, Vector3(0, 1.04, -0.118), Vector3(0.12, 0.22, 0.025))

	# Arms.
	for side in [-1.0, 1.0]:
		var arm_pos := Vector3(side * (torso_width * 0.5 + 0.105), 1.19, 0)
		_capsule(actor, shirt, arm_pos, 0.61, 0.085, Vector3(0, 0, side * -0.08))
		_capsule(actor, skin, Vector3(arm_pos.x + side * -0.025, 0.86, 0), 0.22, 0.065)

	# Neck and head.
	_capsule(actor, skin, Vector3(0, 1.53, 0), 0.18, 0.075)
	var head := SphereMesh.new()
	head.radius = 0.145
	head.height = 0.29
	_part(actor, head, skin, Vector3(0, 1.625, 0))
	# Hair cap and rear volume.
	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.151
	hair_mesh.height = 0.19
	_part(actor, hair_mesh, hair, Vector3(0, 1.704, 0.012), Vector3(1.0, 0.62, 1.0))
	if is_female:
		_capsule(actor, hair, Vector3(0, 1.57, 0.105), 0.32, 0.075)

	# Clothing details distinguish the four survivor archetypes.
	match int(data.style):
		1:
			_part(actor, BoxMesh.new(), accent, Vector3(0, 1.36, -0.13), Vector3(0.34, 0.10, 0.035))
			_capsule(actor, accent, Vector3(0.0, 1.25, 0.14), 0.30, 0.045)
		2:
			for side in [-1.0, 1.0]:
				_part(actor, BoxMesh.new(), accent, Vector3(side * 0.20, 1.28, -0.01), Vector3(0.10, 0.16, 0.20))
			_part(actor, BoxMesh.new(), dark, Vector3(0, 1.03, -0.13), Vector3(0.30, 0.07, 0.035))
		3:
			_part(actor, BoxMesh.new(), accent, Vector3(0, 1.32, -0.14), Vector3(0.24, 0.13, 0.035))
			_part(actor, BoxMesh.new(), dark, Vector3(0, 1.18, -0.14), Vector3(0.07, 0.16, 0.035))

	var label := Label3D.new()
	label.text = str(data.name)
	label.position = Vector3(0, 2.0, 0)
	label.font_size = 32
	label.pixel_size = 0.004
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("#f2eee5")
	actor.add_child(label)

func _build_stage() -> void:
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(12.0, 9.0)
	floor.mesh = plane
	floor.material_override = _mat(Color("#343b3b"))
	floor.position = Vector3(0, -0.025, 0)
	add_child(floor)

	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#20282b")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#b7c3c4")
	environment.ambient_light_energy = 0.65
	env.environment = environment
	add_child(env)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48, -28, 0)
	key.light_energy = 1.35
	key.shadow_enabled = true
	add_child(key)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 5.9, 10.8)
	camera.rotation_degrees = Vector3(-27, 0, 0)
	camera.fov = 48
	camera.current = true
	add_child(camera)

	# Shared scale reference line behind the lineup.
	for x in [-4.84, -2.69, -0.54, 1.61, 3.76]:
		var marker := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.012, 0.008, 5.4)
		marker.mesh = box
		marker.material_override = _mat(Color("#657171"))
		marker.position = Vector3(x, 0.002, 0)
		add_child(marker)

func _capture_preview() -> void:
	await get_tree().create_timer(2.0).timeout
	var image := get_viewport().get_texture().get_image()
	image.save_png("res://Screenshots/eight_characters_godot.png")
	get_tree().quit()

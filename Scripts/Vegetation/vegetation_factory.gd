@tool
class_name VegetationFactory
extends Node3D
## Builds reusable procedural 3D trees and harvestable shrubs for Godot 4.4.1.

const TREES := [
	{"id":"TREE_01_PINE","name":"Pino","kind":"pine","height":5.8,"color":"#315b3b"},
	{"id":"TREE_02_OAK","name":"Roble","kind":"oak","height":5.2,"color":"#477b39"},
	{"id":"TREE_03_BIRCH","name":"Abedul","kind":"birch","height":5.0,"color":"#6b9148"},
	{"id":"TREE_04_WILLOW","name":"Sauce","kind":"willow","height":5.1,"color":"#789b3c"},
	{"id":"TREE_05_PALM","name":"Palmera","kind":"palm","height":6.2,"color":"#39834a"},
	{"id":"TREE_06_DEAD","name":"Árbol muerto","kind":"dead","height":4.7,"color":"#786044"},
	{"id":"TREE_07_MAPLE","name":"Arce otoñal","kind":"maple","height":5.3,"color":"#c65a24"},
	{"id":"TREE_08_BANANA","name":"Banano","kind":"banana","height":4.2,"color":"#5b9b32"},
	{"id":"TREE_09_CYPRESS","name":"Ciprés","kind":"cypress","height":6.0,"color":"#28543d"},
	{"id":"TREE_10_ACACIA","name":"Acacia","kind":"acacia","height":4.8,"color":"#789448"},
	{"id":"TREE_11_SNOW_PINE","name":"Pino nevado","kind":"snow","height":5.7,"color":"#456d55"},
	{"id":"TREE_12_CHERRY","name":"Cerezo","kind":"cherry","height":5.0,"color":"#e8a5c2"},
	{"id":"TREE_13_JUNGLE","name":"Árbol de jungla","kind":"jungle","height":6.4,"color":"#347343"},
	{"id":"TREE_14_FRUIT","name":"Árbol frutal","kind":"fruit","height":4.8,"color":"#4f8735"},
	{"id":"TREE_15_DESERT","name":"Árbol desértico","kind":"desert","height":4.2,"color":"#9a8a55"}
]
const BUSHES := [
	{"id":"BUSH_01_FIBER","name":"Arbusto de tela","resource":"cloth","minimum":2,"maximum":5},
	{"id":"BUSH_02_FOOD","name":"Arbusto de comida","resource":"food","minimum":3,"maximum":6}
]
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	_build_gallery()

func create_asset(asset_id: String) -> Node3D:
	return create_tree(asset_id) if asset_id.begins_with("TREE_") else create_bush(asset_id)

func create_tree(asset_id: String) -> Node3D:
	var data := _tree_data(asset_id)
	if data.is_empty():
		push_error("Unknown tree: " + asset_id)
		return Node3D.new()
	rng.seed = abs(hash(asset_id))
	var root := Node3D.new()
	root.name = asset_id
	root.set_meta("asset_id", asset_id)
	root.set_meta("asset_type", "tree")
	root.set_meta("harvestable", false)
	var height: float = data["height"]
	var bark := _mat("#69503a")
	if data["kind"] == "birch":
		bark = _mat("#e6e2d0")
	var foliage := _mat(data["color"])
	_add_trunk(root, height, bark)
	match data["kind"]:
		"pine", "snow", "cypress":
			_build_conifer(root, height, bark, foliage, data["kind"])
		"palm":
			_build_palm(root, height, bark, foliage)
		"banana":
			_build_banana(root, height, bark, foliage)
		"dead":
			_build_dead(root, height, bark)
		"desert":
			_build_desert(root, height, bark, foliage)
		_:
			_build_broadleaf(root, height, bark, foliage, data["kind"])
	_add_tree_collision(root, height)
	return root

func create_bush(asset_id: String) -> Node3D:
	var data := _bush_data(asset_id)
	if data.is_empty():
		push_error("Unknown bush: " + asset_id)
		return Node3D.new()
	rng.seed = abs(hash(asset_id))
	var root := Node3D.new()
	root.name = asset_id
	root.set_meta("asset_id", asset_id)
	root.set_meta("asset_type", "bush")
	root.set_meta("harvestable", true)
	root.set_meta("resource_type", data["resource"])
	root.set_meta("resource_label", "Tela" if data["resource"] == "cloth" else "Comida")
	root.set_meta("yield_min", data["minimum"])
	root.set_meta("yield_max", data["maximum"])
	_build_bush_mesh(root, data["resource"])
	_add_bush_collision(root)
	return root

func _tree_data(asset_id: String) -> Dictionary:
	for data in TREES:
		if data["id"] == asset_id:
			return data
	return {}

func _bush_data(asset_id: String) -> Dictionary:
	for data in BUSHES:
		if data["id"] == asset_id:
			return data
	return {}

func _mat(hex: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(hex)
	material.roughness = 0.92
	return material

func _sphere() -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 10
	mesh.rings = 6
	return mesh

func _mesh(parent: Node3D, mesh: Mesh, material: Material, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(node)
	return node

func _cluster(parent: Node3D, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var node := _mesh(parent, _sphere(), material, pos)
	node.scale = size
	node.rotation_degrees = Vector3(rng.randf_range(-12.0, 12.0), rng.randf_range(0.0, 360.0), rng.randf_range(-12.0, 12.0))
	return node

func _cone(parent: Node3D, pos: Vector3, radius: float, height: float, material: Material) -> void:
	var mesh := ConeMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = 0.025
	mesh.height = height
	mesh.radial_segments = 10
	_mesh(parent, mesh, material, pos)

func _branch(parent: Node3D, a: Vector3, b: Vector3, base: float, tip: float, material: Material) -> void:
	var axis := b - a
	if axis.length() < 0.02:
		return
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = maxf(base, 0.012)
	mesh.top_radius = maxf(tip, 0.008)
	mesh.height = axis.length()
	mesh.radial_segments = 7
	var node := _mesh(parent, mesh, material, (a + b) * 0.5)
	node.quaternion = Quaternion(Vector3.UP, axis.normalized())

func _add_trunk(root: Node3D, height: float, bark: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.105
	mesh.bottom_radius = 0.265
	mesh.height = height * 0.74
	mesh.radial_segments = 10
	_mesh(root, mesh, bark, Vector3(0.0, height * 0.37, 0.0))

func _build_conifer(root: Node3D, height: float, bark: Material, leaves: Material, kind: String) -> void:
	var tiers := 8 if kind == "cypress" else 6
	for level in range(tiers):
		var t := float(level) / float(maxi(1, tiers - 1))
		var y := height * (0.34 + t * 0.54)
		var spread := (0.92 if kind == "cypress" else 1.48) * (1.0 - t) + 0.16
		var cone_h := (1.12 if kind != "cypress" else 0.92) * (1.0 - t * 0.32)
		_cone(root, Vector3(0.0, y, 0.0), spread, cone_h, leaves)
		if kind == "snow":
			_cone(root, Vector3(0.0, y + cone_h * 0.22, 0.0), spread * 0.72, cone_h * 0.48, _mat("#e9eeee"))
		var branch_count := 5 if kind == "cypress" else 7
		for j in range(branch_count):
			var angle := TAU * float(j) / float(branch_count) + float(level) * 0.31
			var direction := Vector3(cos(angle), 0.0, sin(angle))
			var end := Vector3(direction.x * spread * 0.88, y - cone_h * 0.23, direction.z * spread * 0.88)
			_branch(root, Vector3(0.0, y + 0.10, 0.0), end, 0.075 * (1.0 - t) + 0.018, 0.014, bark)
			_cluster(root, end, Vector3(0.22, 0.12, 0.34), leaves)

func _build_palm(root: Node3D, height: float, bark: Material, leaves: Material) -> void:
	for segment in range(5):
		var t0 := float(segment) / 5.0
		var t1 := float(segment + 1) / 5.0
		var a := Vector3(sin(t0 * 1.2) * 0.16, height * 0.74 * t0, 0.0)
		var b := Vector3(sin(t1 * 1.2) * 0.16, height * 0.74 * t1, 0.0)
		_branch(root, a, b, 0.24 - t0 * 0.10, 0.20 - t1 * 0.10, bark)
	var crown := Vector3(0.0, height * 0.74, 0.0)
	for frond in range(9):
		var angle := TAU * float(frond) / 9.0
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		var middle := crown + direction * 1.05 + Vector3(0.0, 0.34, 0.0)
		var tip := crown + direction * 2.25 + Vector3(0.0, -0.64, 0.0)
		_branch(root, crown, middle, 0.07, 0.035, leaves)
		_branch(root, middle, tip, 0.035, 0.012, leaves)
		for leaflet in range(1, 7):
			var t := float(leaflet) / 7.0
			var center := middle.lerp(tip, t)
			for side in [-1.0, 1.0]:
				var lateral := Vector3(-direction.z * side, 0.0, direction.x * side)
				var leaf := _cluster(root, center + lateral * (0.30 + t * 0.18), Vector3(0.075, 0.055, 0.43), leaves)
				leaf.rotation_degrees.y = rad_to_deg(angle) + (90.0 if side > 0.0 else -90.0)

func _build_banana(root: Node3D, height: float, bark: Material, leaves: Material) -> void:
	var crown := Vector3(0.0, height * 0.73, 0.0)
	for j in range(8):
		var angle := TAU * float(j) / 8.0
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		var mid := crown + direction * 0.72 + Vector3(0.0, 0.12, 0.0)
		var tip := crown + direction * rng.randf_range(1.65, 2.05) + Vector3(0.0, rng.randf_range(-0.55, 0.05), 0.0)
		_branch(root, crown, tip, 0.055, 0.012, leaves)
		var blade := _cluster(root, mid.lerp(tip, 0.52), Vector3(0.29, 0.045, 1.28), leaves)
		blade.rotation_degrees.y = rad_to_deg(angle)
		blade.rotation_degrees.z = rng.randf_range(-13.0, 13.0)
	_cluster(root, Vector3(0.0, height * 0.18, 0.0), Vector3(0.37, 0.55, 0.37), _mat("#4f7d32"))

func _build_dead(root: Node3D, height: float, bark: Material) -> void:
	var crown := Vector3(0.0, height * 0.68, 0.0)
	for j in range(7):
		var angle := TAU * float(j) / 7.0 + rng.randf_range(-0.2, 0.2)
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		var start := crown + Vector3(0.0, rng.randf_range(-0.45, 0.35), 0.0)
		var end := start + direction * rng.randf_range(0.85, 1.55) + Vector3(0.0, rng.randf_range(0.35, 1.05), 0.0)
		_branch(root, start, end, 0.105, 0.035, bark)
		var fork := end + direction * rng.randf_range(0.25, 0.55) + Vector3(0.0, rng.randf_range(0.25, 0.52), 0.0)
		_branch(root, end, fork, 0.04, 0.012, bark)
	_branch(root, crown, crown + Vector3(0.12, height * 0.26, 0.0), 0.13, 0.055, bark)

func _build_desert(root: Node3D, height: float, bark: Material, leaves: Material) -> void:
	for j in range(5):
		var angle := TAU * float(j) / 5.0
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		var start := Vector3(0.0, height * rng.randf_range(0.42, 0.67), 0.0)
		var end := start + direction * rng.randf_range(0.8, 1.25) + Vector3(0.0, rng.randf_range(0.15, 0.6), 0.0)
		_branch(root, start, end, 0.075, 0.02, bark)
		_cluster(root, end, Vector3(0.30, 0.20, 0.28), leaves)
		_cluster(root, end + direction * 0.24, Vector3(0.20, 0.14, 0.22), leaves)

func _build_broadleaf(root: Node3D, height: float, bark: Material, leaves: Material, kind: String) -> void:
	var crown_y := height * 0.78
	var branch_count := 9 if kind == "willow" else 7
	for j in range(branch_count):
		var angle := TAU * float(j) / float(branch_count)
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		var start := Vector3(0.0, height * 0.48, 0.0)
		var finish := Vector3(direction.x * rng.randf_range(0.88, 1.38), crown_y + rng.randf_range(-0.38, 0.34), direction.z * rng.randf_range(0.88, 1.38))
		_branch(root, start, finish, 0.105, 0.035, bark)
		if kind == "willow":
			var droop := finish + direction * 0.25 + Vector3(0.0, -height * 0.24, 0.0)
			_branch(root, finish, droop, 0.035, 0.012, bark)
			for k in range(5):
				var p := finish.lerp(droop, float(k + 1) / 6.0)
				_cluster(root, p, Vector3(0.18, 0.28, 0.18), leaves)

	var canopy_count := 16
	if kind == "desert":
		canopy_count = 4
	elif kind == "acacia":
		canopy_count = 12
	elif kind == "cherry":
		canopy_count = 21
	for j in range(canopy_count):
		var angle := TAU * float(j) / float(canopy_count) + rng.randf_range(-0.18, 0.18)
		var radius := rng.randf_range(0.15, 1.30)
		var y := crown_y + rng.randf_range(-0.52, 0.45)
		var pos := Vector3(cos(angle) * radius, y, sin(angle) * radius)
		var size := Vector3(rng.randf_range(0.52, 0.86), rng.randf_range(0.38, 0.62), rng.randf_range(0.50, 0.84))
		if kind == "acacia":
			size = Vector3(rng.randf_range(0.76, 1.05), 0.27, rng.randf_range(0.72, 1.02))
			pos.y = crown_y
		elif kind == "maple":
			size *= Vector3(1.16, 0.90, 1.16)
		elif kind == "birch":
			size *= Vector3(0.86, 1.03, 0.86)
		elif kind == "jungle":
			size *= Vector3(1.12, 1.12, 1.12)
		_cluster(root, pos, size, leaves)

	if kind == "birch":
		var dark := _mat("#3e3d36")
		for j in range(7):
			var y := height * (0.13 + float(j) * 0.075)
			var radius := lerpf(0.235, 0.15, float(j) / 7.0)
			var band := CylinderMesh.new()
			band.top_radius = radius
			band.bottom_radius = radius
			band.height = 0.035
			band.radial_segments = 10
			_mesh(root, band, dark, Vector3(0.0, y, 0.0))
	if kind == "cherry":
		var blossom := _mat("#f4c1d4")
		for group in range(15):
			var a := rng.randf_range(0.0, TAU)
			var pos := Vector3(cos(a) * rng.randf_range(0.25, 1.15), crown_y + rng.randf_range(-0.35, 0.45), sin(a) * rng.randf_range(0.25, 1.15))
			for petal in range(5):
				var pa := TAU * float(petal) / 5.0
				_cluster(root, pos + Vector3(cos(pa) * 0.11, 0.0, sin(pa) * 0.11), Vector3(0.105, 0.075, 0.10), blossom)
	if kind == "fruit":
		var fruit := _mat("#d94b32")
		for j in range(15):
			var a := rng.randf_range(0.0, TAU)
			var pos := Vector3(cos(a) * rng.randf_range(0.45, 1.08), crown_y + rng.randf_range(-0.42, 0.35), sin(a) * rng.randf_range(0.45, 1.08))
			_cluster(root, pos, Vector3.ONE * 0.115, fruit)
	if kind == "jungle":
		var vine := _mat("#52713b")
		for j in range(5):
			var a := TAU * float(j) / 5.0
			_branch(root, Vector3(cos(a) * 0.42, height * 0.88, sin(a) * 0.42), Vector3(cos(a) * 0.78, height * 0.40, sin(a) * 0.78), 0.035, 0.012, vine)
			_branch(root, Vector3(0.0, 0.65, 0.0), Vector3(cos(a) * 0.9, 0.08, sin(a) * 0.9), 0.18, 0.035, bark)

func _build_bush_mesh(root: Node3D, resource: String) -> void:
	var green := _mat("#728d45" if resource == "cloth" else "#4f8738")
	var pale := _mat("#9dad61")
	var stem := _mat("#756044")
	for j in range(9):
		var a := TAU * float(j) / 9.0
		var direction := Vector3(cos(a), 0.0, sin(a))
		var end := Vector3(direction.x * rng.randf_range(0.38, 0.68), rng.randf_range(0.55, 0.92), direction.z * rng.randf_range(0.38, 0.68))
		_branch(root, Vector3(0.0, 0.12, 0.0), end, 0.035, 0.012, stem)
		for k in range(3):
			var p := end.lerp(Vector3.ZERO, float(k + 1) / 4.0)
			var leaf := _cluster(root, p, Vector3(0.19, 0.095, 0.28), green if k % 2 == 0 else pale)
			leaf.rotation_degrees.y = rad_to_deg(a)
	if resource == "cloth":
		var fibers := _mat("#b7bd79")
		for j in range(30):
			var a := rng.randf_range(0.0, TAU)
			var r := rng.randf_range(0.12, 0.55)
			var base := Vector3(cos(a) * r, 0.13, sin(a) * r)
			var tip := base + Vector3(cos(a) * rng.randf_range(0.18, 0.42), rng.randf_range(0.38, 0.72), sin(a) * rng.randf_range(0.18, 0.42))
			_branch(root, base, tip, 0.018, 0.004, fibers)
	else:
		var red := _mat("#c73542")
		var purple := _mat("#713b68")
		for j in range(22):
			var a := rng.randf_range(0.0, TAU)
			var r := rng.randf_range(0.18, 0.62)
			var pos := Vector3(cos(a) * r, rng.randf_range(0.38, 0.86), sin(a) * r)
			_cluster(root, pos, Vector3.ONE * rng.randf_range(0.07, 0.105), red if j % 3 != 0 else purple)

func _add_tree_collision(root: Node3D, height: float) -> void:
	var body := StaticBody3D.new()
	body.name = "TrunkCollision"
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.25
	capsule.height = height * 0.70
	collision.shape = capsule
	collision.position.y = height * 0.35
	body.add_child(collision)
	root.add_child(body)

func _add_bush_collision(root: Node3D) -> void:
	var body := StaticBody3D.new()
	body.name = "BushCollision"
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.72
	collision.shape = shape
	collision.position.y = 0.46
	body.add_child(collision)
	root.add_child(body)

func _build_gallery() -> void:
	_build_stage()
	for index in range(TREES.size()):
		var data: Dictionary = TREES[index]
		var model := create_tree(data["id"])
		model.position = Vector3(float(index % 5) * 4.7 - 9.4, 0.0, float(floori(float(index) / 5.0)) * 6.8 - 6.8)
		add_child(model)
	for index in range(BUSHES.size()):
		var data: Dictionary = BUSHES[index]
		var model := create_bush(data["id"])
		model.position = Vector3(-2.5 + float(index) * 5.0, 0.0, 13.4)
		add_child(model)
	if OS.get_environment("CAPTURE_VEGETATION") == "1":
		_capture_preview.call_deferred()

func _build_stage() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#aebdc0")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#dce5df")
	environment.ambient_light_energy = 0.82
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)
	var ground := PlaneMesh.new()
	ground.size = Vector2(38.0, 34.0)
	var floor_node := MeshInstance3D.new()
	floor_node.mesh = ground
	floor_node.position = Vector3(0.0, -0.08, 3.3)
	floor_node.material_override = _mat("#777d70")
	add_child(floor_node)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 27.5
	camera.position = Vector3(0.0, 22.0, 35.0)
	add_child(camera)
	camera.look_at(Vector3(0.0, 2.4, 3.4), Vector3.UP)
	camera.current = true

func _capture_preview() -> void:
	await get_tree().create_timer(3.0).timeout
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://Screenshots/vegetation_gallery_godot.png")
	var error := image.save_png(path)
	print("VEGETATION_CAPTURE path=", path, " error=", error, " size=", image.get_size())
	get_tree().quit(0)

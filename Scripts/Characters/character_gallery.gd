extends Node3D

# Character showcase rebuilt with continuous procedural surfaces rather than primitive body parts.
# The same dimensions and collision capsule are shared by all eight cosmetic skins.
const PLAYER_HEIGHT := 1.75
const HITBOX_RADIUS := 0.32
const HITBOX_HEIGHT := 1.75
const RADIAL_SEGMENTS := 32

const SKINS := [
	{"name":"SKIN 01","body":"male","skin":Color("#b87954"),"hair":Color("#30231e"),"shorts":Color("#393d39"),"bra":Color("#777b63"),"style":0,"build":0},
	{"name":"SKIN 02","body":"female","skin":Color("#d49a70"),"hair":Color("#4b3025"),"shorts":Color("#66513b"),"bra":Color("#526c59"),"style":0,"build":1},
	{"name":"SKIN 03","body":"male","skin":Color("#a96f50"),"hair":Color("#211e1b"),"shorts":Color("#303831"),"bra":Color("#414b43"),"style":1,"build":2},
	{"name":"SKIN 04","body":"female","skin":Color("#c58b68"),"hair":Color("#382a22"),"shorts":Color("#414b5a"),"bra":Color("#a45e37"),"style":1,"build":3},
	{"name":"SKIN 05","body":"male","skin":Color("#e0b18f"),"hair":Color("#38251f"),"shorts":Color("#4c4648"),"bra":Color("#806b65"),"style":2,"build":4},
	{"name":"SKIN 06","body":"female","skin":Color("#bd8768"),"hair":Color("#251c19"),"shorts":Color("#514c3c"),"bra":Color("#687b63"),"style":2,"build":5},
	{"name":"SKIN 07","body":"male","skin":Color("#9d684e"),"hair":Color("#211c1a"),"shorts":Color("#303831"),"bra":Color("#414b43"),"style":3,"build":6},
	{"name":"SKIN 08","body":"female","skin":Color("#d8a17f"),"hair":Color("#67402d"),"shorts":Color("#414b5a"),"bra":Color("#a45e37"),"style":3,"build":7}
]

func _ready() -> void:
	print("CHARACTER_GALLERY_REBUILT_READY skins=", SKINS.size())
	_build_stage()
	for i in SKINS.size():
		var row := i / 4
		var col := i % 4
		_build_character(SKINS[i], Vector3((col - 1.5) * 2.25, 0.0, (row - 0.5) * 2.35))
	if OS.get_environment("CAPTURE_CHARACTERS") == "1":
		call_deferred("_capture_preview")


func _material(color: Color, roughness: float = 0.82, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m


func _catmull4(a: Vector4, b: Vector4, c: Vector4, d: Vector4, t: float) -> Vector4:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * ((2.0 * b) + (-a + c) * t + (2.0 * a - 5.0 * b + 4.0 * c - d) * t2 + (-a + 3.0 * b - 3.0 * c + d) * t3)


func _create_mesh(parent: Node3D, mesh_name: String, vertices: PackedVector3Array, indices: PackedInt32Array, material: Material) -> MeshInstance3D:
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	for i in range(normals.size()):
		normals[i] = Vector3.ZERO
	for i in range(0, indices.size(), 3):
		var ia := indices[i]
		var ib := indices[i + 1]
		var ic := indices[i + 2]
		var n := (vertices[ib] - vertices[ia]).cross(vertices[ic] - vertices[ia])
		normals[ia] += n
		normals[ib] += n
		normals[ic] += n
	for i in range(normals.size()):
		normals[i] = normals[i].normalized()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	instance.mesh = mesh
	instance.material_override = material
	parent.add_child(instance)
	return instance


func _loft(parent: Node3D, mesh_name: String, profile: Array, material: Material, radial: int = RADIAL_SEGMENTS, subdivisions: int = 4) -> MeshInstance3D:
	var rings: Array[Vector4] = []
	for i in range(profile.size() - 1):
		var p0: Vector4 = profile[maxi(i - 1, 0)]
		var p1: Vector4 = profile[i]
		var p2: Vector4 = profile[i + 1]
		var p3: Vector4 = profile[mini(i + 2, profile.size() - 1)]
		for step in range(subdivisions):
			rings.append(_catmull4(p0, p1, p2, p3, float(step) / float(subdivisions)))
	rings.append(profile[profile.size() - 1])
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	for ring in rings:
		for j in range(radial):
			var angle := TAU * float(j) / float(radial)
			vertices.append(Vector3(ring.y * sin(angle), ring.x, ring.w + ring.z * cos(angle)))
	for i in range(rings.size() - 1):
		for j in range(radial):
			var a := i * radial + j
			var d := i * radial + ((j + 1) % radial)
			var c := (i + 1) * radial + ((j + 1) % radial)
			var b := (i + 1) * radial + j
			indices.append_array(PackedInt32Array([a, d, c, a, c, b]))
	return _create_mesh(parent, mesh_name, vertices, indices, material)


func _ellipsoid(parent: Node3D, mesh_name: String, center: Vector3, radii: Vector3, material: Material, segments: int = 24) -> MeshInstance3D:
	var profile: Array[Vector4] = []
	var latitude_count := 18
	for i in range(1, latitude_count):
		var latitude := -PI * 0.5 + PI * float(i) / float(latitude_count)
		var c := cos(latitude)
		profile.append(Vector4(center.y + radii.y * sin(latitude), maxf(0.002, radii.x * c), maxf(0.002, radii.z * c), center.z))
	return _loft(parent, mesh_name, profile, material, segments, 1)


func _tube(parent: Node3D, mesh_name: String, points: PackedVector3Array, radii: PackedVector2Array, material: Material, radial: int = 12, subdivisions: int = 4) -> MeshInstance3D:
	var centers := PackedVector3Array()
	var sizes := PackedVector2Array()
	for i in range(points.size() - 1):
		for step in range(subdivisions):
			var t := float(step) / float(subdivisions)
			centers.append(points[i].lerp(points[i + 1], t))
			sizes.append(radii[i].lerp(radii[i + 1], t))
	centers.append(points[points.size() - 1])
	sizes.append(radii[radii.size() - 1])
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	for i in range(centers.size()):
		var tangent: Vector3
		if i == 0:
			tangent = (centers[1] - centers[0]).normalized()
		elif i == centers.size() - 1:
			tangent = (centers[i] - centers[i - 1]).normalized()
		else:
			tangent = (centers[i + 1] - centers[i - 1]).normalized()
		var reference := Vector3.FORWARD
		if absf(tangent.dot(reference)) > 0.92:
			reference = Vector3.RIGHT
		var side := tangent.cross(reference).normalized()
		var front := side.cross(tangent).normalized()
		for j in range(radial):
			var angle := TAU * float(j) / float(radial)
			var offset := side * cos(angle) * sizes[i].x + front * sin(angle) * sizes[i].y
			vertices.append(centers[i] + offset)
	for i in range(centers.size() - 1):
		for j in range(radial):
			var a := i * radial + j
			var d := i * radial + ((j + 1) % radial)
			var c := (i + 1) * radial + ((j + 1) % radial)
			var b := (i + 1) * radial + j
			indices.append_array(PackedInt32Array([a, d, c, a, c, b]))
	return _create_mesh(parent, mesh_name, vertices, indices, material)


func _path(points: Array[Vector3]) -> PackedVector3Array:
	var result := PackedVector3Array()
	for p in points:
		result.append(p)
	return result


func _radii(values: Array[Vector2]) -> PackedVector2Array:
	var result := PackedVector2Array()
	for v in values:
		result.append(v)
	return result


func _build_character(data: Dictionary, origin: Vector3) -> void:
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

	var skin: Material = _material(data.skin, 0.72)
	var hair: Material = _material(data.hair, 0.9)
	var hair_highlight: Material = _material(data.hair.lightened(0.09), 0.88)
	var shorts: Material = _material(data.shorts, 0.93)
	var dark: Material = _material(Color("#282321"), 0.78)
	var female := str(data.body) == "female"
	var build := int(data.build)
	var body_width := 1.0 + float(build % 3) * 0.025
	var hip_width := 1.0 + float(build % 2) * 0.035

	_build_legs(player, skin, female, body_width)
	_build_shorts(player, shorts, hip_width)
	_build_torso(player, skin, female, body_width, hip_width)
	_build_arms(player, skin, female, body_width)
	_build_head(player, skin, hair, hair_highlight, dark, female, int(data.style))
	if female:
		_build_sports_bra(player, skin, data.bra, build)
		_build_long_hair(player, hair, hair_highlight, int(data.style), build)
	else:
		_build_short_hair(player, hair, hair_highlight, int(data.style), build)

	var label := Label3D.new()
	label.text = str(data.name)
	label.position = Vector3(0, 1.94, 0)
	label.font_size = 30
	label.pixel_size = 0.004
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("#f2eee5")
	player.add_child(label)


func _build_legs(player: Node3D, skin: Material, female: bool, width_scale: float) -> void:
	var hip := 0.105 if female else 0.095
	var calf := 0.070 if female else 0.075
	for side in [-1.0, 1.0]:
		var x: float = side * (0.105 if female else 0.095) * width_scale
		_tube(player, "Thigh", _path([Vector3(x, 0.83, 0), Vector3(x * 1.02, 0.67, 0.005), Vector3(x * 1.05, 0.48, 0.008)]), _radii([Vector2(hip, hip * 0.92), Vector2(hip * 0.86, hip * 0.82), Vector2(0.073, 0.075)]), skin, 20, 6)
		_tube(player, "Calf", _path([Vector3(x * 1.05, 0.49, 0.008), Vector3(x * 1.04, 0.31, -0.005), Vector3(x * 1.03, 0.13, -0.015)]), _radii([Vector2(0.073, 0.075), Vector2(calf, calf * 0.9), Vector2(0.052, 0.057)]), skin, 18, 6)
		_ellipsoid(player, "Foot", Vector3(x * 1.03, 0.075, 0.065), Vector3(0.066, 0.060, 0.135), skin, 20)


func _build_shorts(player: Node3D, material: Material, width_scale: float) -> void:
	_loft(player, "Survival_Shorts", [
		Vector4(0.655, 0.185 * width_scale, 0.145, 0.0),
		Vector4(0.690, 0.202 * width_scale, 0.151, 0.0),
		Vector4(0.805, 0.218 * width_scale, 0.155, 0.0),
		Vector4(0.905, 0.192 * width_scale, 0.135, 0.0)
	], material, 36, 5)
	_loft(player, "Shorts_Waistband", [
		Vector4(0.875, 0.194 * width_scale, 0.138, 0.0),
		Vector4(0.902, 0.194 * width_scale, 0.138, 0.0),
		Vector4(0.922, 0.186 * width_scale, 0.132, 0.0)
	], _material(material.albedo_color.darkened(0.10), 0.94), 36, 3)


func _build_torso(player: Node3D, skin: Material, female: bool, width_scale: float, hip_scale: float) -> void:
	if female:
		_loft(player, "Anatomical_Torso", [
			Vector4(0.805, 0.175 * hip_scale, 0.118, 0.0),
			Vector4(0.875, 0.186 * hip_scale, 0.119, 0.0),
			Vector4(0.985, 0.158 * width_scale, 0.102, 0.0),
			Vector4(1.105, 0.153 * width_scale, 0.105, 0.0),
			Vector4(1.215, 0.174 * width_scale, 0.120, 0.0),
			Vector4(1.315, 0.194 * width_scale, 0.137, 0.0),
			Vector4(1.405, 0.198 * width_scale, 0.121, 0.0),
			Vector4(1.455, 0.142, 0.092, 0.0)
		], skin, 40, 5)
	else:
		_loft(player, "Anatomical_Torso", [
			Vector4(0.805, 0.166 * hip_scale, 0.116, 0.0),
			Vector4(0.900, 0.177 * hip_scale, 0.119, 0.0),
			Vector4(1.015, 0.171 * width_scale, 0.108, 0.0),
			Vector4(1.125, 0.180 * width_scale, 0.118, 0.0),
			Vector4(1.245, 0.207 * width_scale, 0.132, 0.0),
			Vector4(1.355, 0.231 * width_scale, 0.139, 0.0),
			Vector4(1.425, 0.219 * width_scale, 0.115, 0.0),
			Vector4(1.465, 0.145, 0.091, 0.0)
		], skin, 40, 5)
	_loft(player, "Neck", [
		Vector4(1.425, 0.067, 0.071, 0.0),
		Vector4(1.485, 0.064, 0.068, 0.0),
		Vector4(1.535, 0.073, 0.073, 0.0)
	], skin, 28, 4)


func _build_arms(player: Node3D, skin: Material, female: bool, width_scale: float) -> void:
	var shoulder := 0.074 if female else 0.086
	var upper := 0.064 if female else 0.071
	var forearm := 0.052 if female else 0.060
	for side in [-1.0, 1.0]:
		var sx: float = side * (0.205 if female else 0.237) * width_scale
		_ellipsoid(player, "Shoulder", Vector3(sx, 1.388, 0), Vector3(shoulder, 0.105, 0.095), skin, 20)
		_tube(player, "Upper_Arm", _path([Vector3(sx, 1.40, 0), Vector3(side * 0.275, 1.245, 0.012), Vector3(side * 0.292, 1.105, 0.018)]), _radii([Vector2(upper, upper), Vector2(upper * 0.91, upper * 0.92), Vector2(0.055, 0.055)]), skin, 18, 5)
		_ellipsoid(player, "Elbow", Vector3(side * 0.292, 1.095, 0.018), Vector3(0.057, 0.061, 0.058), skin, 18)
		_tube(player, "Forearm", _path([Vector3(side * 0.292, 1.09, 0.018), Vector3(side * 0.304, 0.985, 0.030), Vector3(side * 0.304, 0.885, 0.038)]), _radii([Vector2(0.054, 0.055), Vector2(forearm, forearm), Vector2(0.043, 0.045)]), skin, 18, 5)
		_ellipsoid(player, "Hand", Vector3(side * 0.304, 0.845, 0.045), Vector3(0.047, 0.067, 0.035), skin, 18)
		for finger in range(4):
			var fx: float = side * (0.278 + float(finger) * 0.018)
			_tube(player, "Finger", _path([Vector3(fx, 0.835, 0.067), Vector3(fx, 0.795, 0.075)]), _radii([Vector2(0.010, 0.010), Vector2(0.008, 0.008)]), skin, 8, 2)


func _build_head(player: Node3D, skin: Material, hair: Material, hair_highlight: Material, dark: Material, female: bool, style: int) -> void:
	_loft(player, "Head", [
		Vector4(1.505, 0.050, 0.067, 0.012),
		Vector4(1.530, 0.078, 0.085, 0.012),
		Vector4(1.570, 0.101, 0.106, 0.012),
		Vector4(1.625, 0.113, 0.118, 0.012),
		Vector4(1.680, 0.108, 0.115, 0.012),
		Vector4(1.724, 0.085, 0.093, 0.010),
		Vector4(1.748, 0.042, 0.052, 0.008)
	], skin, 36, 5)
	for side in [-1.0, 1.0]:
		_ellipsoid(player, "Ear", Vector3(side * 0.108, 1.603, 0.004), Vector3(0.025, 0.043, 0.027), skin, 16)
		_ellipsoid(player, "Eye_White", Vector3(side * 0.043, 1.635, 0.119), Vector3(0.020, 0.012, 0.009), _material(Color("#eee9df"), 0.36), 16)
		_ellipsoid(player, "Iris", Vector3(side * 0.043, 1.635, 0.128), Vector3(0.008, 0.009, 0.004), _material(Color("#49372b"), 0.35), 12)
		_ellipsoid(player, "Pupil", Vector3(side * 0.043, 1.635, 0.131), Vector3(0.0035, 0.005, 0.002), dark, 10)
		_tube(player, "Eyebrow", _path([Vector3(side * 0.066, 1.657, 0.121), Vector3(side * 0.044, 1.665, 0.127), Vector3(side * 0.023, 1.659, 0.124)]), _radii([Vector2(0.006, 0.004), Vector2(0.007, 0.004), Vector2(0.004, 0.003)]), hair, 8, 3)
	_ellipsoid(player, "Nose", Vector3(0, 1.602, 0.132), Vector3(0.014, 0.026, 0.020), skin, 16)
	_tube(player, "Mouth", _path([Vector3(-0.024, 1.562, 0.119), Vector3(0, 1.557, 0.126), Vector3(0.024, 1.562, 0.119)]), _radii([Vector2(0.0035, 0.003), Vector2(0.0045, 0.003), Vector2(0.0035, 0.003)]), _material(Color("#754b45"), 0.9), 8, 3)


func _front_z(x: float, base: float = 0.0) -> float:
	var normalized_x := clampf(absf(x) / 0.22, 0.0, 0.96)
	return base + 0.135 * sqrt(1.0 - normalized_x * normalized_x)


func _bra_cup(player: Node3D, side: float, material: Material) -> void:
	var center_x := side * 0.092
	var center_y := 1.345
	var rx := 0.092
	var ry := 0.073
	var radial := 10
	var segments := 32
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	vertices.append(Vector3(center_x, center_y, _front_z(center_x) + 0.018))
	for ring in range(1, radial + 1):
		var r := float(ring) / float(radial)
		for j in range(segments):
			var angle := TAU * float(j) / float(segments)
			var x := center_x + cos(angle) * rx * r
			var y := center_y + sin(angle) * ry * r
			var dome := 0.012 * (1.0 - r * r)
			vertices.append(Vector3(x, y, _front_z(x) + dome + 0.018))
	for j in range(segments):
		indices.append_array(PackedInt32Array([0, 1 + j, 1 + ((j + 1) % segments)]))
	for ring in range(radial - 1):
		var base_a := 1 + ring * segments
		var base_b := base_a + segments
		for j in range(segments):
			var a := base_a + j
			var d := base_a + ((j + 1) % segments)
			var b := base_b + j
			var c := base_b + ((j + 1) % segments)
			indices.append_array(PackedInt32Array([a, b, c, a, c, d]))
	_create_mesh(player, "Sports_Bra_Cup", vertices, indices, material)


func _build_sports_bra(player: Node3D, skin: Material, color: Color, build: int) -> void:
	var cloth := _material(color, 0.96)
	var seam := _material(color.darkened(0.16), 0.94)
	_loft(player, "Sports_Bra_Underband", [
		Vector4(1.245, 0.169, 0.123, 0.0),
		Vector4(1.270, 0.176, 0.128, 0.0),
		Vector4(1.292, 0.178, 0.129, 0.0)
	], cloth, 36, 4)
	_bra_cup(player, -1.0, cloth)
	_bra_cup(player, 1.0, cloth)
	_tube(player, "Bra_Center_Join", _path([Vector3(0, 1.285, 0.139), Vector3(0, 1.325, 0.151), Vector3(0, 1.365, 0.145)]), _radii([Vector2(0.010, 0.006), Vector2(0.012, 0.006), Vector2(0.009, 0.005)]), seam, 10, 3)
	for side in [-1.0, 1.0]:
		_tube(player, "Bra_Shoulder_Strap", _path([
			Vector3(side * 0.135, 1.405, 0.112),
			Vector3(side * 0.145, 1.445, 0.082),
			Vector3(side * 0.145, 1.485, 0.012),
			Vector3(side * 0.135, 1.465, -0.080),
			Vector3(side * 0.130, 1.410, -0.112)
		]), _radii([Vector2(0.018, 0.010), Vector2(0.018, 0.010), Vector2(0.017, 0.010), Vector2(0.017, 0.010), Vector2(0.018, 0.010)]), cloth, 10, 4)


func _build_long_hair(player: Node3D, hair: Material, highlight: Material, style: int, build: int) -> void:
	_ellipsoid(player, "Hair_Crown", Vector3(0, 1.704, -0.012), Vector3(0.126, 0.082, 0.132), hair, 28)
	var back_width := 0.142
	if style == 2:
		back_width = 0.125
	elif style == 3:
		back_width = 0.105
	_loft(player, "Long_Hair_Back", [
		Vector4(1.690, 0.105, 0.060, -0.066),
		Vector4(1.585, back_width, 0.079, -0.105),
		Vector4(1.420, back_width * 1.08, 0.070, -0.112),
		Vector4(1.235, back_width * 0.98, 0.061, -0.108),
		Vector4(1.075, back_width * 0.87, 0.046, -0.097)
	], hair, 32, 5)
	for side in [-1.0, 1.0]:
		var x_offset := 0.0
		var z_offset := 0.0
		if style == 1:
			x_offset = side * 0.018
			z_offset = -0.018
		_tube(player, "Long_Face_Fringe", _path([
			Vector3(side * 0.077, 1.690, 0.070),
			Vector3(side * 0.105, 1.615, 0.080),
			Vector3(side * 0.119, 1.495, 0.025),
			Vector3(side * 0.132 + x_offset, 1.315, -0.015 + z_offset),
			Vector3(side * 0.145 + x_offset, 1.105, -0.035 + z_offset)
		]), _radii([Vector2(0.035, 0.027), Vector2(0.030, 0.024), Vector2(0.026, 0.021), Vector2(0.024, 0.019), Vector2(0.012, 0.012)]), hair, 14, 5)
	if style == 0:
		for lock in range(5):
			var x := (float(lock) - 2.0) * 0.047
			_tube(player, "Hair_Lock", _path([Vector3(x * 0.45, 1.56, -0.174), Vector3(x * 0.72, 1.40, -0.183), Vector3(x, 1.22, -0.160), Vector3(x * 0.92, 1.08, -0.135)]), _radii([Vector2(0.018, 0.014), Vector2(0.016, 0.013), Vector2(0.013, 0.011), Vector2(0.004, 0.004)]), highlight if lock % 2 == 0 else hair, 10, 4)
	elif style == 1:
		for lock in range(4):
			var side := -1.0 if lock < 2 else 1.0
			var phase := float(lock) * 0.9
			_tube(player, "Wavy_Hair_Lock", _path([
				Vector3(side * 0.055, 1.57, -0.165),
				Vector3(side * (0.10 + 0.018 * sin(phase)), 1.40, -0.180),
				Vector3(side * (0.12 + 0.020 * cos(phase)), 1.23, -0.158),
				Vector3(side * 0.10, 1.08, -0.135)
			]), _radii([Vector2(0.025, 0.021), Vector2(0.022, 0.018), Vector2(0.017, 0.014), Vector2(0.004, 0.004)]), highlight if lock % 2 == 0 else hair, 12, 5)
	elif style == 2:
		_tube(player, "Long_Braid_Base", _path([Vector3(0, 1.56, -0.176), Vector3(0, 1.40, -0.205), Vector3(0, 1.22, -0.205), Vector3(0, 1.07, -0.170)]), _radii([Vector2(0.035, 0.033), Vector2(0.033, 0.030), Vector2(0.026, 0.024), Vector2(0.006, 0.006)]), hair, 14, 5)
		for knot in range(7):
			var y := 1.50 - float(knot) * 0.062
			var offset := 0.018 if knot % 2 == 0 else -0.018
			_ellipsoid(player, "Braid_Weave", Vector3(offset, y, -0.213), Vector3(0.030, 0.043, 0.024), highlight if knot % 2 == 0 else hair, 14)
	else:
		_tube(player, "Ponytail", _path([Vector3(0, 1.66, -0.11), Vector3(0, 1.57, -0.22), Vector3(0.025, 1.39, -0.27), Vector3(0.040, 1.20, -0.25), Vector3(0.035, 1.08, -0.20)]), _radii([Vector2(0.045, 0.040), Vector2(0.043, 0.038), Vector2(0.034, 0.030), Vector2(0.022, 0.020), Vector2(0.005, 0.005)]), hair, 16, 5)
		_ellipsoid(player, "Ponytail_Tie", Vector3(0, 1.585, -0.19), Vector3(0.045, 0.018, 0.035), highlight, 14)


func _build_short_hair(player: Node3D, hair: Material, highlight: Material, style: int, build: int) -> void:
	_ellipsoid(player, "Hair_Cap", Vector3(0, 1.704, -0.008), Vector3(0.119, 0.079, 0.126), hair, 28)
	var fringe_y := 1.681 - float(style) * 0.006
	_tube(player, "Front_Hairline", _path([Vector3(-0.095, fringe_y, 0.067), Vector3(-0.045, fringe_y - 0.010, 0.112), Vector3(0.012, fringe_y - 0.004, 0.119), Vector3(0.092, fringe_y + 0.006, 0.075)]), _radii([Vector2(0.025, 0.020), Vector2(0.030, 0.020), Vector2(0.028, 0.018), Vector2(0.012, 0.012)]), highlight if style % 2 == 0 else hair, 12, 4)
	for side in [-1.0, 1.0]:
		_loft(player, "Side_Hair", [
			Vector4(1.565, 0.022, 0.027, 0.0),
			Vector4(1.615, 0.035, 0.040, -0.005),
			Vector4(1.670, 0.045, 0.050, -0.012)
		], hair, 16, 3).position.x = side * 0.091
	if style == 1:
		_ellipsoid(player, "Textured_Top", Vector3(0, 1.758, -0.025), Vector3(0.073, 0.026, 0.074), highlight, 20)
	elif style == 2:
		for tuft in range(3):
			var x := (float(tuft) - 1.0) * 0.045
			_tube(player, "Hair_Tuft", _path([Vector3(x, 1.72, 0.015), Vector3(x * 1.1, 1.77, -0.005), Vector3(x * 0.8, 1.755, -0.04)]), _radii([Vector2(0.026, 0.022), Vector2(0.020, 0.018), Vector2(0.004, 0.004)]), hair, 10, 3)
	elif style == 3:
		_tube(player, "Swept_Hair", _path([Vector3(-0.09, 1.69, 0.045), Vector3(-0.03, 1.75, 0.015), Vector3(0.07, 1.75, -0.03)]), _radii([Vector2(0.025, 0.020), Vector2(0.038, 0.027), Vector2(0.005, 0.005)]), highlight, 12, 4)


func _build_stage() -> void:
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(11.5, 8.0)
	floor.mesh = plane
	floor.material_override = _material(Color("#343b3b"))
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
	camera.position = Vector3(0, 4.55, 11.7)
	camera.rotation_degrees = Vector3(-20, 0, 0)
	camera.fov = 39
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

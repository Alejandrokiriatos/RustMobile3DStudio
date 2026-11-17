extends SceneTree
## Structural validation for all 17 3D models.

const Factory = preload("res://Scripts/Vegetation/vegetation_factory.gd")

func _initialize() -> void:
	var builder = Factory.new()
	var failures: Array[String] = []
	var passed := 0
	for data in Factory.TREES:
		var asset: Node3D = builder.create_tree(data["id"])
		if _check_asset(asset, data["id"], false):
			passed += 1
		else:
			failures.append(data["id"])
		asset.free()
	for data in Factory.BUSHES:
		var asset: Node3D = builder.create_bush(data["id"])
		if _check_asset(asset, data["id"], true):
			passed += 1
			if str(asset.get_meta("resource_type", "")) == "" or int(asset.get_meta("yield_min", 0)) > int(asset.get_meta("yield_max", 0)):
				failures.append(data["id"] + "_metadata")
		else:
			failures.append(data["id"])
		asset.free()
	print("VEGETATION_VALIDATION passed=", passed, "/17 failures=", failures)
	quit(0 if failures.is_empty() and passed == 17 else 1)

func _check_asset(asset: Node3D, asset_id: String, harvestable: bool) -> bool:
	if asset == null or str(asset.get_meta("asset_id", "")) != asset_id:
		return false
	if bool(asset.get_meta("harvestable", false)) != harvestable:
		return false
	var meshes := asset.find_children("*", "MeshInstance3D", true, false)
	var collisions := asset.find_children("*", "CollisionShape3D", true, false)
	if meshes.size() < 8 or collisions.is_empty():
		return false
	for child in meshes:
		var mesh_node := child as MeshInstance3D
		if mesh_node == null or mesh_node.mesh == null:
			return false
	return true

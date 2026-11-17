extends SceneTree
## Exports 17 independent GLB assets and imports each output back for validation.

const Factory = preload("res://Scripts/Vegetation/vegetation_factory.gd")

func _initialize() -> void:
	var output_dir := ProjectSettings.globalize_path("res://build/vegetation")
	var mkdir_error := DirAccess.make_dir_recursive_absolute(output_dir)
	if mkdir_error != OK and mkdir_error != ERR_ALREADY_EXISTS:
		push_error("Cannot create export folder: " + error_string(mkdir_error))
		quit(1)
		return
	var builder = Factory.new()
	var failures: Array[String] = []
	var exported := 0
	for data in Factory.TREES:
		if _export_one(builder.create_tree(data["id"]), data["id"], output_dir):
			exported += 1
		else:
			failures.append(data["id"])
	for data in Factory.BUSHES:
		if _export_one(builder.create_bush(data["id"]), data["id"], output_dir):
			exported += 1
		else:
			failures.append(data["id"])
	print("VEGETATION_GLB_EXPORT exported=", exported, "/17 failures=", failures)
	quit(0 if failures.is_empty() and exported == 17 else 1)

func _export_one(model: Node3D, asset_id: String, output_dir: String) -> bool:
	model.name = asset_id
	root.add_child(model)
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var error := document.append_from_scene(model, state)
	var path := output_dir.path_join(asset_id + ".glb")
	if error == OK:
		error = document.write_to_filesystem(state, path)
	root.remove_child(model)
	model.free()
	if error != OK:
		push_error("GLB export failed for " + asset_id + ": " + error_string(error))
		return false
	var check_document := GLTFDocument.new()
	var check_state := GLTFState.new()
	var check_error := check_document.append_from_file(path, check_state)
	if check_error != OK:
		push_error("GLB re-import failed for " + asset_id)
		return false
	var imported := check_document.generate_scene(check_state)
	if imported == null:
		push_error("GLB imported as an empty scene: " + asset_id)
		return false
	imported.free()
	print("VEGETATION_GLB_OK ", asset_id, " bytes=", FileAccess.get_file_as_bytes(path).size())
	return true

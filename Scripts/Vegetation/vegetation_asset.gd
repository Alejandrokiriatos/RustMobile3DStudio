@tool
extends Node3D
## Reusable root: choose any of the 17 IDs in the Inspector.

const Factory = preload("res://Scripts/Vegetation/vegetation_factory.gd")

@export_enum(
	"TREE_01_PINE", "TREE_02_OAK", "TREE_03_BIRCH", "TREE_04_WILLOW",
	"TREE_05_PALM", "TREE_06_DEAD", "TREE_07_MAPLE", "TREE_08_BANANA",
	"TREE_09_CYPRESS", "TREE_10_ACACIA", "TREE_11_SNOW_PINE",
	"TREE_12_CHERRY", "TREE_13_JUNGLE", "TREE_14_FRUIT", "TREE_15_DESERT",
	"BUSH_01_FIBER", "BUSH_02_FOOD"
)
var asset_id: String = "TREE_01_PINE":
	set(value):
		asset_id = value
		if is_inside_tree():
			_rebuild()

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.free()
	var builder = Factory.new()
	var model: Node3D = builder.create_asset(asset_id)
	add_child(model)
	if Engine.is_editor_hint() and get_tree().edited_scene_root != null:
		_set_owner_recursive(model, get_tree().edited_scene_root)

func _set_owner_recursive(node: Node, scene_root: Node) -> void:
	node.owner = scene_root
	for child in node.get_children():
		_set_owner_recursive(child, scene_root)

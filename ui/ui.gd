@tool
class_name _DebugTools_UI
extends Control

const LABEL_LIST_SCENE = preload("label_list.tscn")

var scene_list_map: Dictionary[String, Node]
var current_label_list: _DebugTools_UI_LabelList
const float_format: StringName = &"%*.*f"
const vector_format: StringName = &"%*.*v"

func _format(value: Variant, precision: int) -> String:
	if value is Array or value is PackedFloat32Array:
		return '[%s ]' % ', '.join((value as Array).map(_format.bind(precision)))

	if value is float:
		return float_format % [precision + 3, precision, value]

	if value is Vector2 or value is Vector3 or value is Vector4:
		return vector_format % [precision + 3, precision, value]

	return str(value)

func set_current_scene(scene: Node, ui_node: Control):
	if not scene or scene.scene_file_path.contains('addons/debug-tools'):
		current_label_list = null
	else:
		var key: String = scene.scene_file_path
		if not scene_list_map.has(key):
			scene_list_map[key] = LABEL_LIST_SCENE.instantiate()
			ui_node.add_child(scene_list_map[key])

		current_label_list = scene_list_map[key]

	for list in scene_list_map.values():
		list.visible = list == current_label_list and list.list.size() > 0

func clear_map():
	scene_list_map.clear()

func clear_current_list():
	if is_instance_valid(current_label_list):
		current_label_list.clear()

func clean():
	if is_instance_valid(current_label_list):
		current_label_list.clean()

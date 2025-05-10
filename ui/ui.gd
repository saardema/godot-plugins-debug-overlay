@tool
class_name _DebugTools_UI
extends Node
const LABEL_LIST_SCENE = preload("res://addons/debug-tools/ui/label_list.tscn")
var scene_list_map: Dictionary[String, Node]
var current_label_list: _DebugTools_UI_LabelList

func _on_label_expired(entity: ExpiringEntity.NodeType):
	entity.node.queue_free()

func write(id: String, value: Variant, expires: bool):
	var text: String = str(value)
	if not current_label_list: return
	current_label_list.write(id, text, expires)

func update_current_scene(scene: Node, ui_node: Node):
	if not scene:
		current_label_list = null
		printerr("No scene node provided in UI.gd")
		return

	if scene.scene_file_path.contains('addons/debug-tools'):
		current_label_list = null
	else:
		var key: String = scene.scene_file_path

		if not scene_list_map.has(key):
			scene_list_map[key] = LABEL_LIST_SCENE.instantiate()
			ui_node.add_child(scene_list_map[key])

		current_label_list = scene_list_map[key]

	for list in scene_list_map.values():
		list.visible = list == current_label_list

func clear_map():
	scene_list_map.clear()

func clear_current_list():
	if is_instance_valid(current_label_list):
		current_label_list.clear()

func clean():
	if is_instance_valid(current_label_list):
		current_label_list.clean()

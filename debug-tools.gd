@tool
extends Node3D

const UI_SCENE = preload("res://addons/debug-tools/ui/ui.tscn")

var ui: _DebugTools_UI
var draw3d: _DebugToolsDraw3D
var is_enabled: bool = true
var camera: Camera3D
var ui_node: Control


func _on_plugin_disable() -> void:
	ui.clear_map()
	ui_node.queue_free()


func _enter_tree() -> void:
	if ui_node: return
	ui_node = UI_SCENE.instantiate()
	if Engine.is_editor_hint():
		EditorInterface.get_editor_main_screen().add_child(ui_node)
	else:
		add_child(ui_node)


func _ready():
	camera = _get_camera()
	draw3d = $Draw3D
	ui = $UI
	ui.set_current_scene(get_tree().current_scene, ui_node)
	draw3d.set_current_scene(get_tree().current_scene)


func _process(delta: float) -> void:
	if draw3d.current_lines.size():
		draw3d.draw_lines(camera.position)
		draw3d.clean()

	if ui.current_label_list.count():
		ui.clean()


func write(id: StringName, text: Variant, expires: bool = true, precision: int = 2):
	ui.write(id, text, expires, precision)


func draw_line(id: StringName, p1: Vector3, p2: Vector3, color: Color = Color.RED, thickness: float = 0.01, expires: bool = true):
	draw3d.set_line(id, p1, p2, color, thickness, expires)


func _on_state_change(show: bool):
	ui_node.visible = show


func _get_camera():
	if Engine.is_editor_hint():
		return EditorInterface.get_editor_viewport_3d(0).get_camera_3d()
	if get_viewport().get_camera_3d():
		return get_viewport().get_camera_3d()
	return Camera3D.new()


func _on_scene_changed(scene: Node):
	ui.set_current_scene(scene, ui_node)
	draw3d.set_current_scene(scene)
	camera = _get_camera()

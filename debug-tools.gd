@tool
extends Node3D

const UI_SCENE = preload("res://addons/debug-tools/ui/ui.tscn")

var ui: _DebugTools_UI
var draw3d: Node3D
var is_enabled: bool = true
var camera: Camera3D
var ui_node: Node

func _on_plugin_exit() -> void:
	print("DebugTools exit_tree")
	ui.clear_map()
	ui_node.queue_free()

func _enter_tree() -> void:
	print("DebugTools enter_tree")
	ui_node = UI_SCENE.instantiate()
	if Engine.is_editor_hint():
		EditorInterface.get_editor_viewport_3d().add_child(ui_node)
	else:
		add_child(ui_node)

func _ready():
	camera = _get_camera()
	draw3d = $Draw3D
	ui = $UI
	ui.set_current_scene(get_tree().current_scene, ui_node)
	draw3d.set_current_scene(get_tree().current_scene)
	find_child("CSBridge").call("SetInstance", self )

func _process(delta: float) -> void:
	draw3d.draw_lines(camera.position)
	draw3d.clean()
	ui.clean()

func write(id: StringName, text: Variant, expires: bool = true):
	ui.write(id, text, expires)

func draw_line(id: StringName, p1: Vector3, p2: Vector3, color: Color = Color.RED, thickness: float = 0.01, expires: bool = true):
	draw3d.set_line(id, p1, p2, color, thickness, expires)

func disable():
	print("DebugTools disabled")
	is_enabled = false
	draw3d.visible = false

func enable():
	print("DebugTools enabled")
	is_enabled = true
	draw3d.visible = true

func _get_camera():
	if Engine.is_editor_hint():
		return EditorInterface.get_editor_viewport_3d(0).get_camera_3d()
	if get_viewport():
		return get_viewport().get_camera_3d()
	return null

func on_scene_changed(scene: Node):
	ui.set_current_scene(scene, ui_node)
	draw3d.set_current_scene(scene)
	camera = _get_camera()

func on_screen_changed(screen: String):
	if screen in ['2D', '3D']:
		if not is_enabled: enable()
	elif is_enabled: disable()

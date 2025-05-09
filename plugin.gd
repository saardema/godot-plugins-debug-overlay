@tool
extends EditorPlugin

const AUTOLOAD_NAME = "DebugTools"
const PATH = "res://addons/debug-tools/"
const AUTOLOAD_PATH = PATH + "main.tscn"
var node: Node

func _enable_plugin():
	print("Plugin enabled")
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)

func _disable_plugin():
	print("Plugin disabled")
	remove_autoload_singleton(AUTOLOAD_NAME)

func _enter_tree():
	main_screen_changed.connect(on_main_screen_change)
	scene_changed.connect(on_scene_change)
	print("Tree entered")

func _exit_tree():
	print("Tree exited")

func on_main_screen_change(screen: String):
	if not node: return

	if screen in ['2D', '3D']: node.enable()
	else: node.disable()

func on_scene_change(scene: Node):
	node = get_node_or_null("/root/DebugTools")
	update_position()
	clear()

func clear():
	if node: node.clear()
	else: print("node not found")

func update_position():
	var probe: Node2D = Node2D.new()
	var vp = EditorInterface.get_editor_viewport_3d()
	vp.add_sibling(probe)
	node.reposition(probe.global_position, vp.size)
	probe.queue_free()

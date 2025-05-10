@tool
extends EditorPlugin

const AUTOLOAD_NAME = "DebugTools"
const PATH = "res://addons/debug-tools/"
const AUTOLOAD_PATH = PATH + "debug-tools.tscn"
var node: Node3D

func _enable_plugin():
	print("Plugin enabled")
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)

	main_screen_changed.connect(on_main_screen_changed)
	scene_changed.connect(on_scene_changed)

func _disable_plugin():
	print("Plugin disabled")
	if node: node._on_plugin_exit()
	remove_autoload_singleton(AUTOLOAD_NAME)

#func _enter_tree():
	#print("Plugin tree entered")
#
#func _exit_tree():
	#print("Plugin tree exited")

func on_main_screen_changed(screen: String):
	if node: node.on_screen_changed(screen)

func on_scene_changed(scene: Node):
	node = get_node_or_null("/root/DebugTools")
	if node: node.on_scene_changed(scene)

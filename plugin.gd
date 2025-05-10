@tool
extends EditorPlugin
#const BRIDGE_SCENE = preload("res://addons/debug-tools/src/DebugTools.cs")
const PATH = "res://addons/debug-tools/"
const AUTOLOAD_PATH_MAIN = PATH + "debug-tools.tscn"
const AUTOLOAD_PATH_CS_BRIDGE = PATH + "src/DebugTools.cs"

const AUTOLOAD_NAME_MAIN = "DebugTools"
const AUTOLOAD_NAME_BRIDGE = "DebugToolsCSBridge"

var instance: Node3D
var bridge_instance: Node

func _enable_plugin():
	print("Plugin enabled")

	add_autoload_singleton(AUTOLOAD_NAME_MAIN, AUTOLOAD_PATH_MAIN)

func _enter_tree() -> void:
	main_screen_changed.connect(on_main_screen_changed)
	scene_changed.connect(on_scene_changed)

func _disable_plugin():
	print("Plugin disabled")

	#if instance:
	instance._on_plugin_exit()

	remove_autoload_singleton(AUTOLOAD_NAME_MAIN)
	# remove_autoload_singleton(AUTOLOAD_NAME_BRIDGE)

func on_main_screen_changed(screen: String):
	#if instance:
	instance.on_screen_changed(screen)

func on_scene_changed(scene: Node):
	print("scene change")
	if not instance:
		instance = get_node_or_null("/root/" + AUTOLOAD_NAME_MAIN)

	instance.on_scene_changed(scene)

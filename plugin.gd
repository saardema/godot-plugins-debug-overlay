@tool
extends EditorPlugin

const AUTOLOAD_NAME = "DebugOverlay"

func _enable_plugin():
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/debug-overlay/debug-overlay.tscn")

func _disable_plugin():
	remove_autoload_singleton(AUTOLOAD_NAME)

@tool
class_name DebugToolsPlugin
extends EditorPlugin
const PATH = "res://addons/debug-tools/"
const AUTOLOAD_PATH = PATH + "debug-tools.tscn"
const PLUGIN_NAME = "DebugTools"
const LABEL_SCENE = preload("res://addons/debug-tools/ui/label.tscn")
const SETTINGS_MAP: Dictionary[String, Array] = {
	'write/visibility/show_in_2d_view': [TYPE_BOOL, true, PROPERTY_HINT_NONE, "", '2D'],
	'write/visibility/show_in_3d_view': [TYPE_BOOL, true, PROPERTY_HINT_NONE, "", '3D'],
	'write/visibility/show_in_script_editor': [TYPE_BOOL, false, PROPERTY_HINT_NONE, "", 'Script'],
	'write/font/font_size': [TYPE_INT, 16, PROPERTY_HINT_RANGE, "8,96"],
}

static var config := {'visible_on_screens': []}

var current_screen: String
var instance: Node3D
var bridge_instance: Node

func _enable_plugin():
	#print("Plugin enabled")
	add_autoload_singleton(PLUGIN_NAME, AUTOLOAD_PATH)
	_add_editor_settings()
	_apply_settings()


func _disable_plugin():
	#print("Plugin disabled")
	if instance: instance._on_plugin_disable()

	remove_autoload_singleton(PLUGIN_NAME)
	#_remove_editor_settings()


func _add_editor_settings():
	var settings = EditorInterface.get_editor_settings()

	for key in SETTINGS_MAP:
		var setting_path = PLUGIN_NAME + '/' + key
		var config = SETTINGS_MAP[key]

		settings.set_setting(setting_path, config[1])

		var property_info = {
			"name": setting_path,
			"type": config[0],
			"hint": config[2],
			"hint_string": config[3]
		}

		settings.add_property_info(property_info)
		settings.set_initial_value(setting_path, config[1], false)


func _apply_settings():
	var settings = EditorInterface.get_editor_settings()
	config['visible_on_screens'] = []
	for key in SETTINGS_MAP:
		var setting_path = PLUGIN_NAME + '/' + key
		if key.begins_with('write/visibility/') and settings.get_setting(setting_path):
			config['visible_on_screens'].append(SETTINGS_MAP[key][4])
		config[key] = settings.get_setting(setting_path)

	# Apply visibility of UI
	if current_screen: _on_main_screen_changed(current_screen)

	# Embed font size in label settings, normalized by the editor's display scaling
	var font_size = config['write/font/font_size'] * EditorInterface.get_editor_scale()
	var label_instance: Label = LABEL_SCENE.instantiate()
	label_instance.label_settings.font_size = font_size
	LABEL_SCENE.pack(label_instance)
	ResourceSaver.save(LABEL_SCENE, LABEL_SCENE.resource_path)
	label_instance.queue_free()

func _remove_editor_settings():
	var settings = EditorInterface.get_editor_settings()
	for key in SETTINGS_MAP:
		var setting_path = PLUGIN_NAME + '/' + key
		if settings.has_setting(setting_path):
			settings.erase(setting_path)


func _notification(what: int) -> void:
	if what == EditorSettings.NOTIFICATION_EDITOR_SETTINGS_CHANGED:
		_apply_settings()


func _enter_tree() -> void:
	if not instance:
		instance = get_node_or_null("/root/" + PLUGIN_NAME)

	main_screen_changed.connect(_on_main_screen_changed)
	scene_changed.connect(_on_scene_changed)

	_apply_settings()


func _on_main_screen_changed(screen: String):
	current_screen = screen
	if instance:
		var is_visble: bool = screen in config['visible_on_screens']
		instance._on_state_change(is_visble)


func _on_scene_changed(scene: Node):
	if not instance:
		instance = get_node_or_null("/root/" + PLUGIN_NAME)

	if instance: instance._on_scene_changed(scene)

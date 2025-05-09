@tool
extends Control
@onready var panel_container: PanelContainer = $PanelContainer

@onready var labels: VBoxContainer = $PanelContainer/MarginContainer/LabelContainer
var label_nodes: Dictionary[StringName, ExpiringEntity.NodeType]
var _time_last_cleanup: int
const LABEL = preload("res://addons/debug-tools/ui/label.tscn")

func write(id: String, text: String, expires: bool):
	if not label_nodes.has(id):
		label_nodes[id] = _create_label(expires)
		labels.add_child(label_nodes[id].node)
	else:
		label_nodes[id].keep_alive()

	label_nodes[id].node.text = &"%s: %s" % [id, text]

func _create_label(expires: bool) -> ExpiringEntity.NodeType:
	process_mode = Node.PROCESS_MODE_INHERIT
	var label = LABEL.instantiate()
	var node = ExpiringEntity.NodeType.new(label, expires)

	return node

func _process(delta: float):
	var time := Time.get_ticks_msec()
	if time < _time_last_cleanup + 100: return

	_time_last_cleanup = time

	for id in label_nodes.keys():
		if not label_nodes[id].expires: continue
		if time > label_nodes[id].time_updated + ExpiringEntity.NodeType.lifetime_ms:
			label_nodes[id].node.queue_free()
			label_nodes.erase(id)

	if label_nodes.size() == 0:
		visible = false

func clear():
	for label in label_nodes.values():
		label.node.queue_free()
	label_nodes.clear()

func reposition(pos: Vector2, _size):
	position = pos
	size = _size

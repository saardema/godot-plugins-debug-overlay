@tool
extends Control
class_name _DebugTools_UI_LabelList

const LABEL = preload("res://addons/debug-tools/ui/label.tscn")

var label_container: VBoxContainer
var list: ExpiringEntity.NodeType.List = ExpiringEntity.NodeType.List.new()
var max_id_length: int


func _ready() -> void:
	list.entity_expired.connect(_on_entity_expired)
	label_container = $MarginContainer/PanelContainer/MarginContainer/LabelContainer


func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index <= 2 and event.is_pressed():
			clear()


func _update_max_id_length():
	max_id_length = 0
	for id in list.entities: max_id_length = max(max_id_length, id.length())


func _on_entity_expired(entity: ExpiringEntity.NodeType):
	entity.node.queue_free()
	visible = list.size() > 1
	_update_max_id_length()


func write(id: String, text: String, expires: bool, show_id: bool):
	var label: Label

	if list.has(id):
		var entity = list.fetch(id)
		entity.refresh()
		label = entity.node
		list.update(id, label, expires)
	else:
		label = LABEL.instantiate()
		label_container.add_child(label)
		list.add(id, label, expires)
		var ids := list.entities.keys()
		ids.sort_custom(func(a, b): return a.naturalnocasecmp_to(b) < 0)
		var new_index := ids.find(id)
		label_container.move_child(label, new_index)
		_update_max_id_length()

	label.text = &"%s: %s" % [id, " ".repeat(max_id_length - id.length()) + text] if show_id else text

	visible = list.size() > 0


func count(): return label_container.get_child_count()


func clean(): list.clean()


func clear():
	for child in label_container.get_children():
		child.queue_free()

	list.clear()
	visible = false

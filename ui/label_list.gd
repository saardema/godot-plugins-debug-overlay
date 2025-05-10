@tool
extends Control
class_name _DebugTools_UI_LabelList

var label_container: VBoxContainer
const LABEL = preload("res://addons/debug-tools/ui/label.tscn")
var list: ExpiringEntity.NodeType.List = ExpiringEntity.NodeType.List.new()

func _ready() -> void:
	list.entity_expired.connect(_on_entity_expired)
	label_container = $MarginContainer/PanelContainer/MarginContainer/LabelContainer

func _on_entity_expired(entity: ExpiringEntity.NodeType):
	entity.node.queue_free()
	visible = list.size() > 1

func write(id: String, text: String, expires: bool):
	var label: Label

	if list.has(id):
		var entity = list.fetch(id)
		entity.refresh()
		label = entity.node
		list.update(id, label, expires)
	else:
		label = LABEL.instantiate()
		list.add(id, label, expires)
		label_container.add_child(label)

	label.text = &"%s: %s" % [id, text]

	visible = list.size() > 0

func clean():
	list.clean()

func clear():
	for child in label_container.get_children():
		child.queue_free()

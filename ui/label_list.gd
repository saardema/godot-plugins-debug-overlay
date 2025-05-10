@tool
extends Control
class_name _DebugTools_UI_LabelList

var label_container: VBoxContainer
const LABEL = preload("res://addons/debug-tools/ui/label.tscn")
var list: ExpiringEntity.NodeType.List = ExpiringEntity.NodeType.List.new()

func _ready() -> void:
	list.entity_expired.connect(func(entity): print("removed"); entity.node.queue_free())
	label_container = $MarginContainer/PanelContainer/MarginContainer/LabelContainer

func write(id: String, text: String, expires: bool):
	var label: Label

	if not label_container: return

	if list.has(id):
		var entity = list.fetch(id)
		entity.refresh()
		label = entity.node
	else:
		label = LABEL.instantiate()
		list.add(id, label, expires)
		label_container.add_child(label)

	label.text = &"%s: %s" % [id, text]

func clean():
	list.clean()

func clear():
	for child in label_container.get_children():
		child.queue_free()

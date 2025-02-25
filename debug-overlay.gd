extends Control

@onready var _container = $PanelContainer/MarginContainer/VBoxContainer
var _label_settings: LabelSettings
var _labels = {}

func _ready() -> void:
	visible = false
	_label_settings = LabelSettings.new()
	_label_settings.font_size = 16

func write(id: String, value: String):
	if not _labels.has(id):
		visible = true
		_labels[id] = _add_label()

	_labels[id].text = "%s: %s" % [id, value]

func _add_label() -> Label:
	var label = Label.new()
	label.label_settings = _label_settings
	_container.add_child(label)

	return label

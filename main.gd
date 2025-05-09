@tool
extends Node3D
@onready var ui = $UI
@onready var draw_3d: Node3D = $Draw3D
var lines: ExpiringEntity.LineType.List = ExpiringEntity.LineType.List.new()

var is_enabled: bool = true

func _process(delta: float) -> void:
	lines.clean()

func write(id: StringName, text: String, expires: bool = false):
	if is_enabled:
		ui.write(id, text, expires)

func draw_line(id: StringName, p1: Vector3, p2: Vector3, color = Color.RED, thickness: float = 0.01, expires: bool = true):
	if is_enabled:
		lines.upsert(id, p1, p2, color, thickness, expires)
		draw_3d.draw_line(id, lines)

func clear():
	ui.clear()
	draw_3d.clear()
	lines.clear()

func disable():
	is_enabled = false
	ui.visible = false
	draw_3d.visible = false
	clear()

func enable():
	is_enabled = true
	ui.visible = true
	draw_3d.visible = true

func reposition(pos, size):
	ui.reposition(pos, size)

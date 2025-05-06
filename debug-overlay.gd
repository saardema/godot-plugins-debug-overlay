extends Control

@onready var _immediate_draw_target:= $MeshInstance3D
@onready var _label_container = $PanelContainer/MarginContainer/VBoxContainer
@onready var _line_3d_container: Node3D = $Line3DContainer
@onready var panel_container: PanelContainer = $PanelContainer

var _label_settings: LabelSettings
var line_nodes: Dictionary[StringName, ExpiringNode]
var text_nodes: Dictionary[StringName, ExpiringNode]
var _time_last_cleanup: int

func _ready() -> void:
	panel_container.visible = false
	_label_settings = LabelSettings.new()
	_label_settings.font_size = 14
	_label_settings.font = SystemFont.new()
	var font_list := PackedStringArray()
	font_list.append('Monaco')
	_label_settings.font.font_names = font_list

func write(id: StringName, value, precision: int = 2, expires: bool = true):
	#print(id, value)
	if value is float:
		value = ('%.' + str(precision) + 'f') % value

	if not text_nodes.has(id):
		text_nodes[id] = _create_label(expires)
		_label_container.add_child(text_nodes[id].node)
	else:
		text_nodes[id].keep_alive()

	text_nodes[id].node.text = &"%s: %s" % [id, value]

func _create_label(expires: bool) -> ExpiringNode:
	var label = Label.new()
	label.label_settings = _label_settings
	var node = ExpiringNode.new(label, expires)

	return node

func _physics_process(_delta: float) -> void:
	_immediate_draw_target.mesh.clear_surfaces()

	var time := Time.get_ticks_msec()
	if time < _time_last_cleanup + 100: return

	_time_last_cleanup = time

	for id in text_nodes.keys():
		if not text_nodes[id].expires: continue
		if time > text_nodes[id].time_updated + ExpiringNode.lifetime_ms:
			text_nodes[id].node.queue_free()
			text_nodes.erase(id)

	panel_container.visible = text_nodes.size() > 0

	for id in line_nodes:
		if time > line_nodes[id].time_updated + ExpiringNode.lifetime_ms:
			line_nodes[id].node.queue_free()
			line_nodes.erase(id)
		#else:
			#var mesh_instance = line_nodes[id].node.get_child(0)
			#mesh_instance.transparency = (time - line_nodes[id].time_updated) / ExpiringNode.lifetime_ms


func draw_line_3d_immediate(point_a: Vector3, point_b: Vector3, color: Color = Color.RED):
	if point_a.is_equal_approx(point_b): return

	_immediate_draw_target.mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_immediate_draw_target.mesh.surface_set_color(color)

	_immediate_draw_target.mesh.surface_add_vertex(point_a)
	_immediate_draw_target.mesh.surface_add_vertex(point_b)

	_immediate_draw_target.mesh.surface_end()

func draw_line_3d(id: String, from: Vector3, to: Vector3, color: Color = Color.RED):
	var node: Node3D
	if not line_nodes.has(id):
		node = _create_line_node()
		_line_3d_container.add_child(node)
		line_nodes[id] = ExpiringNode.new(node)
	else:
		node = line_nodes[id].node
		line_nodes[id].keep_alive()

	var mesh_instance: MeshInstance3D = node.get_child(0)
	var length = from.distance_to(to)

	if is_equal_approx(from.x, to.x):
		from.x += 0.005
	elif is_equal_approx(from.z, to.z):
		from.z += 0.005

	node.look_at_from_position(from, to)

	mesh_instance.position.z = -length / 2
	mesh_instance.mesh.height = length
	mesh_instance.mesh.material.albedo_color = color

func _create_line_node() -> Node3D:
	var node := Node3D.new()
	var mesh_instance := MeshInstance3D.new()
	node.add_child(mesh_instance)

	mesh_instance.mesh = CylinderMesh.new()
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_instance.mesh.top_radius = 0.01
	mesh_instance.mesh.bottom_radius = 0.01
	mesh_instance.mesh.radial_segments = 0
	mesh_instance.rotation.x = -PI / 2

	var material := ORMMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.mesh.material = material

	return node

class ExpiringNode:
	var node: Node
	var time_updated: int
	var expires: bool
	static var lifetime_ms: float = 1000

	func _init(_node: Node, _expires: bool = true):
		node = _node
		expires = _expires
		keep_alive()

	func keep_alive():
		time_updated = Time.get_ticks_msec()

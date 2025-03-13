extends Control

@onready var _immediate_draw_target:= $MeshInstance3D
@onready var _container = $PanelContainer/MarginContainer/VBoxContainer

var _label_settings: LabelSettings
var _labels = {}
var lines: Dictionary[String, Line3D]

#func _draw() -> void:
	#draw_line(Vector2(30, 30), Vector2(80, 80), Color.RED)
	#draw_circle(Vector2(42.479, 65.4825), 9.3905, Color.WHITE)
	#draw_arc(Vector2(500, 500), 100, 1, PI, 20, Color.RED, 50)


func _ready() -> void:
	visible = false
	_label_settings = LabelSettings.new()
	_label_settings.font_size = 16

func write(id: String, value, precision: int = 2):
	if value is float:
		value = ('%.' + str(precision) + 'f') % value
	if not _labels.has(id):
		visible = true
		_labels[id] = _add_label()

	_labels[id].text = "%s: %s" % [id, value]

func _add_label() -> Label:
	var label = Label.new()
	label.label_settings = _label_settings
	_container.add_child(label)

	return label

func _physics_process(_delta: float) -> void:
	_immediate_draw_target.mesh.clear_surfaces()

	var time := Time.get_ticks_msec()
	var remove_queue = []

	for id in lines:
		if time > lines[id].time_updated + 1000:
			lines[id].node.queue_free()
			remove_queue.append(id)
		else:
			var mesh_instance = lines[id].node.get_child(0)
			mesh_instance.transparency = (time - lines[id].time_updated) / 1000.0

	for id in remove_queue:
		lines.erase(id)

func draw_line_3d_immediate(point_a: Vector3, point_b: Vector3, color: Color = Color.RED):
	if point_a.is_equal_approx(point_b): return

	_immediate_draw_target.mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_immediate_draw_target.mesh.surface_set_color(color)

	_immediate_draw_target.mesh.surface_add_vertex(point_a)
	_immediate_draw_target.mesh.surface_add_vertex(point_b)

	_immediate_draw_target.mesh.surface_end()


func draw_line_3d(id: String, from: Vector3, to: Vector3, color: Color = Color.RED):
	var node: Node3D
	if not lines.has(id):
		node = _create_line_node()
		lines[id] = Line3D.new(node, Time.get_ticks_msec())
	else:
		node = lines[id].node
		lines[id].time_updated = Time.get_ticks_msec()

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

	add_child(node)

	return node

class Line3D:
	var node: Node3D
	var time_updated: int

	func _init(_node: Node3D, _time_updated: int):
		node = _node
		time_updated = _time_updated

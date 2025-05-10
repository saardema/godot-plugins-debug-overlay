@tool
extends Node3D

@onready var mi: MeshInstance3D = $LineMesh
@onready var mmi: MultiMeshInstance3D = $MultiMeshInstance3D

@export var material: StandardMaterial3D

var scene_lines_map: Dictionary[StringName, ExpiringEntity.LineType.List]
var current_lines: ExpiringEntity.LineType.List = ExpiringEntity.LineType.List.new()

func _ready():
	mi.material_override = material
	mmi.material_override = material
	clear()

func clear():
	mi.mesh = null
	mmi.multimesh.instance_count = 0

func draw_lines(camera_position: Vector3):
	_build_line_multi_mesh(current_lines, camera_position)

func set_line(id: StringName, p1: Vector3, p2: Vector3, color: Color, thickness: float, expires: bool):
	current_lines.upsert(id, p1, p2, color, thickness, expires)

func clean():
	current_lines.clean()

func set_current_scene(scene):

	if not scene or scene.scene_file_path.contains('addons/debug-tools'):
		current_lines = ExpiringEntity.LineType.List.new()
		return

	var key: String = scene.scene_file_path

	if not scene_lines_map.has(key):
		scene_lines_map[key] = ExpiringEntity.LineType.List.new()

	current_lines = scene_lines_map[key]

func _build_line_multi_mesh(lines: ExpiringEntity.List, camera_pos: Vector3):
	mmi.multimesh.instance_count = lines.size()
	var i: int = 0
	for line: ExpiringEntity.LineType in lines.values():
		var center = (line.p1 + line.p2) / 2.0
		var diff: Vector3 = line.p2 - line.p1
		var tf = Transform3D().looking_at(-diff).translated(center)
		var rel_cam_pos = camera_pos * tf
		var billboard_angle = atan(rel_cam_pos.x / rel_cam_pos.y)
		tf = tf.scaled_local(Vector3(line.thickness, line.thickness, diff.length()))
		tf = tf.rotated_local(Vector3.FORWARD, billboard_angle)

		mmi.multimesh.set_instance_transform(i, tf)
		mmi.multimesh.set_instance_color(i, line.color)
		i += 1

func _build_line_mesh(lines: ExpiringEntity.List):
	mi.mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array()
	arrays[Mesh.ARRAY_COLOR] = PackedColorArray()
	for line in lines.values():
		arrays[Mesh.ARRAY_VERTEX].append_array([line.p1, line.p2])
		arrays[Mesh.ARRAY_COLOR].append_array([line.color, line.color])
	mi.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)

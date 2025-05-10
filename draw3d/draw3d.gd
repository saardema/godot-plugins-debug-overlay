@tool
extends Node3D

@onready var mi: MeshInstance3D = $LineMesh
@onready var mmi: MultiMeshInstance3D = $MultiMeshInstance3D

@export var material: StandardMaterial3D

func _ready():
	mi.material_override = material
	mmi.material_override = material
	clear()

func clear():
	mi.mesh = null
	mmi.multimesh.instance_count = 0

func draw_lines(lines: ExpiringEntity.List, camera_position: Vector3):
	_build_line_multi_mesh(lines, camera_position)
	#if helper_list.size(): build_line_mesh(helper_list)
	#helper_list.clean()
#var helper_list = ExpiringEntity.LineType.List.new()

func _build_line_multi_mesh(lines: ExpiringEntity.List, camera_pos: Vector3):
	mmi.multimesh.instance_count = lines.size()
	var i: int = 0
	for line: ExpiringEntity.LineType in lines.values():
		var center = (line.p1 + line.p2) / 2.0
		var diff: Vector3 = line.p2 - line.p1
		var cam_diff = camera_pos - center
		var direction = diff.normalized()
		var plane = Plane(direction)
		var projection = plane.project(cam_diff)
		var billboard_angle = Vector3.UP.signed_angle_to(projection, -plane.normal)
		var tf = Transform3D().looking_at(-diff).translated(center)
		tf = tf.rotated_local(Vector3.FORWARD, billboard_angle)
		tf = tf.scaled_local(Vector3(line.thickness, line.thickness, diff.length()))
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

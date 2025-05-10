@tool
class_name ExpiringEntity
extends RefCounted

var time_updated: int
var expires: bool
var data: Variant
static var lifetime_ms: float = 1000

func _init(_data: Variant, _expires: bool = true):
	data = _data
	expires = _expires
	refresh()

func is_expired():
	if not expires: return false
	return Time.get_ticks_msec() - time_updated > lifetime_ms

func refresh():
	time_updated = Time.get_ticks_msec()

class List:
	var entities: Dictionary[StringName, ExpiringEntity]
	signal entity_expired(entity: ExpiringEntity)

	func fetch(id: StringName) -> ExpiringEntity:
		if entities.has(id):
			return entities[id]
		return null

	func has(id: StringName) -> bool:
		return entities.has(id)

	func size() -> int:
		return entities.size()

	func keys() -> Array:
		return entities.keys()

	func values() -> Array:
		return entities.values()

	func remove(id) -> bool:
		return entities.erase(id)

	func clear():
		entities.clear()

	func clean():
		for id in entities.keys():
			#print(entities[id].expires)
			if entities[id].is_expired():
				entity_expired.emit(entities[id])
				entities.erase(id)

class NodeType:
	extends ExpiringEntity
	var node: Node

	func _init(_node: Node, _expires: bool = true):
		node = _node
		super._init(null, _expires)

	class List:
		extends ExpiringEntity.List

		func update(id: StringName, node: Node, expires: bool):
			entities[id].node = node
			entities[id].expires = expires

		func add(id: StringName, node: Node, expires: bool):
			entities[id] = ExpiringEntity.NodeType.new(node, expires)

class LineType:
	extends ExpiringEntity
	var color: Color
	var p1: Vector3
	var p2: Vector3
	var thickness: float

	func _init(_p1: Vector3, _p2: Vector3, _color: Color, _thickness: float, expires: bool = true):
		p1 = _p1
		p2 = _p2
		color = _color
		thickness = _thickness
		super._init(null, expires)

	class List:
		extends ExpiringEntity.List

		func upsert(id: StringName, _p1: Vector3, _p2: Vector3, _color: Color, _thickness: float, expires: bool):
			if entities.has(id): update(id, _p1, _p2, _color, _thickness, expires)
			else: add(id, _p1, _p2, _color, _thickness, expires)

		func update(id: StringName, _p1: Vector3, _p2: Vector3, _color: Color, _thickness: float, expires: bool):
			entities[id].refresh()
			entities[id].p1 = _p1
			entities[id].p2 = _p2
			entities[id].color = _color
			entities[id].thickness = _thickness
			entities[id].expires = expires

		func add(id: StringName, _p1: Vector3, _p2: Vector3, _color: Color, _thickness: float, expires: bool):
			entities[id] = ExpiringEntity.LineType.new(_p1, _p2, _color, _thickness, expires)

class_name BatchAnimationBuffer
extends RefCounted

## Buffers animation requests to be played simultaneously.
## Used when Animation Speed is set to 'Batch'.

var _requests: Array[Dictionary] = []

func add_move(unit: Node2D, start_pos: Vector2, path_points: Array[Vector2], duration: float, style: AnimationStyle, coord: Vector2i, style_id: StringName) -> void:
	_requests.append({
		"type": "move",
		"unit": unit,
		"start_pos": start_pos,
		"path_points": path_points,
		"duration": duration,
		"style": style,
		"coord": coord,
		"style_id": style_id
	})

func add_generic(method_name: String, args: Array) -> void:
	_requests.append({
		"type": "generic",
		"method": method_name,
		"args": args
	})

func clear() -> void:
	_requests.clear()

func get_requests() -> Array[Dictionary]:
	return _requests

func is_empty() -> bool:
	return _requests.is_empty()

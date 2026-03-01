class_name CoordValidator
extends RefCounted

static func is_in_bounds(coord: Vector2i, width: int, height: int) -> bool:
	return coord.x >= 1 and coord.y >= 1 and coord.x <= width and coord.y <= height

static func key_of(coord: Vector2i) -> String:
	return "%s,%s" % [coord.x, coord.y]


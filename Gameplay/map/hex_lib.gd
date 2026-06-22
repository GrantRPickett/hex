## Static library for pure hexagonal grid mathematics.
##
## This library follows the "Axial Coordinate" system (q, r) internally,
## and provides conversions for Godot's TileMapLayer (staggered) layouts.
class_name HexLib
extends RefCounted

const DEFAULT_AXIS: int = TileSet.TILE_OFFSET_AXIS_VERTICAL

const EVEN_COLUMN_NEIGHBORS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0),
	Vector2i(0, 1), Vector2i(-1, 0), Vector2i(-1, -1),
]
const ODD_COLUMN_NEIGHBORS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(1, 0), Vector2i(1, 1),
	Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0),
]
const EVEN_ROW_NEIGHBORS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, -1),
	Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1),
]
const ODD_ROW_NEIGHBORS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
	Vector2i(-1, 0), Vector2i(0, 1), Vector2i(1, 1),
]

# Godot 4 TileMapLayer uses staggered layouts by default.
# Standard vertical stagger (odd-column down) is typical for this project.

## Returns the axial distance between two hexagonal coordinates.
static func get_distance(a: Vector2i, b: Vector2i, axis: int = TileSet.TILE_OFFSET_AXIS_VERTICAL) -> int:
	var aq_ar: Vector2i = map_to_axial(a, axis)
	var bq_br: Vector2i = map_to_axial(b, axis)

	var dq = aq_ar.x - bq_br.x
	var dr = aq_ar.y - bq_br.y
	return (abs(dq) + abs(dr) + abs(dq + dr)) >> 1

## Returns neighbor offsets for a given coordinate and axis.
static func get_neighbor_offsets(coord: Vector2i, axis: int) -> Array[Vector2i]:
	if axis == TileSet.TILE_OFFSET_AXIS_VERTICAL:
		if (coord.x & 1):
			return ODD_COLUMN_NEIGHBORS
		return EVEN_COLUMN_NEIGHBORS

	if (coord.y & 1):
		return ODD_ROW_NEIGHBORS
	return EVEN_ROW_NEIGHBORS

## Converts a Godot map coordinate to Axial (q, r).
static func map_to_axial(map_coord: Vector2i, axis: int) -> Vector2i:
	var q = map_coord.x
	var r = map_coord.y
	if axis == TileSet.TILE_OFFSET_AXIS_VERTICAL:
		# Flat-top, odd-column staggered down (Odd-Down)
		r = map_coord.y - (map_coord.x >> 1)
	else:
		# Pointy-top, odd-row staggered right (Odd-Right)
		q = map_coord.x - (map_coord.y >> 1)
	return Vector2i(q, r)

## Converts Axial (q, r) back to Godot map coordinate.
static func axial_to_map(axial_coord: Vector2i, axis: int) -> Vector2i:
	if axis == TileSet.TILE_OFFSET_AXIS_VERTICAL:
		var x = axial_coord.x
		var y = axial_coord.y + (axial_coord.x >> 1)
		return Vector2i(x, y)
	else:
		var x = axial_coord.x + (axial_coord.y >> 1)
		var y = axial_coord.y
		return Vector2i(x, y)

## Returns true if the coordinate is within the given dimensions.
static func is_in_bounds(coord: Vector2i, width: int, height: int) -> bool:
	return coord.x >= 0 and coord.y >= 0 and coord.x < width and coord.y < height

## Returns a unique string key for a coordinate (useful for Dictionaries).
static func key_of(coord: Vector2i) -> String:
	return "%s,%s" % [coord.x, coord.y]

## Returns common grid dimensions from a Level resource.
static func dims_of(level: Level) -> Dictionary:
	if level == null or level.terrain_data == null:
		return {"width": 1, "height": 1, "axis": TileSet.TILE_OFFSET_AXIS_VERTICAL}
	return {
		"width": max(1, int(level.terrain_data.grid_width)),
		"height": max(1, int(level.terrain_data.grid_height)),
		"axis": int(level.hex_offset_axis),
	}

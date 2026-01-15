class_name TerrainMap
extends RefCounted

const DEFAULT_CODE := "G"
const CODE_TO_TERRAIN := {
	"G": preload("res://Gameplay/Terrain/grass_terrain.gd"),
	"R": preload("res://Gameplay/Terrain/road_terrain.gd"),
	"M": preload("res://Gameplay/Terrain/mud_terrain.gd"),
	"S": preload("res://Gameplay/Terrain/swamp_terrain.gd"),
	"I": preload("res://Gameplay/Terrain/ice_terrain.gd"),
	"W": preload("res://Gameplay/Terrain/wall_terrain.gd"),
}

const EVEN_COLUMN_NEIGHBORS := [
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 0),
	Vector2i(-1, -1),
]
const ODD_COLUMN_NEIGHBORS := [
	Vector2i(0, -1),
	Vector2i(1, 0),
	Vector2i(1, 1),
	Vector2i(0, 1),
	Vector2i(-1, 1),
	Vector2i(-1, 0),
]

var grid_width: int = 0
var grid_height: int = 0
var _rows: Array[String] = []
var _tiles: Dictionary = {}

func load_from_rows(rows: Array, width: int = -1, height: int = -1) -> void:
	_rows.clear()
	_tiles.clear()
	if rows.is_empty():
		grid_width = max(width, 0)
		grid_height = max(height, 0)
		return
	grid_height = height if height > 0 else rows.size()
	grid_width = width if width > 0 else 0
	if grid_width <= 0:
		for row in rows:
			grid_width = max(grid_width, row.length())
	for y in range(grid_height):
		var source_row := ""
		if y < rows.size():
			source_row = String(rows[y])
		_rows.append(source_row)
	grid_height = max(grid_height, _rows.size())
	if grid_width <= 0:
		for row in _rows:
			grid_width = max(grid_width, row.length())

func is_within_bounds(coord: Vector2i) -> bool:
	return coord.x >= 0 and coord.y >= 0 and coord.x < grid_width and coord.y < grid_height

func get_terrain(coord: Vector2i) -> TerrainTile:
	if not is_within_bounds(coord):
		return null
	if _tiles.has(coord):
		return _tiles[coord]
	var code := _get_code(coord)
	var klass = CODE_TO_TERRAIN.get(code, CODE_TO_TERRAIN[DEFAULT_CODE])
	var terrain: TerrainTile = klass.new()
	_tiles[coord] = terrain
	return terrain

func is_passable(coord: Vector2i) -> bool:
	var terrain := get_terrain(coord)
	return terrain != null and terrain.passable

func get_movement_cost(coord: Vector2i) -> int:
	var terrain := get_terrain(coord)
	if terrain == null:
		return 999
	var penalty: int = int(max(terrain.movement_penalty, 0))
	var bonus: int = int(max(terrain.movement_bonus, 0))
	var base_cost: int = 1 + penalty - bonus
	return max(base_cost, 0)

func get_neighbors(coord: Vector2i) -> Array[Vector2i]:
	var offsets := EVEN_COLUMN_NEIGHBORS if coord.x % 2 == 0 else ODD_COLUMN_NEIGHBORS
	var neighbors: Array[Vector2i] = []
	for offset in offsets:
		neighbors.append(coord + offset)
	return neighbors

func _get_code(coord: Vector2i) -> String:
	if coord.y >= _rows.size():
		return DEFAULT_CODE
	var row := _rows[coord.y]
	if coord.x >= row.length():
		return DEFAULT_CODE
	return row.substr(coord.x, 1)

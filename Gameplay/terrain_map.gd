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

const NON_PASSABLE_COST := 999

var grid_width: int = 0
var grid_height: int = 0
var offset_axis: int = TileSet.TILE_OFFSET_AXIS_VERTICAL
var _rows: Array[String] = []
var _tiles: Dictionary = {}
var _version: int = 0

func set_offset_axis(axis: int) -> void:
	offset_axis = axis

func get_offset_axis() -> int:
	return offset_axis

func load_from_rows(rows: Array, width: int = -1, height: int = -1) -> void:
	_rows.clear()
	_clear_tiles()
	if rows.is_empty():
		grid_width = max(width, 0)
		grid_height = max(height, 0)
		_version += 1
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
	_version += 1

func is_within_bounds(coord: Vector2i) -> bool:
	return coord.x >= 1 and coord.y >= 1 and coord.x < grid_width and coord.y < grid_height

func get_terrain(coord: Vector2i) -> TerrainTile:
	if not is_within_bounds(coord):
		return TerrainTile.NullTerrain.new()
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
	if not terrain.passable:
		return NON_PASSABLE_COST
	var penalty: int = int(max(terrain.movement_penalty, 0))
	var bonus: int = int(max(terrain.movement_bonus, 0))
	var base_cost: int = 1 + penalty - bonus
	return max(base_cost, 0)

func get_neighbors(coord: Vector2i) -> Array[Vector2i]:
	var offsets := HexNavigator.get_neighbor_offsets(coord, offset_axis)
	var neighbors: Array[Vector2i] = []
	for offset in offsets:
		neighbors.append(coord + offset)
	return neighbors

func get_version() -> int:
	return _version

func get_code(coord: Vector2i) -> String:
	return _get_code(coord)

func _clear_tiles() -> void:
	for tile in _tiles.values():
		if is_instance_valid(tile):
			tile.free()
	_tiles.clear()

func _get_code(coord: Vector2i) -> String:
	if coord.y >= _rows.size():
		return DEFAULT_CODE
	var row := _rows[coord.y]
	if coord.x >= row.length():
		return DEFAULT_CODE
	return row.substr(coord.x, 1)

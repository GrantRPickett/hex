class_name TerrainMap
extends RefCounted

const DEFAULT_CODE := "G"
const CODE_TO_TERRAIN := {
	"0": preload("res://Gameplay/terrain/stone.gd"),
	"1": preload("res://Gameplay/terrain/cave_entrance.gd"),
	"2": preload("res://Gameplay/terrain/waterfall.gd"),
	"3": preload("res://Gameplay/terrain/lava_flow.gd"),
	"4": preload("res://Gameplay/terrain/mountain_peak.gd"),
	"5": preload("res://Gameplay/terrain/desert_oasis.gd"),
	"6": preload("res://Gameplay/terrain/monastery.gd"),
	"7": preload("res://Gameplay/terrain/graveyard.gd"),
	"8": preload("res://Gameplay/terrain/floating_island.gd"),
	"9": preload("res://Gameplay/terrain/rock_dune.gd"),
	"A": preload("res://Gameplay/terrain/ash.gd"),
	"B": preload("res://Gameplay/terrain/bridge_causeway.gd"),
	"C": preload("res://Gameplay/terrain/courtyard.gd"),
	"D": preload("res://Gameplay/terrain/sand.gd"),
	"E": preload("res://Gameplay/terrain/enchanted_forest.gd"),
	"F": preload("res://Gameplay/terrain/fort.gd"),
	"G": preload("res://Gameplay/terrain/grass.gd"),
	"H": preload("res://Gameplay/terrain/hill_high_ground.gd"),
	"I": preload("res://Gameplay/terrain/ice.gd"),
	"J": preload("res://Gameplay/terrain/jungle.gd"),
	"K": preload("res://Gameplay/terrain/keep.gd"),
	"L": preload("res://Gameplay/terrain/leaf_platform.gd"),
	"M": preload("res://Gameplay/terrain/mud.gd"),
	"N": preload("res://Gameplay/terrain/ruins.gd"),
	"O": preload("res://Gameplay/terrain/oasis.gd"),
	"P": preload("res://Gameplay/terrain/path.gd"),
	"Q": preload("res://Gameplay/terrain/quagmire.gd"),
	"R": preload("res://Gameplay/terrain/river.gd"),
	"S": preload("res://Gameplay/terrain/swamp.gd"),
	"T": preload("res://Gameplay/terrain/tree_village.gd"),
	"U": preload("res://Gameplay/terrain/underground.gd"),
	"V": preload("res://Gameplay/terrain/vines.gd"),
	"W": preload("res://Gameplay/terrain/wall.gd"),
	"X": preload("res://Gameplay/terrain/crossroads.gd"),
	"Y": preload("res://Gameplay/terrain/crystal.gd"),
	"Z": preload("res://Gameplay/terrain/plaza.gd"),
}

const NON_PASSABLE_COST := 999

static var _color_cache: Dictionary = {}

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
	return coord.x >= 0 and coord.y >= 0 and coord.x < grid_width and coord.y < grid_height

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
	# Use the new modified movement cost from TerrainTile, passing the current weather
	return terrain.get_modified_movement_cost(WeatherManager.get_current_weather_attribute())

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

func get_color_for_code(code: String) -> Color:
	if _color_cache.has(code):
		return _color_cache[code]

	var klass = CODE_TO_TERRAIN.get(code, CODE_TO_TERRAIN[DEFAULT_CODE])
	if klass:
		var terrain: TerrainTile = klass.new()
		var color := terrain.color
		_color_cache[code] = color
		terrain.free()
		return color
	return Color.WHITE

func get_all_terrain_colors() -> Dictionary:
	var colors := {}
	for code in CODE_TO_TERRAIN:
		colors[code] = get_color_for_code(code)
	return colors

func _clear_tiles() -> void:
	for tile in _tiles.values():
		if is_instance_valid(tile):
			tile.free()
	_tiles.clear()

func _get_code(coord: Vector2i) -> String:
	if coord.y >= _rows.size() or coord.y < 0:
		return DEFAULT_CODE
	var row := _rows[coord.y]
	if coord.x >= row.length() or coord.x < 0:
		return DEFAULT_CODE
	return row.substr(coord.x, 1)

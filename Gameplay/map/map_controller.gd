class_name MapController
extends Node

# EnemyRoster class is auto-global in Godot 4

var _terrain_map: TerrainMap
var _grid: Node2D

func setup(grid: Node2D) -> void:
	_grid = grid
	_terrain_map = TerrainMap.new()
	_terrain_map.set_offset_axis(TileSet.TILE_OFFSET_AXIS_VERTICAL)


func get_terrain_map() -> TerrainMap:
	return _terrain_map

func get_grid() -> Node2D:
	return _grid

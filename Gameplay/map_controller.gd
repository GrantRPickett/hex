class_name MapController
extends Node

# EnemyRoster class is auto-global in Godot 4
const TerrainMapScript := preload("res://Gameplay/terrain_map.gd")
const GENERIC_ENEMY_PATH : String = "res://Gameplay/generic_enemy.tscn"

var _terrain_map
var _grid: Node2D

func setup(grid: Node2D) -> void:
	_grid = grid
	_terrain_map = TerrainMapScript.new()
	_terrain_map.set_offset_axis(TileSet.TILE_OFFSET_AXIS_VERTICAL)

func load_level(level_resource: Resource, context: LevelBuildContext) -> Dictionary:
	var builder = LevelBuilder.new(context)
	var result = builder.build(level_resource, _terrain_map)

	return result

func get_terrain_map():
	return _terrain_map


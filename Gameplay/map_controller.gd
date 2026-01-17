class_name MapController
extends Node

const LevelBuilder := preload("res://Gameplay/level_builder.gd")
const TerrainMapScript := preload("res://Gameplay/terrain_map.gd")

var _terrain_map
var _grid: Node2D

func setup(grid: Node2D) -> void:
	_grid = grid
	_terrain_map = TerrainMapScript.new()
	_terrain_map.set_offset_axis(TileSet.TILE_OFFSET_AXIS_VERTICAL)

func load_level(level_resource: Resource, gameplay_root: Node2D, unit_manager: UnitManager, goal_manager: GoalManager, camera: Camera2D, controls: Node, player_templates: Array[Unit], goal_templates: Array[Goal]) -> Dictionary:
	var builder = LevelBuilder.new(gameplay_root, unit_manager, goal_manager, _grid, camera, controls, player_templates, goal_templates)
	return builder.build(level_resource, _terrain_map)

func get_terrain_map():
	return _terrain_map

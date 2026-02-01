class_name MapController
extends Node

# EnemyRoster class is auto-global in Godot 4
const TerrainMapScript := preload("res://Gameplay/terrain_map.gd")
const GENERIC_ENEMY_PATH := "res://Gameplay/generic_enemy.tscn"

var _terrain_map
var _grid: Node2D

func setup(grid: Node2D) -> void:
	_grid = grid
	_terrain_map = TerrainMapScript.new()
	_terrain_map.set_offset_axis(TileSet.TILE_OFFSET_AXIS_VERTICAL)

func load_level(level_resource: Resource, context: LevelBuildContext) -> Dictionary:
	if context.loot_manager:
		context.loot_manager.reset()
		if "loot" in level_resource:
			_load_loot(level_resource.loot, context.loot_manager)

	var builder = LevelBuilder.new(context)
	var result = builder.build(level_resource, _terrain_map)

	return result

func get_terrain_map():
	return _terrain_map

func _load_loot(loot_data: Array, loot_manager: LootManager) -> void:
	for entry in loot_data:
		var coord: Vector2i = Vector2i(-999, -999)
		var items: Array = []

		if entry is Dictionary:
			coord = entry.get("coord", Vector2i(-999, -999))
			items = entry.get("items", [])
		elif entry is Object:
			if "coord" in entry:
				coord = entry.get("coord")
			if "items" in entry:
				items = entry.get("items")

		if not items.is_empty():
			loot_manager.spawn_loot(coord, items)

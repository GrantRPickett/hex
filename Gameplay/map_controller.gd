class_name MapController
extends Node

const EnemyRoster = preload("res://Gameplay/enemy_roster.gd")
const TerrainMapScript := preload("res://Gameplay/terrain_map.gd")
const GENERIC_ENEMY_PATH := "res://Gameplay/Units/generic_enemy.tscn"

var _terrain_map
var _grid: Node2D

func setup(grid: Node2D) -> void:
	_grid = grid
	_terrain_map = TerrainMapScript.new()
	_terrain_map.set_offset_axis(TileSet.TILE_OFFSET_AXIS_VERTICAL)

func load_level(level_resource: Resource, gameplay_root: Node2D, unit_manager: UnitManager, goal_manager: GoalManager, loot_manager: LootManager, camera: Camera2D, controls: Node, player_roster: PlayerRoster, enemy_roster: EnemyRoster, goal_templates: Array[Goal]) -> Dictionary:
	if loot_manager:
		loot_manager.reset()
		if "loot" in level_resource:
			_load_loot(level_resource.loot, loot_manager)

	var enemy_templates: Array[Unit] = []
	if enemy_roster:
		for scene in enemy_roster.enemy_types:
			if scene:
				var u = scene.instantiate()
				if u is Unit:
					enemy_templates.append(u)

	if enemy_templates.is_empty() and ResourceLoader.exists(GENERIC_ENEMY_PATH):
		var scene = load(GENERIC_ENEMY_PATH)
		if scene:
			var u = scene.instantiate()
			if u is Unit:
				enemy_templates.append(u)

	var builder = LevelBuilder.new(gameplay_root, unit_manager, goal_manager, _grid, camera, controls, [], enemy_templates, goal_templates)
	var result = builder.build(level_resource, _terrain_map)

	for t in enemy_templates:
		t.free()

	if player_roster and "player_starts" in level_resource:
		var starts = level_resource.player_starts
		var units = player_roster.get_units()

		for i in range(min(starts.size(), units.size())):
			var coord = starts[i]
			var unit = units[i]

			gameplay_root.add_child(unit)
			unit.position = _grid.map_to_local(coord)
			unit_manager.add_unit(unit, coord, true)
			if loot_manager:
				unit.set_loot_manager(loot_manager)

	return result

func get_terrain_map():
	return _terrain_map

func _load_loot(loot_data: Array, loot_manager: LootManager) -> void:
	for entry in loot_data:
		var coord: Vector2i = Vector2i.ZERO
		var items: Array = []

		if entry is Dictionary:
			coord = entry.get("coord", Vector2i.ZERO)
			items = entry.get("items", [])
		elif entry is Object:
			if "coord" in entry:
				coord = entry.get("coord")
			if "items" in entry:
				items = entry.get("items")

		if not items.is_empty():
			loot_manager.spawn_loot(coord, items)

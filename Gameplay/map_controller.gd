class_name MapController
extends Node

# EnemyRoster class is auto-global in Godot 4
const TerrainMapScript := preload("res://Gameplay/terrain_map.gd")
const GENERIC_ENEMY_PATH := "res://Gameplay/Units/generic_enemy.tscn"

var _terrain_map
var _grid: Node2D

func setup(grid: Node2D) -> void:
	_grid = grid
	_terrain_map = TerrainMapScript.new()
	_terrain_map.set_offset_axis(TileSet.TILE_OFFSET_AXIS_VERTICAL)

func load_level(level_resource: Resource, gameplay_root: Node2D, unit_manager: UnitManager, goal_manager: GoalManager, loot_manager: LootManager, combat_system: CombatSystem, camera: Camera2D, controls: Node, player_roster: PlayerRoster, enemy_roster: EnemyRoster, goal_templates: Array[Goal]) -> Dictionary:
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

	var player_units: Array[Unit] = []
	if player_roster:
		player_units = player_roster.get_units()

	if player_units.is_empty():
		var generic_unit = load("res://Gameplay/generic_unit.tscn")
		if generic_unit:
			var u = generic_unit.instantiate()
			if u is Unit:
				player_units.append(u)

	var builder = LevelBuilder.new(gameplay_root, unit_manager, goal_manager, combat_system, _grid, camera, controls, player_units, enemy_templates, goal_templates)
	var result = builder.build(level_resource, _terrain_map)

	for t in enemy_templates:
		t.free()

	for t in player_units:
		t.free()

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

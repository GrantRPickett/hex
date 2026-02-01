class_name LevelBuilder
extends RefCounted

const DialogueTrigger := preload("res://Gameplay/dialogue_trigger.gd")
const DialogueTriggerGroup := preload("res://Gameplay/dialogue_trigger_group.gd")
# Goal and Unit classes are auto-global in Godot 4

var _context: LevelBuildContext
var _terrain_map

func _init(context: LevelBuildContext) -> void:
	_context = context

func build(level: Resource, terrain_map) -> Dictionary:
	_apply_level_settings(level, terrain_map)
	_terrain_map = terrain_map
	_context.unit_manager.reset()
	_spawn_units(level)
	_spawn_goals(level)
	_spawn_loot(level)
	var dialogue_triggers := _spawn_dialogue_triggers(level)
	if _context.dialogue_service:
		_context.dialogue_service.register_triggers(dialogue_triggers)

	return {
		"grid_width": level.terrain_data.grid_width,
		"grid_height": level.terrain_data.grid_height,
		"require_all_units": level.require_all_units
	}

func _apply_level_settings(level: Resource, terrain_map) -> void:
	if _context.controls:
		_context.controls.require_all_units_to_goal = level.require_all_units

	_context.camera.rotation = level.initial_rotation

	if is_instance_valid(_context.grid.tile_set):
		var ts: TileSet = _context.grid.tile_set
		if ts:
			var dup: TileSet = ts.duplicate(true)
			dup.tile_offset_axis = level.hex_offset_axis
			_context.grid.tile_set = dup

	if terrain_map:
		terrain_map.set_offset_axis(level.hex_offset_axis)
		if level.terrain_data:
			terrain_map.load_from_rows(level.terrain_data.terrain_rows, level.terrain_data.grid_width, level.terrain_data.grid_height)

func _spawn_units(level: Resource) -> void:
	if not _context.unit_manager:
		return

	# Player starts (still using simple Vector2i array)
	if not level.player_starts.is_empty() and _context.player_roster:
		var player_units_to_spawn: Array[PackedScene] = _context.player_roster.units
		for i in range(level.player_starts.size()):
			var coord = level.player_starts[i]
			var scene_to_spawn: PackedScene = null
			if i < player_units_to_spawn.size():
				scene_to_spawn = player_units_to_spawn[i]
			else:
				# Fallback if more start positions than player units
				# For player, it's usually 1:1, so this is a warning
				push_warning("[LevelBuilder] More player start positions than player units in roster. Skipping start at %s" % coord)
				continue
			if scene_to_spawn:
				_spawn_unit(scene_to_spawn, coord, true, false, Color.WHITE)

	# Enemy spawns (using EnemyRosterDefinition)
	if level.enemy_roster_definition and not level.enemy_roster_definition.spawn_entries.is_empty():
		for spawn_entry in level.enemy_roster_definition.spawn_entries:
			if spawn_entry and spawn_entry.unit_scene:
				_spawn_unit(spawn_entry.unit_scene, spawn_entry.coord, false, false, Color.TOMATO)
			else:
				push_warning("[LevelBuilder] Invalid enemy spawn entry or unit scene in level.enemy_roster_definition.spawn_entries.")
	elif "enemy_spawns" in level and not level.enemy_spawns.is_empty():
		for spawn_entry in level.enemy_spawns:
			if spawn_entry and spawn_entry.unit_scene:
				_spawn_unit(spawn_entry.unit_scene, spawn_entry.coord, false, false, Color.TOMATO)
			else:
				push_warning("[LevelBuilder] Invalid enemy spawn entry or unit scene in level.enemy_spawns.")

	# Neutral spawns (using roster definition fallback)
	if level.neutral_roster_definition and not level.neutral_roster_definition.spawn_entries.is_empty():
		for spawn_entry in level.neutral_roster_definition.spawn_entries:
			if spawn_entry and spawn_entry.unit_scene:
				_spawn_unit(spawn_entry.unit_scene, spawn_entry.coord, false, true, Color.LIGHT_SKY_BLUE)
			else:
				push_warning("[LevelBuilder] Invalid neutral spawn entry or unit scene in level.neutral_roster_definition.spawn_entries.")
	elif "neutral_spawns" in level and not level.neutral_spawns.is_empty():
		for spawn_entry in level.neutral_spawns:
			if spawn_entry and spawn_entry.unit_scene:
				_spawn_unit(spawn_entry.unit_scene, spawn_entry.coord, false, true, Color.LIGHT_SKY_BLUE)
			else:
				push_warning("[LevelBuilder] Invalid neutral spawn entry or unit scene in level.neutral_spawns.")


func _log_impassable_goal(coord: Vector2i) -> void:
	push_warning("[LevelBuilder] Goal at %s is on an impassable tile." % [coord])

func _is_goal_coord_passable(coord: Vector2i) -> bool:
	if _terrain_map == null or not _terrain_map.has_method("is_passable"):
		return true
	var passable: bool = _terrain_map.is_passable(coord)
	if not passable:
		_log_impassable_goal(coord)
	return passable

func _spawn_goals(level: Resource) -> void:
	var goal_nodes: Array[Goal] = []
	var goal_coords_for_manager: Array[Vector2i] = []

	for goal_entry in level.goals:
		if not goal_entry or not goal_entry.goal_scene:
			push_warning("[LevelBuilder] Invalid goal entry or scene in level.goals.")
			continue

		_is_goal_coord_passable(goal_entry.coord)
		goal_coords_for_manager.append(goal_entry.coord)

		var goal_instance = goal_entry.goal_scene.instantiate()
		if goal_instance is Goal:
			_context.gameplay_root.add_child(goal_instance)
			if _context.grid.has_method("map_to_local"):
				goal_instance.grid_map = _context.grid
				goal_instance.position = _context.grid.map_to_local(goal_entry.coord)
			goal_nodes.append(goal_instance)
		else:
			push_warning("[LevelBuilder] Instantiated scene from goal_entry.goal_scene is not a Goal: %s" % goal_entry.goal_scene.resource_path)

	_context.goal_manager.setup(goal_coords_for_manager, goal_nodes, _context.grid)

func _spawn_loot(level: Resource) -> void:
	if not _context.allow_loot_spawn:
		return
	if level.loot_list_definition and not level.loot_list_definition.loot_entries.is_empty() and _context.loot_manager:
		var loot_scene = load("res://Gameplay/loot.tscn")
		if loot_scene:
			for loot_entry in level.loot_list_definition.loot_entries:
				if not loot_entry or loot_entry.items.is_empty():
					push_warning("[LevelBuilder] Invalid loot entry or no items in level.loot_list_definition.loot_entries.")
					continue

				var loot_instance = loot_scene.instantiate()
				if loot_instance:
					loot_instance.add_items(loot_entry.items)

					_context.gameplay_root.add_child(loot_instance)
					if loot_instance.is_empty():
						loot_instance.queue_free()
					else:
						_context.loot_manager.add_loot(loot_instance, loot_entry.coord)

func _spawn_dialogue_triggers(level: Resource) -> Array[DialogueTrigger]:
	var triggers: Array[DialogueTrigger] = []
	if not "dialogue_entries" in level or level.dialogue_entries.is_empty():
		return triggers

	var groups: Dictionary = {}

	for entry in level.dialogue_entries:
		if not entry.has_timeline():
			continue

		var trigger := DialogueTrigger.new()
		trigger.configure_from_entry(entry)
		
		_context.gameplay_root.add_child(trigger)
		trigger.assign_coord_on_grid(_context.grid)

		if not entry.group_id.is_empty():
			var group: DialogueTriggerGroup = groups.get(entry.group_id)
			if group == null:
				group = DialogueTriggerGroup.new()
				group.group_id = entry.group_id
				groups[entry.group_id] = group
			trigger.set_group(group)
		
		triggers.append(trigger)
		
	return triggers

func _spawn_unit(scene: PackedScene, coord: Vector2i, is_player: bool, is_neutral: bool, modulate: Color = Color.WHITE) -> void:
	var unit_instance = scene.instantiate()
	if not (unit_instance is Unit):
		printerr("[LevelBuilder] Error: Instantiated scene is not a Unit: ", scene.resource_path)
		unit_instance.queue_free()
		return

	if is_player:
		unit_instance.faction = Unit.Faction.PLAYER
	elif is_neutral:
		unit_instance.faction = Unit.Faction.NEUTRAL
	else:
		unit_instance.faction = Unit.Faction.ENEMY
	unit_instance.modulate = modulate
	unit_instance.set_unit_manager(_context.unit_manager)
	unit_instance.set_goal_manager(_context.goal_manager)
	unit_instance.set_combat_system(_context.combat_system)
	if _context.loot_manager:
		unit_instance.set_loot_manager(_context.loot_manager)

	_context.gameplay_root.add_child(unit_instance)

	if _context.grid.has_method("map_to_local"):
		unit_instance.grid_map = _context.grid
		unit_instance.position = _context.grid.map_to_local(coord)

	unit_instance.refresh_for_new_round()

	_context.unit_manager.add_unit(unit_instance, coord, is_player)
	_context.unit_manager.set_coord(_context.unit_manager.get_unit_count() - 1, coord)

	var faction_label = "Enemy"
	if is_player: faction_label = "Player"
	elif is_neutral: faction_label = "Neutral"
	print("[LevelBuilder] Spawned %s unit '%s' at %s (Faction: %s, Scene: %s)" % [
		faction_label,
		unit_instance.unit_name,
		coord,
		unit_instance.get_faction_name(),
		scene.resource_path
	])

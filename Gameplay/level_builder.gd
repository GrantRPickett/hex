class_name LevelBuilder
extends RefCounted
# Goal and Unit classes are auto-global in Godot 4

var _context: LevelBuildContext

func _init(context: LevelBuildContext) -> void:
	_context = context

func build(level: Resource, terrain_map) -> Dictionary:
	var data = LevelLoader.load_level_data(level)

	_apply_level_settings(data, terrain_map)
	_context.unit_manager.reset()
	_spawn_units(data)
	_spawn_goals(data)
	_spawn_loot(data)

	return {
		"grid_width": data.grid_width,
		"grid_height": data.grid_height,
		"require_all_units": data.require_all_units
	}

func _apply_level_settings(data: Dictionary, terrain_map) -> void:
	if _context.controls:
		_context.controls.require_all_units_to_goal = data.require_all_units

	_context.camera.rotation = data.initial_rotation

	if is_instance_valid(_context.grid.tile_set):
		var ts: TileSet = _context.grid.tile_set
		if ts:
			var dup: TileSet = ts.duplicate(true)
			dup.tile_offset_axis = data.hex_offset_axis
			_context.grid.tile_set = dup

	if terrain_map:
		terrain_map.set_offset_axis(data.hex_offset_axis)
		terrain_map.load_from_rows(data.terrain_rows, data.grid_width, data.grid_height)

func _spawn_units(data: Dictionary) -> void:
	if "player_starts" in data and _context.player_roster:
		_spawn_roster_units(data.player_starts, _context.player_roster.units, true, false)

	if "enemy_starts" in data and _context.enemy_roster:
		_spawn_roster_units(data.enemy_starts, _context.enemy_roster.units, false, false, Color.TOMATO)

	if "neutral_starts" in data and _context.neutral_roster:
		_spawn_roster_units(data.neutral_starts, _context.neutral_roster.units, false, true, Color.LIGHT_SKY_BLUE)

func _spawn_goals(data: Dictionary) -> void:
	var goals: Array[Vector2i] = []
	goals.assign(data.goal_coords)
	var goal_nodes: Array[Goal] = []

	if _context.goal_templates.is_empty() and not goals.is_empty():
		var goal_scene = load("res://Gameplay/goal.tscn")
		if goal_scene:
			for i in range(goals.size()):
				var goal_instance = goal_scene.instantiate()
				if goal_instance is Goal:
					_context.gameplay_root.add_child(goal_instance)
					if _context.grid.has_method("map_to_local"):
						goal_instance.grid_map = _context.grid
						goal_instance.position = _context.grid.map_to_local(goals[i])
					goal_nodes.append(goal_instance)
	else:
		goal_nodes.assign(_context.goal_templates.map(func(node): return node as Goal))

	_context.goal_manager.setup(goals, goal_nodes, _context.grid)

func _spawn_loot(data: Dictionary) -> void:
	if not _context.allow_loot_spawn:
		return
	if "loot_coords" in data and _context.loot_manager:
		var loot_scene = load("res://Gameplay/loot.tscn")
		if loot_scene:
			var level_loot_items = data.get("loot_items", []) # This is a flat array of InventoryItem Resources

			for i in range(data.loot_coords.size()):
				var coord = data.loot_coords[i]
				var items_for_this_loot_node: Array = []

				# Check if there's a corresponding item for this coordinate and it's not null
				if i < level_loot_items.size() and level_loot_items[i] != null:
					items_for_this_loot_node.append(level_loot_items[i])

				var loot_instance = loot_scene.instantiate()
				if loot_instance:
					loot_instance.add_items(items_for_this_loot_node)

					_context.gameplay_root.add_child(loot_instance)
					if loot_instance.is_empty():
						loot_instance.queue_free()
					else:
						_context.loot_manager.add_loot(loot_instance, coord)

func _spawn_roster_units(starts: Array, scenes: Array[PackedScene], is_player: bool, is_neutral: bool, modulate: Color = Color.WHITE) -> void:
	if scenes.is_empty():
		var label = "enemy"
		if is_player: label = "player"
		elif is_neutral: label = "neutral"
		print("[LevelBuilder] Warning: No scenes provided for %s roster spawning." % [label])
		return

	var label = "player" if is_player else ("neutral" if is_neutral else "enemy")
	print("[LevelBuilder] Spawning %s units from roster (starts: %d, scenes: %d)" % [
		label, starts.size(), scenes.size()
	])

	for i in range(starts.size()):
		var coord = starts[i]
		var scene_idx: int
		if is_player:
			if i >= scenes.size():
				print("[LevelBuilder] Warning: Player roster exhausted; skipping extra start at %s" % [coord])
				break
			scene_idx = i
		else:
			scene_idx = i % scenes.size()

		var scene = scenes[scene_idx]
		if not scene: continue

		_spawn_unit(scene, coord, is_player, is_neutral, modulate)

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


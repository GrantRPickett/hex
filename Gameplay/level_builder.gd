class_name LevelBuilder
extends RefCounted
# Goal and Unit classes are auto-global in Godot 4

var _context: LevelBuildContext

func _init(context: LevelBuildContext) -> void:
	_context = context

func build(level: Resource, terrain_map) -> Dictionary:
	var data = LevelLoader.load_level_data(level)

	var grid_width = data.grid_width
	var grid_height = data.grid_height
	var require_all_units = data.require_all_units

	if _context.controls:
		_context.controls.require_all_units_to_goal = require_all_units

	_context.camera.rotation = data.initial_rotation

	if is_instance_valid(_context.grid.tile_set):
		var ts: TileSet = _context.grid.tile_set
		if ts:
			var dup: TileSet = ts.duplicate(true)
			dup.tile_offset_axis = data.hex_offset_axis
			_context.grid.tile_set = dup

	if terrain_map:
		terrain_map.set_offset_axis(data.hex_offset_axis)
		terrain_map.load_from_rows(data.terrain_rows, grid_width, grid_height)

	_context.unit_manager.reset()

	# Players
	if "player_starts" in data and _context.player_roster:
		_spawn_roster_units(data.player_starts, _context.player_roster.units, true, false)

	# Enemies
	if "enemy_starts" in data and _context.enemy_roster:
		_spawn_roster_units(data.enemy_starts, _context.enemy_roster.enemy_types, false, false, Color.TOMATO)

	# Neutral
	if "neutral_starts" in data and _context.neutral_roster:
		_spawn_roster_units(data.neutral_starts, _context.neutral_roster.enemy_types, false, true, Color.LIGHT_SKY_BLUE)

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
						goal_instance.position = _context.grid.map_to_local(goals[i])
					goal_nodes.append(goal_instance)
	else:
		goal_nodes.assign(_context.goal_templates.map(func(node): return node as Goal))

	_context.goal_manager.setup(goals, goal_nodes, _context.grid)
	return {
		"grid_width": grid_width,
		"grid_height": grid_height,
		"require_all_units": require_all_units
	}

func _spawn_roster_units(starts: Array, scenes: Array[PackedScene], is_player: bool, _is_neutral: bool, modulate: Color = Color.WHITE) -> void:
	if scenes.is_empty():
		print("[LevelBuilder] Warning: No scenes provided for %s roster spawning." % ["player" if is_player else "enemy"])
		return

	print("[LevelBuilder] Spawning %s units from roster (starts: %d, scenes: %d)" % [
		"player" if is_player else "enemy", starts.size(), scenes.size()
	])

	for i in range(starts.size()):
		var coord = starts[i]
		# For players, we match 1:1 with roster. For others, we might cycle or use default.
		var scene_idx = i if is_player else 0
		if scene_idx >= scenes.size():
			scene_idx = 0

		var scene = scenes[scene_idx]
		if not scene: continue

		_spawn_unit(scene, coord, is_player, modulate)

func _spawn_unit(scene: PackedScene, coord: Vector2i, is_player: bool, modulate: Color = Color.WHITE) -> void:
	var unit_instance = scene.instantiate()
	if not (unit_instance is Unit):
		printerr("[LevelBuilder] Error: Instantiated scene is not a Unit: ", scene.resource_path)
		unit_instance.queue_free()
		return

	unit_instance.faction = Unit.Faction.PLAYER if is_player else Unit.Faction.ENEMY
	unit_instance.modulate = modulate
	_context.gameplay_root.add_child(unit_instance)

	if _context.grid.has_method("map_to_local"):
		unit_instance.position = _context.grid.map_to_local(coord)

	unit_instance.set_unit_manager(_context.unit_manager)
	unit_instance.set_goal_manager(_context.goal_manager)
	unit_instance.set_combat_system(_context.combat_system)
	if _context.loot_manager:
		unit_instance.set_loot_manager(_context.loot_manager)

	_context.unit_manager.add_unit(unit_instance, coord, is_player)
	_context.unit_manager.set_coord(_context.unit_manager.get_unit_count() - 1, coord)
	print("[LevelBuilder] Spawned %s unit '%s' at %s (Faction: %s, Scene: %s)" % [
		"Player" if is_player else "Enemy",
		unit_instance.unit_name,
		coord,
		unit_instance.get_faction_name(),
		scene.resource_path
	])

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
		var player_scenes = _context.player_roster.units
		for i in range(min(data.player_starts.size(), player_scenes.size())):
			var coord = data.player_starts[i]
			var scene = player_scenes[i]
			if not scene: continue

			var unit_instance = scene.instantiate()
			_context.gameplay_root.add_child(unit_instance)

			if _context.grid.has_method("map_to_local"):
				unit_instance.position = _context.grid.map_to_local(coord)

			unit_instance.set_unit_manager(_context.unit_manager)
			unit_instance.set_goal_manager(_context.goal_manager)
			unit_instance.set_combat_system(_context.combat_system)
			if _context.loot_manager:
				unit_instance.set_loot_manager(_context.loot_manager)

			_context.unit_manager.add_unit(unit_instance, coord, true)
			_context.unit_manager.set_coord(_context.unit_manager.get_unit_count() - 1, coord)

	# Enemies
	if "enemy_starts" in data and _context.enemy_roster:
		var enemy_scenes = _context.enemy_roster.enemy_types
		if not enemy_scenes.is_empty():
			var default_scene = enemy_scenes[0]
			for coord in data.enemy_starts:
				var unit_instance = default_scene.instantiate()
				unit_instance.modulate = Color.TOMATO
				_context.gameplay_root.add_child(unit_instance)

				if _context.grid.has_method("map_to_local"):
					unit_instance.position = _context.grid.map_to_local(coord)

				unit_instance.set_unit_manager(_context.unit_manager)
				unit_instance.set_goal_manager(_context.goal_manager)
				unit_instance.set_combat_system(_context.combat_system)
				if _context.loot_manager:
					unit_instance.set_loot_manager(_context.loot_manager)

				_context.unit_manager.add_unit(unit_instance, coord, false)
				_context.unit_manager.set_coord(_context.unit_manager.get_unit_count() - 1, coord)

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

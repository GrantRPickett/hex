class_name LevelBuilder
extends RefCounted
# Goal and Unit classes are auto-global in Godot 4

var _root: Node2D
var _unit_manager: UnitManager
var _goal_manager: GoalManager
var _grid: Node2D
var _camera: Camera2D
var _controls: Node
var _combat_system: CombatSystem
var _player_templates: Array[Unit]
var _enemy_templates: Array[Unit]
var _goal_templates: Array[Goal]

func _init(root: Node2D, unit_manager: UnitManager, goal_manager: GoalManager, combat_system: CombatSystem, grid: Node2D, camera: Camera2D, controls: Node, player_templates: Array[Unit], enemy_templates: Array[Unit], goal_templates: Array[Goal]) -> void:
	_root = root
	_unit_manager = unit_manager
	_goal_manager = goal_manager
	_combat_system = combat_system
	_grid = grid
	_camera = camera
	_controls = controls
	_player_templates = player_templates
	_enemy_templates = enemy_templates
	_goal_templates = goal_templates

func build(level: Resource, terrain_map) -> Dictionary:
	var data = LevelLoader.load_level_data(level)

	var grid_width = data.grid_width
	var grid_height = data.grid_height
	var require_all_units = data.require_all_units

	if _controls:
		_controls.require_all_units_to_goal = require_all_units

	_camera.rotation = data.initial_rotation

	if is_instance_valid(_grid.tile_set):
		var ts: TileSet = _grid.tile_set
		if ts:
			var dup: TileSet = ts.duplicate(true)
			dup.tile_offset_axis = data.hex_offset_axis
			_grid.tile_set = dup

	if terrain_map:
		terrain_map.set_offset_axis(data.hex_offset_axis)
		terrain_map.load_from_rows(data.terrain_rows, grid_width, grid_height)

	_unit_manager.reset()

	# Players
	if "player_starts" in data:
		for i in range(min(data.player_starts.size(), _player_templates.size())):
			var coord = data.player_starts[i]
			var template = _player_templates[i]
			var unit_instance = template.duplicate()
			_root.add_child(unit_instance)

			if _grid.has_method("map_to_local"):
				unit_instance.position = _grid.map_to_local(coord)

			unit_instance.set_unit_manager(_unit_manager)
			unit_instance.set_goal_manager(_goal_manager)
			unit_instance.set_combat_system(_combat_system)
			_unit_manager.add_unit(unit_instance, coord, true)
			_unit_manager.set_coord(_unit_manager.get_unit_count() - 1, coord)

	# Enemies
	if "enemy_starts" in data and not _enemy_templates.is_empty():
		var template = _enemy_templates[0]
		for coord in data.enemy_starts:
			var unit_instance = template.duplicate()
			unit_instance.modulate = Color.TOMATO
			_root.add_child(unit_instance)

			if _grid.has_method("map_to_local"):
				unit_instance.position = _grid.map_to_local(coord)

			unit_instance.set_unit_manager(_unit_manager)
			unit_instance.set_goal_manager(_goal_manager)
			unit_instance.set_combat_system(_combat_system)
			_unit_manager.add_unit(unit_instance, coord, false)
			_unit_manager.set_coord(_unit_manager.get_unit_count() - 1, coord)

	var goals: Array[Vector2i] = []
	goals.assign(data.goal_coords)
	var goal_nodes: Array[Goal] = []

	if _goal_templates.is_empty() and not goals.is_empty():
		var goal_scene = load("res://Gameplay/goal.tscn")
		if goal_scene:
			for i in range(goals.size()):
				var goal_instance = goal_scene.instantiate()
				if goal_instance is Goal:
					_root.add_child(goal_instance)
					if _grid.has_method("map_to_local"):
						goal_instance.position = _grid.map_to_local(goals[i])
					goal_nodes.append(goal_instance)
	else:
		goal_nodes.assign(_goal_templates.map(func(node): return node as Goal))

	_goal_manager.setup(goals, goal_nodes, _grid)
	return {
		"grid_width": grid_width,
		"grid_height": grid_height,
		"require_all_units": require_all_units
	}

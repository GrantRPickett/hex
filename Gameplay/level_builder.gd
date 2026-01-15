class_name LevelBuilder
extends RefCounted

var _root: Node2D
var _unit_manager: UnitManager
var _goal_manager: GoalManager
var _grid: Node2D
var _camera: Camera2D
var _controls: Node
var _player_template: Sprite2D
var _goal_templates: Array[Sprite2D]

func _init(root: Node2D, unit_manager: UnitManager, goal_manager: GoalManager, grid: Node2D, camera: Camera2D, controls: Node, player_template: Sprite2D, goal_templates: Array[Sprite2D]) -> void:
	_root = root
	_unit_manager = unit_manager
	_goal_manager = goal_manager
	_grid = grid
	_camera = camera
	_controls = controls
	_player_template = player_template
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

	# Player Units
	for i in range(data.player_starts.size()):
		var coord = data.player_starts[i]
		var sprite: Sprite2D
		if i == 0:
			sprite = _player_template
		else:
			sprite = _player_template.duplicate()
			_root.add_child(sprite)

		if _grid.has_method("map_to_local"):
			sprite.position = _grid.map_to_local(coord)

		_unit_manager.add_unit(sprite, coord, true)
		Unit.notify_unit_moved(coord)

	# Enemies
	if "enemy_starts" in data:
		for coord in data.enemy_starts:
			var sprite = _player_template.duplicate()
			sprite.modulate = Color.TOMATO
			_root.add_child(sprite)

			if _grid.has_method("map_to_local"):
				sprite.position = _grid.map_to_local(coord)

			_unit_manager.add_unit(sprite, coord, false)
			Unit.notify_unit_moved(coord)

	var goals: Array[Vector2i] = []
	goals.assign(data.goal_coords)
	_goal_manager.setup(goals, _goal_templates, _grid)
	return {
		"grid_width": grid_width,
		"grid_height": grid_height,
		"require_all_units": require_all_units
	}
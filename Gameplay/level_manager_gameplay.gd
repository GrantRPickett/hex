extends RefCounted
signal level_complete(next_level_path)
signal quit_to_title
signal quit_to_level_select

var _game_state: GameState
var _coordinator: Node2D
var _controls: Node
var _level_resource: Resource

var _require_all_units_state := false
var _goal_reached_state := false

func _init(game_state: GameState, coordinator: Node2D, controls: Node) -> void:
	_game_state = game_state
	_coordinator = coordinator
	_controls = controls
	if _controls:
		_require_all_units_state = _controls.require_all_units_to_goal

func set_level_resource(level: Resource) -> void:
	_level_resource = level

func apply_level_if_available() -> void:
	if not _level_resource or not _game_state:
		return

	if not is_instance_valid(_game_state.map_controller) or not is_instance_valid(_game_state.unit_manager) or not is_instance_valid(_game_state.goal_manager):
		return

	_set_goal_reached_state(false)

	var player_roster = _coordinator.player_roster
	var enemy_roster = _coordinator.enemy_roster
	var camera = _coordinator.get_node_or_null("Camera2D")
	var grid = _coordinator.get_node_or_null("Grid")
	var context = LevelBuildContext.new(
		_coordinator,
		_game_state.unit_manager,
		_game_state.goal_manager,
		_game_state.loot_manager,
		_game_state.combat_system,
		grid,
		camera,
		_controls,
		player_roster,
		enemy_roster,
		[]
	)

	var result = _game_state.map_controller.load_level(_level_resource, context)


	if "grid_width" in result:
		_coordinator._grid_width = result.grid_width
		_coordinator._grid_height = result.grid_height
		_game_state.move_controller.update_grid_dimensions(result.grid_width, result.grid_height)

	if "require_all_units" in result:
		_set_require_all_units_state(result.require_all_units)

	_game_state.turn_controller.rebuild_turn_roster()
	_coordinator._update_terrain_overlay()

func set_level_and_rebuild(level: Resource) -> void:
	_level_resource = level
	apply_level_if_available()
	if not _game_state:
		return
	if not is_instance_valid(_game_state.goal_controller):
		return
	_game_state.goal_controller.reset_goal_state()
	_game_state.grid_controller.build_grid(_coordinator._grid_width, _coordinator._grid_height)

	var grid = _coordinator.get_node_or_null("Grid")
	if grid:
		_game_state.hex_navigator.cache_analog_vectors(grid)

	_game_state.camera_controller.init_camera_snap()
	_game_state.camera_controller.center_on_selected()

func on_goal_reached() -> void:
	var player_roster = _coordinator.player_roster

	if player_roster and _game_state.unit_manager:
		var player_units: Array[Unit] = []
		for i in range(_game_state.unit_manager.get_unit_count()):
			if _game_state.unit_manager.is_player_controlled(i):
				var unit = _game_state.unit_manager.get_unit(i)
				if is_instance_valid(unit):
					player_units.append(unit)
		player_roster.update_roster(player_units)

		var save_manager = _coordinator.get_tree().root.get_node_or_null("SaveManager")
		if save_manager and save_manager.has_method("save_roster"):
			save_manager.save_roster(player_roster)

	var next_level_path: String = ""
	if _level_resource and "next_level_path" in _level_resource and _level_resource.next_level_path != null:
		next_level_path = _level_resource.next_level_path

	if next_level_path.is_empty():
		quit_to_level_select.emit()
	else:
		level_complete.emit(next_level_path)

func _set_require_all_units_state(value: bool) -> void:
	_require_all_units_state = value
	if _controls:
		_controls.require_all_units_to_goal = value
	if _game_state:
		_game_state.goal_controller.set_require_all_units(value)

func _get_require_all_units_state() -> bool:
	return _require_all_units_state

func _get_goal_reached_state() -> bool:
	if _game_state:
		_goal_reached_state = _game_state.goal_controller.is_goal_reached()
	return _goal_reached_state

func _set_goal_reached_state(value: bool) -> void:
	_goal_reached_state = value
	if not _game_state:
		return
	if value:
		return
	_game_state.goal_controller.reset_goal_state()

func update_goal_progress() -> void:
	if _game_state.goal_controller:
		_game_state.goal_controller.check_goal_progress()
		_goal_reached_state = _game_state.goal_controller.is_goal_reached()
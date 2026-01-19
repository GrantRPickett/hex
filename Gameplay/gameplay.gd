extends Node2D

signal level_complete(next_level_path)
signal quit_to_title
signal quit_to_level_select

const GameSessionBuilderScript := preload("res://Gameplay/game_session_builder.gd")
const InputMapperScript := preload("res://Autoloads/input_mapper.gd")
# InputActions class is auto-global in Godot 4

@onready var _grid: TileMapLayer = $Grid
@onready var _camera: Camera2D = $Camera2D
@onready var _camera_handler: CameraHandler = $CameraHandler
@onready var _pause_handler: PauseHandler = $PauseHandler
@onready var _input_handler: InputHandler = $InputHandler

var _game_state: GameState
var _unit_manager: UnitManager
var _goal_manager: GoalManager
var _loot_manager: LootManager
var _hex_navigator: HexNavigator
var _move_controller: MoveController
var _goal_controller: GoalController
var _camera_controller: CameraController
var _input_controller: InputController
var _turn_system: TurnSystem
var _require_all_units_state := false
var _goal_reached_state := false

var _grid_width: int
var _grid_height: int
var _last_mouse_coord: Vector2i = Vector2i.MAX

var _controls: Node
@export var level_resource: Resource
@export var player_roster: PlayerRoster
@export var enemy_roster: EnemyRoster

func _ready() -> void:
	_grid_width = GameConfig.DEFAULT_GRID_WIDTH
	_grid_height = GameConfig.DEFAULT_GRID_HEIGHT
	var save_manager = get_tree().root.get_node_or_null("SaveManager")
	if not player_roster and save_manager and save_manager.has_method("has_saved_roster") and save_manager.has_saved_roster():
		player_roster = save_manager.load_roster()

	if not player_roster and ResourceLoader.exists("res://Resources/default_player_roster.tres"):
		player_roster = load("res://Resources/default_player_roster.tres")

	if not player_roster:
		var generic_unit = load("res://Gameplay/generic_unit.tscn")
		if generic_unit:
			player_roster = PlayerRoster.new()
			player_roster.units = [generic_unit, generic_unit]

	if not enemy_roster and ResourceLoader.exists("res://Resources/default_enemy_roster.tres"):
		enemy_roster = load("res://Resources/default_enemy_roster.tres")

	if not enemy_roster:
		var generic_unit = load("res://Gameplay/generic_unit.tscn")
		if generic_unit:
			enemy_roster = EnemyRoster.new()
			enemy_roster.enemy_types = [generic_unit]

	_controls = get_tree().root.get_node_or_null("ControlSettings")
	if _controls == null:
		push_warning("ControlSettings autoload not found in Gameplay.gd!")

	var builder := GameSessionBuilderScript.new()
	var build_config := GameSessionBuilderScript.Config.new()
	build_config.grid = _grid
	build_config.camera = _camera
	build_config.camera_handler = _camera_handler
	build_config.input_handler = _input_handler
	build_config.controls = _controls
	build_config.input_mapper = get_tree().root.get_node_or_null("InputMapper")
	_game_state = builder.build(build_config)
	_attach_game_state_nodes()
	_cache_context_references()
	_ensure_input_actions_registered()

	_game_state.grid_controller.configure_tileset()

	_game_state.unit_manager.unit_moved.connect(_on_unit_moved)
	_game_state.unit_manager.selection_changed.connect(_on_selection_changed)
	_game_state.loot_manager.loot_added.connect(_on_loot_added)
	_game_state.turn_controller.turn_changed.connect(_on_turn_changed)

	if is_instance_valid(_pause_handler):
		_pause_handler.quit_requested.connect(_on_quit_requested)

	_game_state.goal_controller.reset_goal_state()
	set_physics_process(true)
	set_process(true)
	_apply_level_if_available()

	_game_state.grid_controller.build_grid(_grid_width, _grid_height)
	_game_state.hex_navigator.cache_analog_vectors(_grid)

	_game_state.grid_visuals.setup_hex_shape(Vector2(_grid.tile_set.tile_size), _grid)

	_game_state.camera_controller.center_on_selected()
	# Initialize camera snap base to nearest 60° and avoid drift
	_game_state.camera_controller.init_camera_snap()

func _attach_game_state_nodes() -> void:
	if _game_state == null:
		return
	for node in _game_state.get_tree_nodes():
		if node == null:
			continue
		add_child(node)

func _cache_context_references() -> void:
	if _game_state == null:
		return
	_unit_manager = _game_state.unit_manager
	_goal_manager = _game_state.goal_manager
	_loot_manager = _game_state.loot_manager
	_hex_navigator = _game_state.hex_navigator
	_move_controller = _game_state.move_controller
	_goal_controller = _game_state.goal_controller
	_camera_controller = _game_state.camera_controller
	_input_controller = _game_state.input_controller
	_turn_system = _game_state.turn_controller.get_turn_system()
	_goal_reached_state = _game_state.goal_controller.is_goal_reached()
	if _controls:
		_require_all_units_state = _controls.require_all_units_to_goal

func _set_require_all_units_state(value: bool) -> void:
	_require_all_units_state = value
	if _controls:
		_controls.require_all_units_to_goal = value
	if _game_state:
		_game_state.goal_controller.set_require_all_units(value)

func _get_require_all_units_state() -> bool:
	return _require_all_units_state

func _set_goal_reached_state(value: bool) -> void:
	_goal_reached_state = value
	if not _game_state:
		return
	if value:
		return
	_game_state.goal_controller.reset_goal_state()

func _get_goal_reached_state() -> bool:
	if _game_state:
		_goal_reached_state = _game_state.goal_controller.is_goal_reached()
	return _goal_reached_state

func _ensure_input_actions_registered() -> void:
	var mapper: Node = get_tree().root.get_node_or_null("InputMapper")
	if mapper == null:
		mapper = InputMapperScript.new()
	var groups = [
		InputActions.MOVEMENT_DEFAULTS,
		InputActions.INTERACTION_DEFAULTS,
		InputActions.CAMERA_DEFAULTS,
		InputActions.SELECTION_DEFAULTS,
		InputActions.PAUSE_DEFAULTS,
	]
	for group in groups:
		var missing: Array = []
		for entry in group:
			var action_name: String = entry.get("action", "")
			if action_name == "":
				continue
			if not InputMap.has_action(action_name):
				missing.append(entry)
		if not missing.is_empty():
			mapper.apply_configs(missing, missing)

func _set(property: StringName, value) -> bool:
	var property_name := String(property)
	match property_name:
		"_require_all_units":
			_set_require_all_units_state(bool(value))
			return true
		"_goal_reached":
			_set_goal_reached_state(bool(value))
			return true
	return false

func _get(property: StringName):
	var property_name := String(property)
	match property_name:
		"_require_all_units":
			return _get_require_all_units_state()
		"_goal_reached":
			return _get_goal_reached_state()
	return null

func _on_quit_requested() -> void:
	_disable_gameplay()
	quit_to_title.emit()

func _process(_delta: float) -> void:
	if is_instance_valid(_game_state.grid_visuals):
		var mouse_pos = get_global_mouse_position()
		var current_coord := _grid.local_to_map(_grid.to_local(mouse_pos))
		if current_coord != _last_mouse_coord:
			_last_mouse_coord = current_coord
			_game_state.grid_visuals.update_hover_indicator(mouse_pos, _grid, _game_state.unit_manager, _game_state.map_controller.get_terrain_map())
			_game_state.grid_visuals.update_path_preview(mouse_pos, _grid, _game_state.unit_manager, _game_state.map_controller.get_terrain_map())

func set_joy_axis(axis: Vector2) -> void:
	# Legacy support for tests if they call this directly
	if _input_handler:
		_input_handler._joy_axis = axis
		_input_handler._joy_repeat_timer = 0.0

func _on_unit_moved(index: int, coord: Vector2i) -> void:
	var unit: Unit = _game_state.unit_manager.get_unit(index)
	if unit:
		var target_pos = _grid.map_to_local(coord)
		var tween = unit.create_tween()
		tween.tween_property(unit, "position", target_pos, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if index == _game_state.unit_manager.get_selected_index():
		_update_selection_visuals()

func _on_selection_changed(_index: int) -> void:
	_update_selection_visuals()

func _on_turn_changed(_unit_index: int) -> void:
	#if _game_state.turn_controller:
		#_game_state.goal_controller.process_turn_progress()
	pass

func _on_loot_added(loot: Loot, coord: Vector2i) -> void:
	if loot.get_parent() == null:
		_grid.add_child(loot)
	if loot is Target:
		loot.grid_map = _grid
		loot.position = _grid.map_to_local(coord)

func _update_selection_visuals() -> void:
	_game_state.camera_controller.center_on_selected()
	if is_instance_valid(_game_state.grid_visuals):
		_game_state.grid_visuals.update_range_indicator(_grid, _game_state.unit_manager, _game_state.map_controller.get_terrain_map())

func _register_input_actions() -> void:
	if _input_controller:
		_input_controller.call("_register_input_actions")
	_ensure_input_actions_registered()

func _on_select_index_requested(index: int) -> void:
	if _input_controller:
		_input_controller._on_select_index_requested(index)

func _on_selection_cycle_requested(direction: int) -> void:
	if _input_controller:
		_input_controller._on_selection_cycle_requested(direction)

func request_move(action: String) -> void:
	if _move_controller:
		_move_controller.request_move(action)

func _on_wait_requested() -> void:
	if _input_controller:
		_input_controller._on_wait_requested()

func _center_camera_on_selected() -> void:
	if _camera_controller:
		_camera_controller.center_on_selected()

func _axial_to_pixel(coord: Vector2i) -> Vector2:
	return _grid.map_to_local(coord)

func update_goal_progress_for_selected() -> void:
	_update_goal_progress_for_selected()

func _update_goal_progress_for_selected() -> void:
	if _goal_controller:
		_goal_controller.check_goal_progress()
		_goal_reached_state = _goal_controller.is_goal_reached()

func _apply_level_if_available() -> void:
	if not level_resource:
		return

	_set_goal_reached_state(false)
	var result = _game_state.map_controller.load_level(level_resource, self, _game_state.unit_manager, _game_state.goal_manager, _game_state.loot_manager, _game_state.combat_system, _camera, _controls, player_roster, enemy_roster, [])
	_grid_width = result.grid_width
	_grid_height = result.grid_height
	_set_require_all_units_state(result.require_all_units)
	_game_state.move_controller.update_grid_dimensions(_grid_width, _grid_height)

	_game_state.turn_controller.rebuild_turn_roster()
	_update_terrain_overlay()

func set_level_and_rebuild(level: Resource) -> void:
	level_resource = level
	_apply_level_if_available()
	# Reset goal progress when loading a level
	_game_state.goal_controller.reset_goal_state()
	_game_state.grid_controller.build_grid(_grid_width, _grid_height)
	_game_state.hex_navigator.cache_analog_vectors(_grid)

	_game_state.camera_controller.init_camera_snap()
	_game_state.camera_controller.center_on_selected()

func add_unit(unit: Unit, coord: Vector2i, is_player: bool) -> void:
	_game_state.unit_controller.add_unit(unit, coord, is_player)
	if _loot_manager:
		unit.set_loot_manager(_loot_manager)
	_game_state.turn_controller.rebuild_turn_roster()
	_update_terrain_overlay()

func set_unit_controlled_by_player(index: int, is_player: bool) -> void:
	_game_state.unit_controller.set_player_controlled(index, is_player)
	_game_state.turn_controller.rebuild_turn_roster()
	_update_terrain_overlay()

# Legacy helpers for tests
var player_coord: Vector2i:
	get: return _game_state.unit_manager.get_coord(0)
var goal_coord: Vector2i:
	get: return _game_state.goal_manager.get_target(0)
var goal2_coord: Vector2i:
	get: return _game_state.goal_manager.get_target(1)

func set_player_coord(coord: Vector2i) -> void:
	_game_state.unit_controller.set_coord(0, coord)

func set_goal_coord(coord: Vector2i) -> void:
	_game_state.goal_manager.set_target(0, coord)

func set_turn_system_enabled(enabled: bool) -> void:
	_game_state.turn_controller.set_enabled(enabled)
	_update_terrain_overlay()

func _update_terrain_overlay() -> void:
	if is_instance_valid(_game_state.grid_visuals):
		_game_state.grid_visuals.update_terrain_overlay(_grid, _game_state.map_controller.get_terrain_map())

func _on_goal_reached() -> void:
	_disable_gameplay()

	if player_roster and _unit_manager:
		var player_units: Array[Unit] = []
		for i in range(_unit_manager.get_unit_count()):
			if _unit_manager.is_player_controlled(i):
				var unit = _unit_manager.get_unit(i)
				if unit:
					player_units.append(unit)
		player_roster.update_roster(player_units)

		var save_manager = get_tree().root.get_node_or_null("SaveManager")
		if save_manager and save_manager.has_method("save_roster"):
			save_manager.save_roster(player_roster)

	var next_level_path: String = ""
	if level_resource and "next_level_path" in level_resource and level_resource.next_level_path != null:
		next_level_path = level_resource.next_level_path
	if next_level_path.is_empty():
		quit_to_level_select.emit()
	else:
		level_complete.emit(next_level_path)

func _disable_gameplay() -> void:
	if _input_handler:
		_input_handler.reset_joy_state()
		_input_handler.set_process_unhandled_input(false)
	set_physics_process(false)
	_game_state.move_controller.set_physics_process(false)
	set_process(false)

func _exit_tree() -> void:
	# Disconnect all signals to prevent memory leaks and stale connections
	if _game_state:
		if _game_state.unit_manager and _game_state.unit_manager.unit_moved.is_connected(_on_unit_moved):
			_game_state.unit_manager.unit_moved.disconnect(_on_unit_moved)
		if _game_state.unit_manager and _game_state.unit_manager.selection_changed.is_connected(_on_selection_changed):
			_game_state.unit_manager.selection_changed.disconnect(_on_selection_changed)
		if _game_state.loot_manager and _game_state.loot_manager.loot_added.is_connected(_on_loot_added):
			_game_state.loot_manager.loot_added.disconnect(_on_loot_added)
		if _game_state.turn_controller and _game_state.turn_controller.turn_changed.is_connected(_on_turn_changed):
			_game_state.turn_controller.turn_changed.disconnect(_on_turn_changed)
		if _game_state.goal_controller and _game_state.goal_controller.goal_reached.is_connected(_on_goal_reached):
			_game_state.goal_controller.goal_reached.disconnect(_on_goal_reached)

	if is_instance_valid(_pause_handler) and _pause_handler.quit_requested.is_connected(_on_quit_requested):
		_pause_handler.quit_requested.disconnect(_on_quit_requested)

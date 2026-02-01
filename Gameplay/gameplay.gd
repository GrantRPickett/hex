extends Node2D

signal level_complete(next_level_path)
signal quit_to_title
signal quit_to_level_select

const LevelManagerGameplay := preload("res://Gameplay/level_manager_gameplay.gd")
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

var _level_manager_gameplay: LevelManagerGameplay

var _controls: Node
var _input_mapper: Node
var _save_manager: Node
@export var level_resource: Resource
@export var player_roster: PlayerRoster
@export var enemy_roster: EnemyRoster
@export var neutral_roster: NeutralRoster
@export var control_settings_path := NodePath("/root/ControlSettings")
@export var input_mapper_path := NodePath("/root/InputMapper")
@export var save_manager_path := NodePath("/root/SaveManager")
var _hometown_exit_triggered := false # Added to prevent multiple triggers

func _ready() -> void:
	_controls = _resolve_dependency(control_settings_path, "ControlSettings")
	_input_mapper = _resolve_dependency(input_mapper_path, "InputMapper")
	_save_manager = _resolve_dependency(save_manager_path, "SaveManager")
	var builder :GameSessionBuilder= GameSessionBuilder.new()

	player_roster = builder.load_player_roster(player_roster, _save_manager)
	enemy_roster = builder.load_enemy_roster(enemy_roster)
	neutral_roster = builder.load_neutral_roster(neutral_roster)

	# ControlSettings autoload may not be available in test contexts
	# _require_all_units_state defaults to false if _controls is null

	var build_config := GameSessionBuilder.Config.new()
	build_config.grid = _grid
	build_config.camera = _camera
	build_config.camera_handler = _camera_handler
	build_config.input_handler = _input_handler
	build_config.controls = _controls
	build_config.input_mapper = _input_mapper
	_game_state = builder.build(build_config)
	_attach_game_state_nodes()
	_cache_context_references()
	_register_input_actions()

	_level_manager_gameplay = LevelManagerGameplay.new(_game_state, self, _controls)
	if _game_state.dialogue_action_service:
		_level_manager_gameplay.set_dialogue_service(_game_state.dialogue_action_service)
	_level_manager_gameplay.set_save_manager(_save_manager)
	_level_manager_gameplay.set_level_resource(level_resource)
	_level_manager_gameplay.level_complete.connect(func(path): level_complete.emit(path))
	_level_manager_gameplay.quit_to_title.connect(func(): quit_to_title.emit())
	_level_manager_gameplay.quit_to_level_select.connect(func(): quit_to_level_select.emit())

	_game_state.grid_controller.configure_tileset()

	_game_state.unit_manager.unit_moved.connect(_on_unit_moved)
	_game_state.unit_manager.selection_changed.connect(_on_selection_changed)
	_game_state.loot_manager.loot_added.connect(_on_loot_added)
	_game_state.turn_controller.turn_changed.connect(_on_turn_changed)
	_game_state.unit_manager.unit_spawn_requested.connect(_on_unit_spawn_requested)
	_game_state.goal_controller.goal_reached.connect(_level_manager_gameplay.on_goal_reached)
	_input_controller.checkpoint_requested.connect(_on_checkpoint_requested)
	_input_controller.undo_requested.connect(_on_undo_requested)
	_input_controller.redo_requested.connect(_on_redo_requested)

	if is_instance_valid(_pause_handler):
		_pause_handler.quit_requested.connect(_on_quit_requested)

	_game_state.goal_controller.reset_goal_state()
	set_physics_process(true)
	_level_manager_gameplay.apply_level_if_available()

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
	_level_manager_gameplay._set_require_all_units_state(value)

func _get_require_all_units_state() -> bool:
	return _level_manager_gameplay._get_require_all_units_state()

func _set_goal_reached_state(value: bool) -> void:
	_level_manager_gameplay._set_goal_reached_state(value)

func _get_goal_reached_state() -> bool:
	if _level_manager_gameplay:
		return _level_manager_gameplay._get_goal_reached_state()
	return false

func _resolve_dependency(path: NodePath, label: String) -> Node:
	if path.is_empty():
		return null
	var node := get_node_or_null(path)
	if node == null:
		push_warning("Gameplay: Missing %s at %s" % [label, path])
	return node

func _on_quit_requested() -> void:
	_disable_gameplay()
	quit_to_title.emit()


func _on_unit_moved(index: int, coord: Vector2i) -> void:
	var unit: Unit = _game_state.unit_manager.get_unit(index)
	var is_selected := index == _game_state.unit_manager.get_selected_index()
	if is_selected and _move_controller:
		_move_controller.force_action_menu_update()
	if unit:
		var target_pos = _grid.map_to_local(coord)
		var tween = unit.create_tween()
		tween.tween_property(unit, "position", target_pos, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		# Check if the selected unit has moved to the hometown exit coordinate
		if is_selected and _level_manager_gameplay._is_hometown_level(_level_manager_gameplay._level_resource) and coord == Vector2i(1, 1):
			if not _hometown_exit_triggered:
				_hometown_exit_triggered = true
				print_debug("Player reached hometown exit (1,1). Emitting quit_to_level_select.")
				_level_manager_gameplay.quit_to_level_select.emit()
	if is_selected:
		_update_selection_visuals()

func _on_selection_changed(_index: int) -> void:
	_update_selection_visuals()
	if _move_controller:
		_move_controller.force_action_menu_update()

func _on_turn_changed(unit: Unit) -> void:
	# Create a checkpoint at the start of a turn
	if _game_state and _game_state.checkpoint_manager:
		_game_state.checkpoint_manager.create_checkpoint(_game_state)

	# Unit refresh is now handled at the start of each round
	pass


func _on_loot_added(loot: Loot, coord: Vector2i) -> void:
	if loot.get_parent() == null:
		_grid.add_child(loot)
	if loot is Target:
		loot.grid_map = _grid
		loot.position = _grid.map_to_local(coord)

func _on_unit_spawn_requested(unit: Unit) -> void:
	if not is_instance_valid(unit):
		return

	unit.set_unit_manager(_unit_manager)
	unit.set_loot_manager(_loot_manager)
	unit.set_goal_manager(_goal_manager)
	unit.set_combat_system(_game_state.combat_system)
	# Removed: _grid.add_child(unit) as unit is already a child of Gameplay

	unit.grid_map = _grid
	unit.snap_to_grid()
	_update_selection_visuals()

func _on_checkpoint_requested() -> void:
	if _game_state and _game_state.checkpoint_manager:
		_game_state.checkpoint_manager.create_checkpoint(_game_state)

func _on_undo_requested() -> void:
	if _game_state and _game_state.checkpoint_manager:
		if _game_state.checkpoint_manager.undo(_game_state):
			_update_selection_visuals()
			_show_feedback("Undo")

func _on_redo_requested() -> void:
	if _game_state and _game_state.checkpoint_manager:
		if _game_state.checkpoint_manager.redo(_game_state):
			_update_selection_visuals()
			_show_feedback("Redo")

func _update_selection_visuals() -> void:
	_game_state.camera_controller.center_on_selected()
	if is_instance_valid(_game_state.grid_visuals):
		_game_state.grid_visuals.update_range_indicator(_grid, _game_state.unit_manager, _game_state.map_controller.get_terrain_map())

func _register_input_actions() -> void:
	if _input_controller:
		_input_controller.register_input_actions()
	_apply_control_settings_bindings()

func _apply_control_settings_bindings() -> void:
	if _input_mapper == null:
		push_warning("Gameplay: InputMapper dependency missing; cannot apply control settings")
		return
	_apply_action_group(_get_action_configs("move_actions", InputActions.MOVEMENT_DEFAULTS), InputActions.MOVEMENT_DEFAULTS)
	_apply_action_group(_get_action_configs("interaction_actions", InputActions.INTERACTION_DEFAULTS), InputActions.INTERACTION_DEFAULTS)
	_apply_action_group(_get_action_configs("camera_actions", InputActions.CAMERA_DEFAULTS), InputActions.CAMERA_DEFAULTS)
	_apply_action_group(_get_action_configs("selection_actions", InputActions.SELECTION_DEFAULTS), InputActions.SELECTION_DEFAULTS)
	_apply_action_group(_get_action_configs("pause_actions", InputActions.PAUSE_DEFAULTS), InputActions.PAUSE_DEFAULTS)
	_apply_action_group(_get_action_configs("visual_actions", []), InputActions.VISUAL_DEFAULTS)

func _get_action_configs(property_name: String, fallback: Array) -> Array:
	if _controls:
		var value = _controls.get(property_name)
		if value is Array:
			return value
	return fallback

func _apply_action_group(configs: Array, fallback: Array) -> void:
	if _input_mapper and _input_mapper.has_method("apply_configs"):
		_input_mapper.apply_configs(configs, fallback)

func _on_select_index_requested(index: int) -> void:
	if _input_controller:
		_input_controller.request_select_index(index)

func _on_selection_cycle_requested(direction: int) -> void:
	if _input_controller:
		_input_controller.request_selection_cycle(direction)

func request_move(action: String) -> void:
	if _move_controller:
		_move_controller.request_move(action)

func _on_wait_requested() -> void:
	if _input_controller:
		_input_controller.request_wait()

func _center_camera_on_selected() -> void:
	if _camera_controller:
		_camera_controller.center_on_selected()

func _axial_to_pixel(coord: Vector2i) -> Vector2:
	return _grid.map_to_local(coord)

func update_goal_progress_for_selected() -> void:
	_update_goal_progress_for_selected()

func _update_goal_progress_for_selected() -> void:
	if _level_manager_gameplay:
		_level_manager_gameplay.update_goal_progress()

func _apply_level_if_available() -> void:
	if _level_manager_gameplay:
		_level_manager_gameplay.apply_level_if_available()

func set_level_and_rebuild(level: Resource) -> void:
	if _level_manager_gameplay:
		_level_manager_gameplay.set_level_and_rebuild(level)

func add_unit(unit: Unit, coord: Vector2i, is_player: bool) -> void:
	if not _game_state or not is_instance_valid(_game_state.unit_controller):
		return
	_game_state.unit_controller.add_unit(unit, coord, is_player)
	if _loot_manager:
		unit.set_loot_manager(_loot_manager)
	_game_state.turn_controller.rebuild_turn_roster()
	_update_terrain_overlay()

func set_unit_controlled_by_player(index: int, is_player: bool) -> void:
	if not _game_state or not is_instance_valid(_game_state.unit_controller):
		return
	_game_state.unit_controller.set_player_controlled(index, is_player)
	_game_state.turn_controller.rebuild_turn_roster()
	_update_terrain_overlay()

func set_player_coord(coord: Vector2i) -> void:
	if _game_state and is_instance_valid(_game_state.unit_controller):
		_game_state.unit_controller.set_coord(0, coord)

func set_goal_coord(coord: Vector2i) -> void:
	if _game_state and is_instance_valid(_game_state.goal_manager):
		_game_state.goal_manager.set_target(0, coord)

func set_turn_system_enabled(enabled: bool) -> void:
	if not _game_state or not is_instance_valid(_game_state.turn_controller):
		return
	_game_state.turn_controller.set_enabled(enabled)
	_update_terrain_overlay()

func _update_terrain_overlay() -> void:
	if is_instance_valid(_game_state.grid_visuals):
		_game_state.grid_visuals.update_terrain_overlay(_grid, _game_state.map_controller.get_terrain_map())

func _on_goal_reached() -> void:
	# Handled by LevelManagerGameplay
	pass

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
		if _game_state.goal_controller and _game_state.goal_controller.goal_reached.is_connected(_level_manager_gameplay.on_goal_reached):
			_game_state.goal_controller.goal_reached.disconnect(_level_manager_gameplay.on_goal_reached)

	if is_instance_valid(_pause_handler) and _pause_handler.quit_requested.is_connected(_on_quit_requested):
		_pause_handler.quit_requested.disconnect(_on_quit_requested)

func _show_feedback(text: String) -> void:
	if not _game_state or not _game_state.hud:
		return

	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)

	_game_state.hud.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

	var tween = create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -50), 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN)
	tween.tween_callback(label.queue_free)

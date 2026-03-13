class_name GameSession
extends Node2D

signal session_started
signal session_ended

var state: GameState
var _builder: GameSessionBuilder
var _config: GameSessionBuilder.Config

func _init(p_config: GameSessionBuilder.Config) -> void:
	_config = p_config
	_builder = GameSessionBuilder.new()
	state = _builder.build(_config)

func initialize() -> void:
	_attach_services()
	_initialize_technical_systems()
	session_started.emit()

func _initialize_technical_systems() -> void:
	if state.hex_navigator and _config.grid:
		state.hex_navigator.cache_analog_vectors(_config.grid)
	if state.grid_visuals and _config.grid:
		state.grid_visuals.setup_hex_shape(Vector2(_config.grid.tile_set.tile_size), _config.grid)
	if state.map_controller:
		state.map_controller.configure_tileset()
	if state.input_controller:
		state.input_controller.register_input_actions()

func _attach_services() -> void:
	print_debug("[GameSession] _attach_services calling for ", state.get_tree_nodes().size(), " nodes")
	for node in state.get_tree_nodes():
		if node:
			if not node.is_inside_tree():
				var node_name: String = String(node.name) if not String(node.name).is_empty() else str(node)
				print_debug("[GameSession] Adding node to tree: ", node_name)
				add_child(node)
			else:
				var parent_name: String = String(node.get_parent().name) if node.get_parent() else "no parent"
				print_debug("[GameSession] Node already in tree: ", String(node.name), " (", parent_name, ")")

func end_session() -> void:
	session_ended.emit()
	queue_free()

func add_unit(unit: Unit, coord: Vector2i, is_player: bool) -> void:
	if not state or not is_instance_valid(state.unit_controller):
		return
	state.unit_controller.add_unit(unit, coord, is_player)
	state.turn_controller.rebuild_turn_roster()
	_update_terrain_overlay()

func set_unit_controlled_by_player(index: int, is_player: bool) -> void:
	if not state or not is_instance_valid(state.unit_controller):
		return
	state.unit_controller.set_player_controlled(index, is_player)
	state.turn_controller.rebuild_turn_roster()
	_update_terrain_overlay()

func handle_pause_state_changed(paused: bool) -> void:
	if not state or not is_instance_valid(state.turn_controller):
		return
	state.turn_controller.set_enabled(not paused)
	if not paused and state.turn_controller.get_turn_system().get_current_side() == TurnSystem.Side.NEUTRAL:
		state.turn_controller.start_next_turn()

func handle_hud_toggle(visible: bool) -> void:
	if state.hud:
		state.hud.visible = visible

func _update_terrain_overlay() -> void:
	if is_instance_valid(state.grid_visuals) and _config.grid:
		state.grid_visuals.update_terrain_overlay(_config.grid, state.map_controller.get_terrain_map())

func disable_gameplay() -> void:
	if _config.input_handler:
		_config.input_handler.reset_joy_state()
		_config.input_handler.set_process_unhandled_input(false)
	# Note: Gameplay node handles its own physics_process
	if state.move_controller:
		state.move_controller.set_physics_process(false)

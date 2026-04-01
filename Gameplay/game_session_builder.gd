class_name GameSessionBuilder
extends RefCounted

const DEFAULT_ANIMATION_STYLE_SET_PATH := FilePaths.Resources.DEFAULT_ANIMATION_STYLE_SET

const DEFAULT_PLAYER_ROSTER_PATH: String = RosterLoader.DEFAULT_PLAYER_ROSTER_PATH
const DEFAULT_ENEMY_ROSTER_PATH: String = RosterLoader.DEFAULT_ENEMY_ROSTER_PATH
const DEFAULT_NEUTRAL_ROSTER_PATH: String = RosterLoader.DEFAULT_NEUTRAL_ROSTER_PATH

static var _REQUIRED_SERVICE_FIELDS := [
	GameConstants.ContextKeys.UNIT_CONTROLLER,
	GameConstants.ContextKeys.UNIT_MANAGER,
	GameConstants.ContextKeys.TASK_MANAGER,
	GameConstants.ContextKeys.LOOT_MANAGER,
	GameConstants.ContextKeys.HEX_NAVIGATOR,
	GameConstants.ContextKeys.GRID_VISUALS,
	GameConstants.ContextKeys.HUD_CONTROLLER,
	GameConstants.ContextKeys.INPUT_CONTROLLER,
	GameConstants.ContextKeys.MOVE_CONTROLLER,
	GameConstants.ContextKeys.ANIMATION_SERVICE,
	GameConstants.ContextKeys.CAMERA_CONTROLLER,
	GameConstants.ContextKeys.TASK_CONTROLLER,
	GameConstants.ContextKeys.MAP_CONTROLLER,
	GameConstants.ContextKeys.AI_CONTROLLER,
	GameConstants.ContextKeys.COMBAT_SYSTEM,
	GameConstants.ContextKeys.CHECKPOINT_MANAGER
]

class Config extends RefCounted:
	var grid: TileMapLayer
	var camera: Camera2D
	var camera_handler: CameraHandler
	var input_handler: InputHandler
	var pause_handler: PauseHandler
	var controls: Node
	var input_mapper: Node
	var services_factory: GameSessionServiceFactory
	var animation_style_set: AnimationStyleSet
	var level: Level
	var player_roster: PlayerRoster
	var save_manager: Node

var _roster_loader: RosterLoader

func set_roster_loader(loader: RosterLoader) -> void:
	_roster_loader = loader

func build(config: Config) -> GameState:
	assert(config != null, "GameSessionBuilder requires a config object.")
	assert(config.grid != null, "GameSessionBuilder requires a grid reference.")

	var services := _prepare_services(config)
	var game_state := _create_game_state(services, config)

	_setup_core_systems(game_state, config)
	_setup_input_and_hud(game_state, config, services)
	_register_observers(game_state, config)

	if game_state.checkpoint_manager and game_state.checkpoint_manager.has_method("setup"):
		game_state.checkpoint_manager.setup(game_state)

	return game_state

func _prepare_services(config: Config) -> Dictionary:
	var factory: GameSessionServiceFactory = config.services_factory
	if factory == null:
		factory = DefaultGameSessionServiceFactory.new()

	var services := factory.create_services()
	assert(services != null, "Service factory must return a services dictionary.")

	if config.save_manager != null:
		services[GameConstants.ContextKeys.SAVE_MANAGER] = config.save_manager

	if not services.has(GameConstants.ContextKeys.UNIT_MANAGER) and services.has(GameConstants.ContextKeys.UNIT_CONTROLLER) and services[GameConstants.ContextKeys.UNIT_CONTROLLER] != null:
		services[GameConstants.ContextKeys.UNIT_MANAGER] = services[GameConstants.ContextKeys.UNIT_CONTROLLER].get_unit_manager()
	services[GameConstants.ContextKeys.LEVEL_RESOURCE] = config.level

	_validate_required_services(services)

	if not services.has(GameConstants.ContextKeys.HUD) or services[GameConstants.ContextKeys.HUD] == null:
		services[GameConstants.ContextKeys.HUD] = Hud.new()

	return services

func _validate_required_services(services: Dictionary) -> void:
	for field in _REQUIRED_SERVICE_FIELDS:
		var dependency = services.get(field)
		assert(dependency != null, "Services dictionary missing required dependency '%s'." % field)

func _setup_core_systems(state: GameState, config: Config) -> void:
	state.map_controller.setup(config.grid)
	state.terrain_map = state.map_controller.get_terrain_map()

	state.turn_controller.setup(state, config)
	state.camera_controller.setup(state, config)
	state.task_controller.setup(state)

	state.grid_query_service = GridQueryService.new()
	state.grid_query_service.setup(state.unit_manager, state.loot_manager, state.terrain_map, state.task_manager, config.grid)
	if state.unit_manager:
		state.unit_manager.grid_query_service = state.grid_query_service
		state.unit_manager.terrain_map = state.terrain_map

	_setup_dialogue_logic(state, config)
	_register_task_dialogue_signals(state)
	state.task_manager.setup(state)
	if is_instance_valid(state.journal_manager):
		state.journal_manager.setup(state.task_manager)
		if config.level:
			state.journal_manager.set_level(config.level)

	state.move_controller.setup(
		state,
		config
	)
	var style_set: AnimationStyleSet = config.animation_style_set
	if style_set == null:
		if ResourceLoader.exists(DEFAULT_ANIMATION_STYLE_SET_PATH):
			style_set = load(DEFAULT_ANIMATION_STYLE_SET_PATH)

	if state.animation_service:
		state.animation_service.setup(state, config)
	state.ai_controller.setup(
		state,
		config
	)
	state.location_service = LocationService.new()
	state.location_service.setup(state.unit_manager)

func _setup_input_and_hud(state: GameState, config: Config, services: Dictionary) -> void:
	var hud_components := _setup_hud(state, config)
	_setup_command_infrastructure(state, config, services)

	state.input_controller.setup(state, config)

	GameLogger.debug(GameLogger.Category.UI, "GameSessionBuilder: input controller wired; HUD and systems initialized")
	state.hud.setup(state, config)
	if state.animation_service and state.hud.has_method("set_animation_service"):
		state.hud.set_animation_service(state.animation_service)
	hud_components.setup(state, config)

	if state.input_controller and state.hud:
		state.input_controller.command_executed.connect(state.hud.on_command_executed)

	if config.input_handler:
		config.input_handler.auto_battle_toggle_requested.connect(func():
			var next_state := not state.turn_controller.is_player_auto_battle_enabled()
			state.turn_controller.set_player_auto_battle_enabled(next_state)
		)

	if config.camera_handler and state.hud_controller:
		config.camera_handler.camera_rotated.connect(state.hud_controller.update_compass)
		state.hud_controller.update_compass(config.camera_handler.get_camera_rotation())

func _setup_hud(state: GameState, config: Config) -> HUDComponentFactory.Components:
	if state.hud == null:
		state.hud = Hud.new()

	var aim_cursor: AimCursor = AimCursor.new()
	aim_cursor.name = "AimCursor"
	state.hud.add_child(aim_cursor)
	if config.input_handler:
		aim_cursor.connect_input_handler(config.input_handler)

	var is_portrait := false
	if DisplaySettings:
		is_portrait = DisplaySettings.get_current_orientation() == DisplayOrientation.Orientation.PORTRAIT

	var hud_components := HUDComponentFactory.create_components(state.hud, is_portrait)
	state.hud_controller.setup(state, hud_components, config)
	return hud_components

func _setup_command_infrastructure(state: GameState, _config: Config, services: Dictionary) -> void:
	if state.binding_service == null:
		state.binding_service = InputBindingService.new()
	if state.command_context == null:
		state.command_context = GameCommandContext.new(services)

	if state.command_router == null:
		state.command_router = InputCommandRouter.new(state.command_context)

	if state.ai_controller != null:
		state.ai_controller.set_command_context(state.command_context)
		if state.ai_controller.has_method("set_router"):
			state.ai_controller.set_router(state.command_router)

func _setup_dialogue_logic(state: GameState, config: Config) -> void:
	if state.dialogue_action_service == null:
		state.dialogue_action_service = DialogueActionService.new()
	state.dialogue_action_service.setup(
		state,
		config
	)
	if state.command_context != null:
		state.command_context.dialogue_action_service = state.dialogue_action_service
	PlayerActionManager.set_dialogue_service(state.dialogue_action_service)

	if state.dialogue_action_service and is_instance_valid(state.journal_manager):
		state.dialogue_action_service.journal_entry_unlocked.connect(state.journal_manager.unlock_coupled_entry)

func _register_observers(state: GameState, config: Config) -> void:
	_register_ui_signals(state)
	_register_turn_and_task_signals(state)
	_register_combat_and_world_signals(state, config)
	_register_visual_signals(state, config)

func _register_ui_signals(state: GameState) -> void:
	if not state.hud or not state.hud_controller:
		return

	state.move_controller.actions_updated.connect(state.hud_controller.handle_actions_updated)
	state.hud.action_refresh_requested.connect(state.move_controller.force_action_menu_update)
	state.move_controller.threat_warning_requested.connect(state.hud.show_warning_message)

	state.hud_controller.auto_battle_toggle_requested.connect(state.turn_controller.set_player_auto_battle_enabled)
	state.turn_controller.player_auto_battle_changed.connect(state.hud_controller.set_auto_battle_state)
	state.turn_controller.player_auto_battle_changed.connect(func(enabled: bool):
		if state.command_context:
			state.command_context.auto_battle_active = enabled
	)

	state.hud_controller.set_auto_battle_state(state.turn_controller.is_player_auto_battle_enabled())
	if state.command_context:
		state.command_context.auto_battle_active = state.turn_controller.is_player_auto_battle_enabled()

func _register_task_dialogue_signals(state: GameState) -> void:
	if state.dialogue_action_service:
		state.dialogue_action_service.dialogue_finished.connect(state.hud_controller.handle_dialogue_finished)
		state.dialogue_action_service.dialogue_finished.connect(state.task_controller.handle_dialogue_finished)
		state.task_controller.dialogue_requested.connect(state.dialogue_action_service.handle_dialogue_request)

		# Suppress grid movement overlay during dialogue; restore after
		if state.grid_visuals:
			state.dialogue_action_service.dialogue_started.connect(func(_flag):
				state.grid_visuals.set_suppress_updates(true)
			)
			state.dialogue_action_service.dialogue_finished.connect(func(_flag):
				state.grid_visuals.set_suppress_updates(false)
				# Recalculate and redraw the range overlay for the current unit
				var selected_idx := state.unit_manager.get_selected_index()
				var unit := state.unit_manager.get_unit(selected_idx)
				var reachable := ReachableState.create_empty()
				if is_instance_valid(unit):
					reachable = MovementRangeService.calculate_reachable_state(unit, state.terrain_map, state.unit_manager)
				var grid := state.map_controller.get_grid()
				if grid:
					state.grid_visuals.update_range_indicator(grid, reachable)
					state.grid_visuals.update_loyalty_indicators(state.unit_manager, state.terrain_map, grid)
			)

func _register_turn_and_task_signals(state: GameState) -> void:
	if state.turn_controller:
		state.turn_controller.configure_dependencies(state.checkpoint_manager, state.hud, state.terrain_map)
		if not state.turn_controller.turn_changed.is_connected(state.turn_controller.on_turn_changed):
			state.turn_controller.turn_changed.connect(state.turn_controller.on_turn_changed)
		if state.turn_controller.has_signal("round_changed"):
			if not state.turn_controller.round_changed.is_connected(state.task_controller.on_round_changed):
				state.turn_controller.round_changed.connect(state.task_controller.on_round_changed)

func _register_combat_and_world_signals(state: GameState, config: Config) -> void:
	if state.combat_system and state.task_controller:
		state.combat_system.unit_defeated.connect(state.task_controller.on_unit_defeated)

	if state.loot_manager and state.map_controller:
		state.loot_manager.loot_added.connect(state.map_controller.on_loot_added)

	if state.unit_manager and state.unit_controller:
		state.unit_controller.configure_dependencies(state, config)

	if state.checkpoint_manager and state.input_controller:
		state.input_controller.checkpoint_requested.connect(state.checkpoint_manager.on_checkpoint_requested)
		state.input_controller.undo_requested.connect(state.checkpoint_manager.on_undo_requested)
		state.input_controller.redo_requested.connect(state.checkpoint_manager.on_redo_requested)

func _register_visual_signals(state: GameState, config: Config) -> void:
	if not state.unit_manager:
		return

	if state.animation_service:
		state.unit_manager.unit_moved.connect(state.animation_service.on_unit_moved)
	else:
		state.unit_manager.unit_moved.connect(func(index: int, coord: Vector2i):
			var unit: Unit = state.unit_manager.get_unit(index)
			if unit and config.grid:
				unit.position = config.grid.map_to_local(coord)
		)

	if state.camera_controller:
		state.unit_manager.unit_moved.connect(state.camera_controller.on_unit_moved)
		state.unit_manager.selection_changed.connect(func(_idx): state.camera_controller.center_on_selected())

	if state.grid_visuals and state.map_controller:
		var update_visuals: Callable = func(_index: int = -1, _coord: Vector2i = Vector2i.ZERO):
			var selected_idx = state.unit_manager.get_selected_index()
			var unit = state.unit_manager.get_unit(selected_idx)
			var reachable = ReachableState.create_empty()
			if is_instance_valid(unit):
				reachable = MovementRangeService.calculate_reachable_state(unit, state.terrain_map, state.unit_manager)

			state.grid_visuals.update_range_indicator(
				state.map_controller.get_grid(),
				reachable
			)
			state.grid_visuals.update_enemy_range_overlay(
				state.map_controller.get_grid(),
				state.map_controller.get_threat_map()
			)

		# Ensure threat map is updated initially
		state.map_controller.update_threat_map(state.unit_manager, state.terrain_map)

		state.unit_manager.selection_changed.connect(func(idx): update_visuals.call(idx))
		state.unit_manager.unit_moved.connect(func(idx, _c):
			state.map_controller.update_threat_map(state.unit_manager, state.terrain_map)
			if idx == state.unit_manager.get_selected_index():
				update_visuals.call(idx, _c)
		)
		state.unit_manager.unit_removed.connect(func(_u):
			state.map_controller.update_threat_map(state.unit_manager, state.terrain_map)
			update_visuals.call()
		)
		if state.turn_controller:
			state.turn_controller.turn_started.connect(func(_side):
				state.map_controller.update_threat_map(state.unit_manager, state.terrain_map)
				update_visuals.call()
			)

func _create_game_state(services: Dictionary, config: Config) -> GameState:
	services[GameConstants.ContextKeys.GRID] = config.grid
	services[GameConstants.ContextKeys.CAMERA_2D] = config.camera
	services[GameConstants.ContextKeys.PLAYER_ROSTER] = config.player_roster

	var tree_nodes: Array[Node] = [
		services.get(GameConstants.ContextKeys.HUD),
		services.get(GameConstants.ContextKeys.GRID_VISUALS),
		services.get(GameConstants.ContextKeys.HUD_CONTROLLER),
		services.get(GameConstants.ContextKeys.MOVE_CONTROLLER),
		services.get(GameConstants.ContextKeys.ANIMATION_SERVICE),
		services.get(GameConstants.ContextKeys.LOOT_MANAGER),
		services.get(GameConstants.ContextKeys.AI_CONTROLLER),
		services.get(GameConstants.ContextKeys.COMBAT_SYSTEM),
		services.get(GameConstants.ContextKeys.UNIT_CONTROLLER),
		services.get(GameConstants.ContextKeys.UNIT_MANAGER),
		services.get(GameConstants.ContextKeys.TASK_MANAGER),
		services.get(GameConstants.ContextKeys.INPUT_CONTROLLER),
		services.get(GameConstants.ContextKeys.CAMERA_CONTROLLER),
		services.get(GameConstants.ContextKeys.TASK_CONTROLLER),
		services.get(GameConstants.ContextKeys.TURN_CONTROLLER),
		services.get(GameConstants.ContextKeys.MAP_CONTROLLER),
	]

	return GameState.new(services, tree_nodes)

func load_player_roster(provided_roster: PlayerRoster, save_manager: Node) -> PlayerRoster:
	return _get_roster_loader().load_player_roster(provided_roster, save_manager, DEFAULT_PLAYER_ROSTER_PATH)

func load_enemy_roster(provided_roster: EnemyRoster) -> EnemyRoster:
	return _get_roster_loader().load_enemy_roster(provided_roster, DEFAULT_ENEMY_ROSTER_PATH)

func load_neutral_roster(provided_roster: NeutralRoster) -> NeutralRoster:
	return _get_roster_loader().load_neutral_roster(provided_roster, DEFAULT_NEUTRAL_ROSTER_PATH)

func _get_roster_loader() -> RosterLoader:
	if _roster_loader == null:
		_roster_loader = RosterLoader.new()
	return _roster_loader

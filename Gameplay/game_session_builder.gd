class_name GameSessionBuilder
extends RefCounted

const DEFAULT_ANIMATION_STYLE_SET_PATH := FilePaths.Resources.DEFAULT_ANIMATION_STYLE_SET

const DEFAULT_PLAYER_ROSTER_PATH: String = RosterLoader.DEFAULT_PLAYER_ROSTER_PATH
const DEFAULT_ENEMY_ROSTER_PATH: String = RosterLoader.DEFAULT_ENEMY_ROSTER_PATH
const DEFAULT_NEUTRAL_ROSTER_PATH: String = RosterLoader.DEFAULT_NEUTRAL_ROSTER_PATH

const _REQUIRED_SERVICE_FIELDS := [
	"unit_controller",
	"unit_manager",
	"task_manager",
	"loot_manager",
	"hex_navigator",
	"grid_visuals",
	"hud_controller",
	"input_controller",
	"move_controller",
	"animation_service",
	"camera_controller",
	"task_controller",
	"map_controller",
	"ai_controller",
	"combat_system",
	"checkpoint_manager"
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
	_setup_input_and_hud(game_state, config)
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
		services["save_manager"] = config.save_manager

	if not services.has("unit_manager") and services.has("unit_controller") and services["unit_controller"] != null:
		services["unit_manager"] = services["unit_controller"].get_unit_manager()
	services["level_resource"] = config.level

	_validate_required_services(services)

	if not services.has("hud") or services["hud"] == null:
		services["hud"] = Hud.new()

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
	state.location_service.setup(state.task_manager)

func _setup_input_and_hud(state: GameState, config: Config) -> void:
	var hud_components := _setup_hud(state, config)
	_setup_command_infrastructure(state, config)

	state.input_controller.setup(state, config)

	print_debug("GameSessionBuilder: input controller wired; HUD and systems initialized")
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

func _setup_command_infrastructure(state: GameState, config: Config) -> void:
	if state.binding_service == null:
		state.binding_service = InputBindingService.new()
	if state.command_context == null:
		state.command_context = GameCommandContext.new(
			state.unit_manager,
			state.hex_navigator,
			state.camera_controller,
			state.move_controller,
			state.turn_controller,
			state.task_controller,
			config.grid,
			state.grid_visuals,
			state.terrain_map,
			state.binding_service,
			state.dialogue_action_service
		)

	if state.command_router == null:
		state.command_router = InputCommandRouter.new(state.command_context)

	if state.ai_controller != null:
		state.ai_controller.set_command_context(state.command_context)

func _setup_dialogue_logic(state: GameState, config: Config) -> void:
	if state.dialogue_action_service == null:
		state.dialogue_action_service = DialogueActionService.new()
	state.dialogue_action_service.setup(
		state,
		config
	)
	if state.command_context != null:
		state.command_context.dialogue_action_service = state.dialogue_action_service
	UnitActionManager.set_dialogue_service(state.dialogue_action_service)

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
	state.turn_controller.player_auto_battle_failed.connect(state.hud.show_warning_message)

	state.hud_controller.set_auto_battle_state(state.turn_controller.is_player_auto_battle_enabled())

func _register_task_dialogue_signals(state: GameState) -> void:
	if state.dialogue_action_service:
		state.dialogue_action_service.dialogue_finished.connect(state.hud_controller.handle_dialogue_finished)
		state.dialogue_action_service.dialogue_finished.connect(state.task_controller._on_dialogue_finished)
		state.task_controller.dialogue_requested.connect(state.dialogue_action_service.handle_dialogue_request)

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
			state.grid_visuals.update_range_indicator(
				state.map_controller.get_grid(),
				state.unit_manager,
				state.map_controller.get_terrain_map()
			)
		state.unit_manager.selection_changed.connect(func(idx): update_visuals.call(idx))
		state.unit_manager.unit_moved.connect(func(idx, _c):
			if idx == state.unit_manager.get_selected_index():
				update_visuals.call(idx, _c)
		)

func _create_game_state(services: Dictionary, config: Config) -> GameState:
	services["grid"] = config.grid
	services["camera_2d"] = config.camera
	services["player_roster"] = config.player_roster

	var tree_nodes: Array[Node] = [
		services.get("hud"),
		services.get("grid_visuals"),
		services.get("hud_controller"),
		services.get("move_controller"),
		services.get("animation_service"),
		services.get("loot_manager"),
		services.get("ai_controller"),
		services.get("combat_system"),
		services.get("unit_controller"),
		services.get("unit_manager"),
		services.get("task_manager"),
		services.get("input_controller"),
		services.get("camera_controller"),
		services.get("task_controller"),
		services.get("turn_controller"),
		services.get("map_controller"),
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

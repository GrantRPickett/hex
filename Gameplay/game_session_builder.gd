class_name GameSessionBuilder
extends RefCounted

const InputMapperScript := preload("res://Autoloads/input_mapper.gd")
const DefaultGameSessionServiceFactoryScript := preload("res://Gameplay/default_game_session_service_factory.gd")
const RosterLoaderScript := preload("res://Gameplay/roster_loader.gd")
const HUDComponentFactoryScript := preload("res://Gameplay/hud_component_factory.gd")
const DEFAULT_ANIMATION_STYLE_SET_PATH := "res://Resources/animation_styles/default_animation_styles.tres"

const DEFAULT_PLAYER_ROSTER_PATH: String = RosterLoaderScript.DEFAULT_PLAYER_ROSTER_PATH
const DEFAULT_ENEMY_ROSTER_PATH: String = RosterLoaderScript.DEFAULT_ENEMY_ROSTER_PATH
const DEFAULT_NEUTRAL_ROSTER_PATH: String = RosterLoaderScript.DEFAULT_NEUTRAL_ROSTER_PATH

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
	"grid_controller",
	"camera_controller",
	"task_controller",
	"turn_controller",
	"map_controller",
	"ai_controller",
	"combat_system",
	"checkpoint_manager"
]

class Config extends RefCounted:
	var grid: Node2D
	var camera: Camera2D
	var camera_handler: CameraHandler
	var input_handler: InputHandler
	var pause_handler: PauseHandler
	var controls: Node
	var input_mapper: Node
	var services_factory: GameSessionServiceFactory
	var animation_style_set: AnimationStyleSet
	var level_resource: Resource

var _roster_loader: RosterLoader

func set_roster_loader(loader: RosterLoader) -> void:
	_roster_loader = loader

func build(config: Config) -> GameState:
	assert(config != null, "GameSessionBuilder requires a config object.")
	assert(config.grid != null, "GameSessionBuilder requires a grid reference.")

	var services := _prepare_services(config)
	_setup_core_systems(services, config)
	_setup_input_and_hud(services, config)
	_register_observers(services, config)
	var game_state = _create_game_state(services)
	if services.checkpoint_manager and services.checkpoint_manager.has_method("setup"):
		services.checkpoint_manager.setup(game_state)
	return game_state

func _prepare_services(config: Config) -> GameSessionServices:
	var factory: GameSessionServiceFactory = config.services_factory
	if factory == null:
		factory = DefaultGameSessionServiceFactoryScript.new()

	var services := factory.create_services()
	assert(services != null, "Service factory must return a GameSessionServices instance.")
	if services.unit_manager == null and services.unit_controller != null:
		services.unit_manager = services.unit_controller.get_unit_manager()

	_validate_required_services(services)
	return services

func _validate_required_services(services: GameSessionServices) -> void:
	for field in _REQUIRED_SERVICE_FIELDS:
		var dependency = services.get(field)
		assert(dependency != null, "GameSessionServices missing required dependency '%s'." % field)

func _setup_core_systems(services: GameSessionServices, config: Config) -> void:
	services.grid_controller.setup(config.grid)
	services.map_controller.setup(config.grid)
	services.terrain_map = services.map_controller.get_terrain_map()
	services.turn_controller.setup(services, config)
	services.camera_controller.setup(services, config)

	# Set the level resource on services for task controller to access
	services.level_resource = config.level_resource

	services.task_controller.setup(services, config)
	services.move_controller.setup(
		services,
		config
	)
	var style_set = config.animation_style_set
	if style_set == null:
		if ResourceLoader.exists(DEFAULT_ANIMATION_STYLE_SET_PATH):
			style_set = load(DEFAULT_ANIMATION_STYLE_SET_PATH)

	if services.animation_service:
		services.animation_service.setup(services, config)
	services.ai_controller.setup(
		services,
		config
	)

func _setup_input_and_hud(services: GameSessionServices, config: Config) -> void:
	if services.hud == null:
		services.hud = Hud.new()

	var aim_cursor = AimCursor.new()
	services.hud.add_child(aim_cursor)
	if config.input_handler:
		aim_cursor.connect_input_handler(config.input_handler)

	var turn_system := services.turn_controller.get_turn_system()
	var hud_components := HUDComponentFactoryScript.create_components(services.hud)
	var hud_controller_config := HUDController.Config.new()
	hud_controller_config.components = hud_components
	hud_controller_config.turn_system = turn_system

	hud_controller_config.unit_manager = services.unit_manager
	hud_controller_config.task_manager = services.task_manager
	hud_controller_config.loot_manager = services.loot_manager
	hud_controller_config.combat_system = services.combat_system
	hud_controller_config.grid = config.grid
	hud_controller_config.hud = services.hud
	hud_controller_config.terrain_map = services.terrain_map
	hud_controller_config.grid_visuals = services.grid_visuals
	hud_controller_config.aim_cursor = aim_cursor
	hud_controller_config.location_service = services.location_service
	hud_controller_config.task_controller = services.task_controller
	hud_controller_config.pause_handler = config.pause_handler
	hud_controller_config.animation_service = services.animation_service
	services.location_service.setup(config.level_resource)
	services.hud_controller.setup(hud_controller_config)
	if services.binding_service == null:
		services.binding_service = InputBindingService.new()
	if services.command_context == null:
		services.command_context = GameCommandContext.new(
			services.unit_manager,
			services.hex_navigator,
			services.camera_controller,
			services.move_controller,
			services.turn_controller,
			services.task_controller,
			config.grid,
			services.grid_visuals,
			services.terrain_map,
			services.binding_service,
			services.dialogue_action_service
		)

	if services.command_router == null:
		services.command_router = InputCommandRouter.new(services.command_context)

	if services.ai_controller != null:
		services.ai_controller.set_command_context(services.command_context)

	# Instantiate and wire controllers
	services.input_controller.setup(
		services,
		config,
		{} # Passing the empty dictionary for command_set
	)

	print_debug("GameSessionBuilder: input controller wired; HUD and systems initialized")
	services.hud.setup(services, config)
	if services.animation_service and services.hud.has_method("set_animation_service"):
		services.hud.set_animation_service(services.animation_service)
	hud_components.setup(services, config)
	if services.dialogue_action_service == null:
		services.dialogue_action_service = DialogueActionService.new()
	services.dialogue_action_service.setup(
		services,
		config
	)
	if services.command_context != null:
		services.command_context.dialogue_action_service = services.dialogue_action_service
	UnitActionManager.set_dialogue_service(services.dialogue_action_service)

	# Connect Coupled Journal Updates
	if services.dialogue_action_service and is_instance_valid(JournalManager):
		services.dialogue_action_service.journal_entry_unlocked.connect(JournalManager.unlock_coupled_entry)

	if services.input_controller and services.hud:
		services.input_controller.command_executed.connect(services.hud.on_command_executed)

	if config.input_handler:
		config.input_handler.auto_battle_toggle_requested.connect(func():
			var next_state := not services.turn_controller.is_player_auto_battle_enabled()
			services.turn_controller.set_player_auto_battle_enabled(next_state)
		)

	if config.camera_handler and services.hud_controller:
		config.camera_handler.camera_rotated.connect(services.hud_controller.update_compass)
		services.hud_controller.update_compass(config.camera_handler.get_camera_rotation())

func _register_observers(services: GameSessionServices, config: Config) -> void:
	services.move_controller.actions_updated.connect(services.hud_controller.handle_actions_updated)
	services.hud.action_refresh_requested.connect(services.move_controller.force_action_menu_update)
	services.move_controller.threat_warning_requested.connect(services.hud.show_warning_message)
	services.dialogue_action_service.dialogue_finished.connect(services.hud_controller.handle_dialogue_finished)
	services.dialogue_action_service.dialogue_finished.connect(services.task_controller._on_dialogue_finished)

	services.hud_controller.auto_battle_toggle_requested.connect(services.turn_controller.set_player_auto_battle_enabled)
	services.turn_controller.player_auto_battle_changed.connect(services.hud_controller.set_auto_battle_state)
	services.turn_controller.player_auto_battle_failed.connect(services.hud.show_warning_message)

	# Set initial state
	services.hud_controller.set_auto_battle_state(services.turn_controller.is_player_auto_battle_enabled())

	# Checkpoint/Undo/Redo
	if services.checkpoint_manager and services.input_controller:
		services.input_controller.checkpoint_requested.connect(services.checkpoint_manager.on_checkpoint_requested)
		services.input_controller.undo_requested.connect(services.checkpoint_manager.on_undo_requested)
		services.input_controller.redo_requested.connect(services.checkpoint_manager.on_redo_requested)

	# Turn Logic
	if services.turn_controller:
		services.turn_controller.configure_dependencies(services.checkpoint_manager, services.hud, services.terrain_map)
		services.turn_controller.turn_changed.connect(services.turn_controller.on_turn_changed)
		if services.turn_controller.has_signal("round_changed"):
			services.turn_controller.round_changed.connect(services.task_controller.on_round_changed)

	# Combat System
	if services.combat_system and services.task_controller:
		services.combat_system.unit_defeated.connect(services.task_controller.on_unit_defeated)

	# Grid/Loot
	if services.loot_manager and services.grid_controller:
		services.loot_manager.loot_added.connect(services.grid_controller.on_loot_added)

	# Unit Spawn
	if services.unit_manager and services.unit_controller:
		services.unit_controller.configure_dependencies(services, config)


	# Visuals (Camera, Animation, Grid)
	if services.unit_manager:
		if services.animation_service:
			services.unit_manager.unit_moved.connect(services.animation_service.on_unit_moved)
		else:
			# Fallback: Immediate position update if no animation service
			services.unit_manager.unit_moved.connect(func(index: int, coord: Vector2i):
				var unit = services.unit_manager.get_unit(index)
				if unit and config.grid:
					unit.position = config.grid.map_to_local(coord)
			)

		if services.camera_controller:
			services.unit_manager.unit_moved.connect(services.camera_controller.on_unit_moved)
			services.unit_manager.selection_changed.connect(func(_idx): services.camera_controller.center_on_selected())

		if services.grid_visuals and services.map_controller and services.grid_controller:
			var update_visuals = func(index: int = -1, _coord: Vector2i = Vector2i.ZERO):
				# Only update range if selected unit moved or selection changed
				services.grid_visuals.update_range_indicator(
					services.grid_controller.get_grid(),
					services.unit_manager,
					services.map_controller.get_terrain_map()
				)

			services.unit_manager.selection_changed.connect(func(idx): update_visuals.call(idx))
			services.unit_manager.unit_moved.connect(func(idx, c):
				if idx == services.unit_manager.get_selected_index():
					update_visuals.call(idx, c)
			)

func _create_game_state(services: GameSessionServices) -> GameState:
	var tree_nodes: Array[Node] = [
		services.hud,
		services.grid_visuals,
		services.hud_controller,
		services.move_controller,
		services.animation_service,
		services.loot_manager,
		services.ai_controller,
		services.combat_system,
		services.unit_controller,
		services.unit_manager,
		services.task_manager, # Changed from task_manager
		services.input_controller,
		services.grid_controller,
		services.camera_controller,
		services.task_controller,
		services.turn_controller,
		services.map_controller,
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
		_roster_loader = RosterLoaderScript.new()
	return _roster_loader



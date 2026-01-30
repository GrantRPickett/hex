class_name GameSessionBuilder
extends RefCounted

const InputMapperScript := preload("res://Autoloads/input_mapper.gd")
const DefaultGameSessionServiceFactoryScript := preload("res://Gameplay/default_game_session_service_factory.gd")
const RosterLoaderScript := preload("res://Gameplay/roster_loader.gd")
const HUDComponentFactoryScript := preload("res://Gameplay/hud_component_factory.gd")

const DEFAULT_PLAYER_ROSTER_PATH := RosterLoaderScript.DEFAULT_PLAYER_ROSTER_PATH
const DEFAULT_ENEMY_ROSTER_PATH := RosterLoaderScript.DEFAULT_ENEMY_ROSTER_PATH
const DEFAULT_NEUTRAL_ROSTER_PATH := RosterLoaderScript.DEFAULT_NEUTRAL_ROSTER_PATH

const _REQUIRED_SERVICE_FIELDS := [
	"unit_controller",
	"unit_manager",
	"goal_manager",
	"loot_manager",
	"hex_navigator",
	"grid_visuals",
	"hud_controller",
	"input_controller",
	"move_controller",
	"grid_controller",
	"camera_controller",
	"goal_controller",
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
	var controls: Node
	var input_mapper: Node
	var services_factory: GameSessionServiceFactory

var _roster_loader: RosterLoader

func set_roster_loader(loader: RosterLoader) -> void:
	_roster_loader = loader

func build(config: Config) -> GameState:
	assert(config != null, "GameSessionBuilder requires a config object.")
	assert(config.grid != null, "GameSessionBuilder requires a grid reference.")

	var services := _prepare_services(config)
	_setup_core_systems(services, config)
	_setup_input_and_hud(services, config)
	_register_observers(services)
	return _create_game_state(services)

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
	services.turn_controller.setup(services.unit_manager, services.ai_controller)
	services.camera_controller.setup(config.camera, config.camera_handler, services.unit_manager)
	services.goal_controller.setup(services.goal_manager, services.unit_manager)
	services.move_controller.setup(
		services.unit_manager,
		services.unit_controller,
		services.hex_navigator,
		services.turn_controller,
		services.goal_controller,
		services.map_controller,
		config.grid
	)
	services.ai_controller.setup(
		services.unit_manager,
		services.map_controller,
		services.combat_system,
		services.unit_controller,
		services.goal_manager,
		services.loot_manager
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
	hud_controller_config.goal_manager = services.goal_manager
	hud_controller_config.loot_manager = services.loot_manager
	hud_controller_config.combat_system = services.combat_system
	hud_controller_config.grid = config.grid
	hud_controller_config.hud = services.hud
	hud_controller_config.terrain_map = services.terrain_map
	hud_controller_config.grid_visuals = services.grid_visuals
	hud_controller_config.aim_cursor = aim_cursor
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
			services.goal_controller,
			config.grid,
			services.grid_visuals,
			services.terrain_map,
			services.binding_service
		)
	if services.command_router == null:
		services.command_router = InputCommandRouter.new(services.command_context)

	# Instantiate and wire controllers
	services.input_controller.setup(
		config.input_handler,
		services.unit_manager,
		services.hex_navigator,
		services.camera_controller,
		services.move_controller,
		services.turn_controller,
		services.goal_controller,
		config.grid,
		config.controls,
		config.input_mapper if config.input_mapper != null else InputMapperScript.new(),
		services.binding_service,
		services.command_context,
		services.command_router,
		services.grid_visuals,
		services.terrain_map
	)

	print_debug("GameSessionBuilder: input controller wired; HUD and systems initialized")
	services.hud.setup(services.unit_manager, services.turn_controller, services.input_controller, services.goal_manager)
	hud_components.setup(services.unit_manager, services.turn_controller, services.input_controller, services.goal_manager)
	if is_instance_valid(services.input_controller) and is_instance_valid(services.hud):
		services.input_controller.command_executed.connect(services.hud.on_command_executed)

func _register_observers(services: GameSessionServices) -> void:
	services.move_controller.actions_updated.connect(services.hud_controller.handle_actions_updated)
	services.hud.action_refresh_requested.connect(services.move_controller.force_action_menu_update)
	services.move_controller.threat_warning_requested.connect(services.hud.show_warning_message)

func _create_game_state(services: GameSessionServices) -> GameState:
	var tree_nodes: Array[Node] = [
		services.hud,
		services.grid_visuals,
		services.hud_controller,
		services.move_controller,
		services.loot_manager,
		services.ai_controller,
		services.combat_system,
		services.unit_controller,
		services.unit_manager,
		services.goal_manager,
		services.input_controller,
		services.grid_controller,
		services.camera_controller,
		services.goal_controller,
		services.turn_controller,
		services.map_controller,
	]
	return GameState.new(
		services.unit_controller,
		services.goal_manager,
		services.loot_manager,
		services.hex_navigator,
		services.hud,
		services.grid_visuals,
		services.hud_controller,
		services.input_controller,
		services.move_controller,
		services.grid_controller,
		services.camera_controller,
		services.goal_controller,
		services.turn_controller,
		services.map_controller,
		services.ai_controller,
		services.combat_system,
		services.checkpoint_manager,
		tree_nodes
	)

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

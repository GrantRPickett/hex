extends GdUnitTestSuite

const DefaultGameSessionServiceFactoryScript := preload("res://Gameplay/default_game_session_service_factory.gd")
const GameSessionServiceFactoryScript := preload("res://Gameplay/game_session_service_factory.gd")
const RosterLoaderScript := preload("res://Gameplay/roster_loader.gd")

var _grid: TileMapLayer
var _camera: Camera2D
var _camera_handler: CameraHandler
var _input_handler: InputHandler

func before() -> void:
	_grid = auto_free(TileMapLayer.new())
	_camera = auto_free(Camera2D.new())
	_camera_handler = auto_free(CameraHandler.new())
	_input_handler = auto_free(InputHandler.new())

func test_builder_returns_context_with_dependencies() -> void:
	var builder := GameSessionBuilder.new()
	var config := _create_builder_config()

	var state := builder.build(config)
	assert_object(state).is_not_null()
	assert_object(state.unit_manager).is_not_null()
	assert_object(state.grid_controller).is_not_null()
	assert_object(state.goal_controller).is_not_null()

	var nodes := state.get_tree_nodes()
	assert_int(nodes.size()).is_greater_equal(8)
	assert_bool(nodes.has(state.hud)).is_true()
	assert_bool(nodes.has(state.grid_visuals)).is_true()
	assert_bool(nodes.has(state.hud_controller)).is_true()
	assert_bool(nodes.has(state.move_controller)).is_true()
	assert_bool(nodes.has(state.animation_service)).is_true()
	assert_bool(nodes.has(state.loot_manager)).is_true()
	assert_bool(nodes.has(state.ai_controller)).is_true()
	assert_bool(nodes.has(state.combat_system)).is_true()

func test_builder_uses_custom_service_factory() -> void:
	var builder := GameSessionBuilder.new()
	var config := _create_builder_config()
	var factory := TestServiceFactory.new()
	config.services_factory = factory

	var state := builder.build(config)
	assert_bool(factory.create_called).is_true()
	assert_object(state.move_controller).is_equal(factory.custom_move_controller)
	assert_object(state.animation_service).is_equal(factory.custom_animation_service)

func test_builder_uses_assigned_roster_loader() -> void:
	var builder := GameSessionBuilder.new()
	var loader := TestRosterLoader.new()
	builder.set_roster_loader(loader)

	var enemy_roster := builder.load_enemy_roster(null)
	assert_bool(loader.enemy_called).is_true()
	assert_object(enemy_roster).is_equal(loader.enemy_response)

func _create_builder_config() -> GameSessionBuilder.Config:
	var config := GameSessionBuilder.Config.new()
	config.grid = _grid
	config.camera = _camera
	config.camera_handler = _camera_handler
	config.input_handler = _input_handler
	config.controls = null
	config.input_mapper = null
	return config

class TestServiceFactory extends GameSessionServiceFactoryScript:
	var create_called := false
	var custom_move_controller := MoveController.new()
	var custom_animation_service := AnimationRequestService.new()
	var _delegate := DefaultGameSessionServiceFactoryScript.new()

	func create_services() -> GameSessionServices:
		create_called = true
		var services := _delegate.create_services()
		services.move_controller = custom_move_controller
		services.animation_service = custom_animation_service
		return services

class TestRosterLoader extends RosterLoaderScript:
	var enemy_called := false
	var enemy_response := EnemyRoster.new()

	func load_player_roster(provided_roster: PlayerRoster, save_manager: Node, fallback_path: String = DEFAULT_PLAYER_ROSTER_PATH) -> PlayerRoster:
		return provided_roster if provided_roster else PlayerRoster.new()

	func load_enemy_roster(provided_roster: EnemyRoster, fallback_path: String = DEFAULT_ENEMY_ROSTER_PATH) -> EnemyRoster:
		enemy_called = true
		return enemy_response

	func load_neutral_roster(provided_roster: NeutralRoster, fallback_path: String = DEFAULT_NEUTRAL_ROSTER_PATH) -> NeutralRoster:
		return NeutralRoster.new()

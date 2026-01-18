extends GdUnitTestSuite


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
	var config := GameSessionBuilder.Config.new()
	config.grid = _grid
	config.camera = _camera
	config.camera_handler = _camera_handler
	config.input_handler = _input_handler
	config.controls = null
	config.input_mapper = null

	var state := builder.build(config)
	assert_object(state).is_not_null()
	assert_object(state.unit_manager).is_not_null()
	assert_object(state.grid_controller).is_not_null()
	assert_object(state.goal_controller).is_not_null()

	var nodes := state.get_tree_nodes()
	assert_int(nodes.size()).is_equal(7)
	assert_bool(nodes.has(state.hud)).is_true()
	assert_bool(nodes.has(state.grid_visuals)).is_true()
	assert_bool(nodes.has(state.hud_controller)).is_true()
	assert_bool(nodes.has(state.move_controller)).is_true()
	assert_bool(nodes.has(state.loot_manager)).is_true()
	assert_bool(nodes.has(state.ai_controller)).is_true()
	assert_bool(nodes.has(state.combat_system)).is_true()

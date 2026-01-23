extends GdUnitTestSuite

var _input_binding_service: InputBindingService
var _mock_mapper: Node

class MockInputMapper extends Node:
	func apply_configs(_configs, _defaults) -> void:
		pass

func before() -> void:
	_input_binding_service = auto_free(InputBindingService.new())
	_mock_mapper = auto_free(MockInputMapper.new())

func test_apply_bindings_with_null_mapper() -> void:
	# Should handle null gracefully and return early
	_input_binding_service.apply_bindings(null, null)

	# No crash expected, just early return
	assert_object(_input_binding_service).is_not_null()

func test_apply_bindings_with_mapper() -> void:
	# Create mock controls node
	var controls := Node.new()
	controls.set("move_actions", ["up", "down"])
	controls.set("interaction_actions", ["interact"])
	controls.set("camera_actions", ["pan"])
	controls.set("selection_actions", ["select"])
	controls.set("pause_actions", ["pause"])

	_input_binding_service.apply_bindings(controls, _mock_mapper)

	# Should not crash
	assert_object(_input_binding_service).is_not_null()

func test_apply_bindings_with_empty_settings() -> void:
	var controls := Node.new()
	_input_binding_service.apply_bindings(controls, _mock_mapper)

	assert_object(_input_binding_service).is_not_null()

func test_apply_bindings_with_null_settings() -> void:
	_input_binding_service.apply_bindings(null, _mock_mapper)

	assert_object(_input_binding_service).is_not_null()

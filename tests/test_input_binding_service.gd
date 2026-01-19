extends GdUnitTestSuite

var _input_binding_service: InputBindingService
var _mock_mapper: RefCounted

class MockInputMapper extends RefCounted:
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
	# Create mock settings
	var settings = {
		"move_actions": ["up", "down"],
		"interaction_actions": ["interact"],
		"camera_actions": ["pan"],
		"selection_actions": ["select"],
		"pause_actions": ["pause"]
	}

	_input_binding_service.apply_bindings(settings, _mock_mapper)

	# Should not crash
	assert_object(_input_binding_service).is_not_null()

func test_apply_bindings_with_empty_settings() -> void:
	_input_binding_service.apply_bindings({}, _mock_mapper)

	assert_object(_input_binding_service).is_not_null()

func test_apply_bindings_with_null_settings() -> void:
	_input_binding_service.apply_bindings(null, _mock_mapper)

	assert_object(_input_binding_service).is_not_null()

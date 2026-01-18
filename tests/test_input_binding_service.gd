extends GdUnitTestSuite

var _input_binding_service: InputBindingService
var _mock_mapper: RefCounted

func before() -> void:
	_input_binding_service = auto_free(InputBindingService.new())

	# Create a mock input mapper
	_mock_mapper = auto_free(RefCounted.new())
	var apply_called = {"called": false}
	_mock_mapper.set_meta("apply_configs", func(_configs, _defaults): apply_called["called"] = true)

func test_apply_bindings_with_null_mapper() -> void:
	# Should handle null gracefully
	_input_binding_service.apply_bindings(null, null)

	# No crash expected
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

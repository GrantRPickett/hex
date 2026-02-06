extends GdUnitTestSuite

const InputActions := preload("res://Resources/input_actions.gd")

var _input_binding_service: InputBindingService
var _mock_mapper: Node

class MockInputMapper extends Node:
	func apply_configs(_configs, _defaults) -> void:
		pass

func before() -> void:
	_input_binding_service = auto_free(InputBindingService.new())
	_mock_mapper = auto_free(MockInputMapper.new())

func after() -> void:
	_clear_registered_actions()

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

func test_dialogue_action_mirrors_primary_bindings() -> void:
	_clear_registered_actions()
	_input_binding_service.apply_bindings(null, _mock_mapper)

	var primary_signatures := _collect_event_signatures(InputActions.PRIMARY_ACTION)
	var dialogic_signatures := _collect_event_signatures(InputActions.DIALOGIC_DEFAULT_ACTION)

	assert_array(primary_signatures).is_not_empty()
	assert_array(dialogic_signatures).is_equal(primary_signatures)

func _collect_event_signatures(action: String) -> Array:
	var signatures: Array[String] = []
	if not InputMap.has_action(action):
		return signatures
	for event in InputMap.action_get_events(action):
		signatures.append(_event_signature(event))
	return signatures

func _event_signature(event: InputEvent) -> String:
	if event is InputEventKey:
		var keycode = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
		return "key:%s" % keycode
	elif event is InputEventMouseButton:
		return "mouse:%s" % event.button_index
	elif event is InputEventJoypadButton:
		return "joybtn:%s" % event.button_index
	elif event is InputEventJoypadMotion:
		return "joyaxis:%s:%s" % [event.axis, event.axis_value]
	return event.get_class()

func _clear_registered_actions() -> void:
	var groups = [
		InputActions.MOVEMENT_DEFAULTS,
		InputActions.INTERACTION_DEFAULTS,
		InputActions.CAMERA_DEFAULTS,
		InputActions.SELECTION_DEFAULTS,
		InputActions.PAUSE_DEFAULTS,
		InputActions.VISUAL_DEFAULTS,
	]
	for group in groups:
		for entry in group:
			var action: String = entry["action"]
			if InputMap.has_action(action):
				InputMap.erase_action(action)
	if InputMap.has_action(InputActions.DIALOGIC_DEFAULT_ACTION):
		InputMap.erase_action(InputActions.DIALOGIC_DEFAULT_ACTION)

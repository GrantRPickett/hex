extends GdUnitTestSuite

class InteractUnit extends Unit:
	var interacted_target: Target = null

	func interact(target: Target) -> bool:
		interacted_target = target
		return true

class TentativeUnit extends Unit:
	var tentative := false

	func has_tentative_move() -> bool:
		return tentative

class FakeInputController extends InputController:
	var last_command: String = ""
	var last_payload
	var commands: Array[String] = []
	var tentative_unit: TentativeUnit = null

	func _execute_command(command_name: String, payload = null) -> CommandResult:
		last_command = command_name
		last_payload = payload
		commands.append(command_name)
		if command_name == "confirm_move" and tentative_unit:
			tentative_unit.tentative = false
		return CommandResult.new() # Return a default CommandResult

var _info: Hud
var _unit: InteractUnit
var _target: Target

func before() -> void:
	_info = auto_free(Hud.new())
	get_tree().root.add_child(_info)
	_unit = InteractUnit.new()
	_unit._ready()
	_target = Target.new()

	# Mock the unit for the info panel
	_info._current_unit = _unit

func after() -> void:
	if is_instance_valid(_info):
		_info.queue_free()
	if is_instance_valid(_unit):
		_unit.queue_free()
	if is_instance_valid(_target):
		_target.queue_free()

func test_execute_action_directly_with_target() -> void:
	_info._current_unit = _unit
	_unit.interacted_target = null
	monitor_signals(_info)

	var action = {
		"type": "interact_test",
		"target": _target
	}
	_info._execute_action(action)
	assert_object(_unit.interacted_target).is_equal(_target)
	assert_signal(_info).is_emitted("action_executed", ["interact_test"])

func test_execute_action_directly_wait() -> void:
	monitor_signals(_info)

	var action = {
		"type": "wait"
	}

	_info._execute_action_directly(action)

	assert_signal(_info).is_emitted("action_executed", ["wait"])

func test_action_button_press_routes_through_input_controller() -> void:
	var fake_controller := FakeInputController.new()
	_info._input_controller = fake_controller
	_info._current_unit_index = 0
	_info._turn_controller = null
	_info._unit_manager = null

	var enemy := Target.new()
	var action = {
		"type": "attack",
		"target": enemy
	}

	_info._on_action_button_pressed(action)

	assert_str(fake_controller.last_command).is_equal("interact")
	assert_object(fake_controller.last_payload).is_equal(enemy)

func test_show_warning_message_creates_overlay() -> void:
	await get_tree().process_frame
	_info.show_warning_message("Danger")
	await get_tree().process_frame
	var overlay = _info.get_node_or_null("WarningOverlay")
	assert_object(overlay).is_not_null()
	assert_int(overlay.get_child_count()).is_greater(0)


func test_action_button_wait_confirms_tentative_move() -> void:
	var fake_controller := FakeInputController.new()
	var unit := TentativeUnit.new()
	unit.tentative = true
	fake_controller.tentative_unit = unit
	_info._input_controller = fake_controller
	_info._current_unit = unit
	_info._current_unit_index = 0

	var action = {
		"type": "wait"
	}

	await _info._on_action_button_pressed(action)
	await get_tree().process_frame
	assert_array(fake_controller.commands).is_equal(["confirm_move", "wait"])

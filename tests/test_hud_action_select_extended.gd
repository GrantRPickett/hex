extends GdUnitTestSuite

# Test `on_action_selected` in `hud.gd`

const HUDScript = preload("res://GUI/hud.gd")

class FakeUnitManager extends Node:
	var selected_unit = Unit.new()
	var selected_idx = 0
	func get_selected_unit() -> Unit: return selected_unit
	func get_selected_index() -> int: return selected_idx
	func get_unit_index(_u) -> int: return selected_idx

class FakeInputController extends Node:
	var last_cmd = ""
	func _execute_command(cmd_name: String, _args = {}) -> CommandResult:
		last_cmd = cmd_name
		return CommandResult.success()

func _add_and_free(node: Node) -> Node:
	add_child(node)
	return auto_free(node)

func test_hud_on_action_selected_dispatch() -> void:
	var h = HUDScript.new()
	_add_and_free(h)

	var sig_called = [false]
	h.action_executed.connect(func(_type): sig_called[0] = true)

	var um = auto_free(FakeUnitManager.new())
	var in_ctrl = auto_free(FakeInputController.new())

	h._unit_manager = um
	h._input_controller = in_ctrl

	# Try a basic wait command
	h.on_action_selected({"type": "wait"})
	await get_tree().process_frame

	assert_str(in_ctrl.last_cmd).is_equal("wait")
	assert_bool(sig_called[0]).is_true()

	# Try missing type
	in_ctrl.last_cmd = ""
	sig_called[0] = false
	h.on_action_selected({})
	await get_tree().process_frame

	assert_str(in_ctrl.last_cmd).is_empty()
	assert_bool(sig_called[0]).is_false()

	um.selected_unit.free()

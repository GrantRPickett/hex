extends GdUnitTestSuite

# Test `on_action_selected` in `hud.gd`

const HUDScript = preload("res://GUI/hud.gd")
const UnitAction := preload("res://Gameplay/turn/unit_action.gd")
const CommandResult := preload("res://Gameplay/commands/command_result.gd")

class FakeUnitManager extends Node:
	var selected_unit = Unit.new()
	var selected_idx = 0
	func get_selected_unit() -> Unit: return selected_unit
	func get_selected_index() -> int: return selected_idx
	func get_unit_index(_u) -> int: return selected_idx

class FakeInputController extends Node:
	var last_cmd: GameConstants.Commands.CommandID = GameConstants.Commands.CommandID.NONE
	func _execute_command(cmd_id: GameConstants.Commands.CommandID, _args = null) -> CommandResult:
		last_cmd = cmd_id
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
	h._action_executor = HudActionExecutor.new(h, um, in_ctrl)

	# Try a basic wait command
	var wait_action := UnitAction.new()
	wait_action.type = UnitAction.Type.WAIT
	h.on_action_selected(wait_action)
	await get_tree().process_frame

	assert_int(in_ctrl.last_cmd).is_equal(GameConstants.Commands.CommandID.WAIT)
	assert_bool(sig_called[0]).is_true()

	# Try missing type (default is UNKNOWN=0)
	in_ctrl.last_cmd = GameConstants.Commands.CommandID.NONE
	sig_called[0] = false
	var empty_action := UnitAction.new()
	h.on_action_selected(empty_action)
	await get_tree().process_frame

	# UNKNOWN action should not trigger any command in executor
	assert_int(in_ctrl.last_cmd).is_equal(GameConstants.Commands.CommandID.NONE)
	assert_bool(sig_called[0]).is_false()

	um.selected_unit.free()

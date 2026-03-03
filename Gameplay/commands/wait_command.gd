class_name WaitCommand
extends GameCommand

static func get_command_name() -> String:
	return "wait"

static func get_command_description() -> String:
	return "End turn for current unit"

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray(["task_controller", "move_controller", "unit_manager", "turn_controller"])

func execute(context: GameCommandContext, _payload = null) -> CommandResult:
	# Validate context
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	# Check preconditions
	if context.task_controller and context.task_controller.is_task_reached():
		return CommandResult.precondition_failed("location already reached")

	if context.move_controller.is_move_locked():
		return CommandResult.precondition_failed("Move is locked")

	var selected_idx = context.unit_manager.get_selected_index()
	var unit = context.unit_manager.get_unit(selected_idx)
	if unit == null:
		return CommandResult.precondition_failed("No unit selected")
	if not context.turn_controller.can_act_on_index(selected_idx):
		return CommandResult.precondition_failed("Cannot act on selected unit")

	if unit.movement.has_tentative_move() and context.move_controller:
		context.move_controller.cancel_move()
	unit.block_movement_this_turn()
	unit.block_action_this_turn()
	if context.move_controller and context.move_controller.has_method("force_action_menu_update"):
		context.move_controller.force_action_menu_update()

	context.turn_controller.complete_player_activation(selected_idx)
	return CommandResult.success()


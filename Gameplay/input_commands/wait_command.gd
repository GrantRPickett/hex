class_name WaitCommand
extends GameCommand

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray(["goal_controller", "move_controller", "unit_manager", "turn_controller"])

func execute(context: GameCommandContext, _payload = null) -> CommandResult:
	# Validate context
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	# Check preconditions
	if context.goal_controller.is_goal_reached():
		return CommandResult.precondition_failed("Goal already reached")

	if context.move_controller.is_move_locked():
		return CommandResult.precondition_failed("Move is locked")

	var selected_idx = context.unit_manager.get_selected_index()
	if not context.turn_controller.can_act_on_index(selected_idx):
		return CommandResult.precondition_failed("Cannot act on selected unit")

	context.turn_controller.complete_player_activation(selected_idx)
	return CommandResult.success()

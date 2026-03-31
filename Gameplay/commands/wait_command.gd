class_name WaitCommand
extends GameCommand

static func _get_command_id() -> GameConstants.Commands.CommandID:
	return GameConstants.Commands.CommandID.WAIT

static func create_payload() -> Dictionary:
	return {}

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([
		GameConstants.ContextKeys.TASK_CONTROLLER,
		GameConstants.ContextKeys.MOVE_CONTROLLER,
		GameConstants.ContextKeys.UNIT_MANAGER,
		GameConstants.ContextKeys.TURN_CONTROLLER
	])

func execute(context: GameCommandContext, _payload: Dictionary = {}) -> CommandResult:
	# Validate context
	var ctx_result: CommandResult = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	if context.move_controller.is_move_locked():
		return CommandResult.precondition_failed("Move is locked")

	var selected_idx: int = context.unit_manager.get_selected_index()
	var unit: Unit = context.unit_manager.get_unit(selected_idx)
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

	context.turn_controller.complete_turn()
	return CommandResult.success()

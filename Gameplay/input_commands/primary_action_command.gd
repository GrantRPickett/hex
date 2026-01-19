class_name PrimaryActionCommand
extends GameCommand

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray(["grid", "unit_manager", "move_controller", "turn_controller"])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	# Validate context
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	# Validate payload is a Vector2 screen position
	if payload == null or not payload is Vector2:
		return CommandResult.invalid_payload("Payload must be a Vector2 screen position")

	var grid = context.grid
	var unit_manager = context.unit_manager
	var move_controller = context.move_controller
	var turn_controller = context.turn_controller

	var cell: Vector2i = grid.local_to_map(grid.to_local(payload))

	var idx = unit_manager.index_of_unit_at(cell)
	if idx != -1:
		if unit_manager.is_player_controlled(idx) and turn_controller.can_act_on_index(idx):
			unit_manager.select_index(idx)
		return CommandResult.success()

	# Use pathfinding-based movement to allow clicking any reachable hex
	move_controller.request_move_to_coord(cell)
	return CommandResult.success()


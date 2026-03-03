class_name PrimaryActionCommand
extends GameCommand

static func get_command_name() -> String:
	return "primary_action"

static func get_command_description() -> String:
	return "Primary action at screen coordinates (click or tap)"

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray(["grid", "unit_manager", "move_controller", "turn_controller"])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	# Validate context
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		print_debug("DBG PrimaryActionCommand: Context validation failed: ", ctx_result.get_error_message())
		return ctx_result

	# Validate payload is a Vector2 screen position
	if payload == null or not payload is Vector2:
		print_debug("DBG PrimaryActionCommand: Invalid payload. Expected Vector2, got: ", payload)
		return CommandResult.invalid_payload("Payload must be a Vector2 screen position")

	var grid = context.grid
	var unit_manager = context.unit_manager
	var move_controller = context.move_controller
	var turn_controller = context.turn_controller

	var cell: Vector2i = grid.local_to_map(grid.to_local(payload))
	print_debug("DBG PrimaryActionCommand: payload_global=", payload, " converted_cell=", cell)

	var idx = unit_manager.index_of_unit_at(cell)
	if idx != -1:
		print_debug("DBG PrimaryActionCommand: Unit found at cell ", cell, " (index: ", idx, ")")
		if unit_manager.is_player_controlled(idx) and turn_controller.can_act_on_index(idx):
			print_debug("DBG PrimaryActionCommand: Selecting player unit at index ", idx)
			unit_manager.select_index(idx)
		else:
			print_debug("DBG PrimaryActionCommand: Unit at ", idx, " is not selectable (not player controlled or cannot act)")
		return CommandResult.success()

	# Use pathfinding-based movement to allow clicking any reachable hex
	print_debug("DBG PrimaryActionCommand: No unit at cell ", cell, ". Requesting move to coord.")
	move_controller.request_move_to_coord(cell)
	return CommandResult.success()

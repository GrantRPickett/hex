class_name PrimaryActionCommand
extends GameCommand

static func _get_command_id() -> GameConstants.Commands.CommandID:
	return GameConstants.Commands.CommandID.PRIMARY_ACTION

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([
		GameConstants.ContextKeys.GRID,
		GameConstants.ContextKeys.UNIT_MANAGER,
		GameConstants.ContextKeys.MOVE_CONTROLLER,
		GameConstants.ContextKeys.TURN_CONTROLLER,
		GameConstants.ContextKeys.TASK_MANAGER,
		GameConstants.ContextKeys.LOOT_MANAGER
	])

func execute(context: GameCommandContext, payload: Dictionary = {}) -> CommandResult:
	# Validate context
	var ctx_result: CommandResult = validate_context(context)
	if ctx_result.is_failure():
		GameLogger.debug(GameLogger.Category.COMBAT, "DBG PrimaryActionCommand: Context validation failed: ", ctx_result.get_error_message())
		return ctx_result

	# Validate payload is a Vector2 screen position
	if not payload.has("position"):
		GameLogger.debug(GameLogger.Category.COMBAT, "DBG PrimaryActionCommand: Missing position in payload: ", payload)
		return CommandResult.invalid_payload("Payload must have 'position' (Vector2)")
	
	var pos_val = payload.get("position")
	if not pos_val is Vector2:
		GameLogger.debug(GameLogger.Category.COMBAT, "DBG PrimaryActionCommand: Position is not Vector2: ", pos_val)
		return CommandResult.invalid_payload("Position must be a Vector2")

	var grid = context.grid
	var unit_manager = context.unit_manager
	var move_controller = context.move_controller
	var turn_controller = context.turn_controller
	var _task_manager = context.task_manager
	var _loot_manager = context.loot_manager

	var cell: Vector2i = grid.local_to_map(grid.to_local(pos_val))
	GameLogger.debug(GameLogger.Category.COMBAT, "DBG PrimaryActionCommand: pos_val=", pos_val, " converted_cell=", cell)

	var idx: int = unit_manager.index_of_unit_at(cell)
	if idx != GameConstants.INVALID_INDEX:
		GameLogger.debug(GameLogger.Category.COMBAT, "DBG PrimaryActionCommand: Unit found at cell ", cell, " (index: ", idx, ")")
		if unit_manager.is_player_controlled(idx) and turn_controller.can_act_on_index(idx):
			GameLogger.debug(GameLogger.Category.COMBAT, "DBG PrimaryActionCommand: Selecting player unit at index ", idx)
			unit_manager.select_index(idx)
		else:
			GameLogger.debug(GameLogger.Category.COMBAT, "DBG PrimaryActionCommand: Unit at ", idx, " is not selectable (not player controlled or cannot act)")
		return CommandResult.success()
	# Use pathfinding-based movement to allow clicking any reachable hex
	GameLogger.debug(GameLogger.Category.COMBAT, "DBG PrimaryActionCommand: No unit or target at cell ", cell, ". Requesting move to coord.")
	if move_controller.request_move_to_coord(cell):
		return CommandResult.success()
	else:
		return CommandResult.failed("Could not move to target cell")

func _resolve_interaction_type(target: Target) -> String:
	if target is Location:
		if target.exploration_state == Location.ExplorationState.EXPLORABLE:
			return GameConstants.Interactions.EXPLORE
		return GameConstants.Interactions.VISIT
	elif target is Loot:
		var loot: Loot = target as Loot
		if loot.is_trapped:
			return GameConstants.Interactions.TRAPPED
		return GameConstants.Interactions.LOOT
	return ""

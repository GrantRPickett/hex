class_name PrimaryActionCommand
extends GameCommand

static func _get_command_id() -> GameConstants.ActionType:
	return GameConstants.ActionType.PRIMARY_ACTION

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([
		GameConstants.ContextKeys.GRID,
		GameConstants.ContextKeys.UNIT_MANAGER,
		GameConstants.ContextKeys.MOVE_CONTROLLER,
		GameConstants.ContextKeys.TURN_CONTROLLER,
		GameConstants.ContextKeys.TASK_MANAGER,
		GameConstants.ContextKeys.LOOT_MANAGER,
		GameConstants.ContextKeys.LOCATION_SERVICE
	])

func execute(context: GameCommandContext, payload: Dictionary = {}) -> CommandResult:
	var ctx_result: CommandResult = validate_context(context)
	if ctx_result.is_failure():
		GameLogger.debug(GameLogger.Category.COMBAT, "DBG PrimaryActionCommand: Context validation failed: ", ctx_result.get_error_message())
		return ctx_result

	var cell: Vector2i = _extract_cell_from_payload(context, payload)
	if cell.x == -1 and cell.y == -1:
		return CommandResult.invalid_payload("Position must be a valid Vector2")

	# Check for unit selection at cell
	if _try_select_unit(context, cell):
		return CommandResult.success()

	# Movement fallback - path to empty cell
	var move_controller = context.move_controller
	GameLogger.debug(GameLogger.Category.COMBAT, "DBG PrimaryActionCommand: Moving to cell ", cell)
	if move_controller.request_move_to_coord(cell):
		return CommandResult.success()

	return CommandResult.failed("Could not move to target cell")


func _extract_cell_from_payload(context: GameCommandContext, payload: Dictionary) -> Vector2i:
	if not payload.has(GameConstants.Payload.POSITION):
		GameLogger.debug(GameLogger.Category.COMBAT, "DBG PrimaryActionCommand: Missing position in payload: ", payload)
		return Vector2i(-1, -1)

	var pos_val = payload.get(GameConstants.Payload.POSITION)
	if not pos_val is Vector2:
		GameLogger.debug(GameLogger.Category.COMBAT, "DBG PrimaryActionCommand: Position is not Vector2: ", pos_val)
		return Vector2i(-1, -1)

	var grid = context.grid
	var cell: Vector2i = grid.local_to_map(grid.to_local(pos_val))
	GameLogger.debug(GameLogger.Category.COMBAT, "DBG PrimaryActionCommand: pos_val=", pos_val, " converted_cell=", cell)
	return cell


func _try_select_unit(context: GameCommandContext, cell: Vector2i) -> bool:
	var unit_manager = context.unit_manager
	var turn_controller = context.turn_controller

	var idx: int = unit_manager.index_of_unit_at(cell)
	if idx == GameConstants.INVALID_INDEX:
		return false

	# Only select if it's a player-controlled unit we can act on
	if unit_manager.is_player_controlled(idx) and turn_controller.can_act_on_index(idx):
		unit_manager.select_index(idx)
		return true

	return false

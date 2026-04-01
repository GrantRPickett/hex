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
		GameConstants.ContextKeys.LOOT_MANAGER
	])

func execute(context: GameCommandContext, payload: Dictionary = {}) -> CommandResult:
	# Validate context
	var ctx_result: CommandResult = validate_context(context)
	if ctx_result.is_failure():
		GameLogger.debug(GameLogger.Category.COMBAT, "DBG PrimaryActionCommand: Context validation failed: ", ctx_result.get_error_message())
		return ctx_result

	# Validate payload is a Vector2 screen position
	if not payload.has(GameConstants.Payload.POSITION):
		GameLogger.debug(GameLogger.Category.COMBAT, "DBG PrimaryActionCommand: Missing position in payload: ", payload)
		return CommandResult.invalid_payload("Payload must have 'position' (Vector2)")
	
	var pos_val = payload.get(GameConstants.Payload.POSITION)
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

	# 1. Check for Selection / Unit interaction
	var idx: int = unit_manager.index_of_unit_at(cell)
	if idx != GameConstants.INVALID_INDEX:
		if unit_manager.is_player_controlled(idx) and turn_controller.can_act_on_index(idx):
			unit_manager.select_index(idx)
			return CommandResult.success()
		
		var active_unit: Unit = context.get_selected_unit()
		if is_instance_valid(active_unit) and turn_controller.can_act_on_index(active_unit.get_instance_id()):
			var target_unit: Unit = unit_manager.get_unit(idx)
			if active_unit.interaction.interact(target_unit):
				return CommandResult.success()

	# 2. Check for Loot/Location interaction
	var active_unit: Unit = context.get_selected_unit()
	if is_instance_valid(active_unit) and turn_controller.can_act_on_index(active_unit.get_instance_id()):
		var loot_node = _loot_manager.get_loot_at(cell)
		if is_instance_valid(loot_node):
			if active_unit.interaction.interact(loot_node):
				return CommandResult.success()
		
		var loc_node = _task_manager.get_location_at(cell)
		if is_instance_valid(loc_node):
			if active_unit.interaction.interact(loc_node):
				return CommandResult.success()

	# 3. Pathfinding-based movement fallback
	GameLogger.debug(GameLogger.Category.COMBAT, "DBG PrimaryActionCommand: No unit or target at cell ", cell, ". Requesting move to coord.")
	if move_controller.request_move_to_coord(cell):
		return CommandResult.success()
	
	return CommandResult.failed("Could not move to target cell")

func _resolve_interaction_type(_target: Target) -> String:
	return ""

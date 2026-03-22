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

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	# Validate context
	var ctx_result: CommandResult = validate_context(context)
	if ctx_result.is_failure():
		GameLogger.debug(GameLogger.Category.COMBAT, "DBG PrimaryActionCommand: Context validation failed: ", ctx_result.get_error_message())
		return ctx_result

	# Validate payload is a Vector2 screen position
	if payload == null or not payload is Vector2:
		GameLogger.debug(GameLogger.Category.COMBAT, "DBG PrimaryActionCommand: Invalid payload. Expected Vector2, got: ", payload)
		return CommandResult.invalid_payload("Payload must be a Vector2 screen position")

	var grid = context.grid
	var unit_manager = context.unit_manager
	var move_controller = context.move_controller
	var turn_controller = context.turn_controller
	var task_manager = context.task_manager
	var loot_manager = context.loot_manager

	var cell: Vector2i = grid.local_to_map(grid.to_local(payload))
	GameLogger.debug(GameLogger.Category.COMBAT, "DBG PrimaryActionCommand: payload_global=", payload, " converted_cell=", cell)

	var idx: int = unit_manager.index_of_unit_at(cell)
	if idx != GameConstants.INVALID_INDEX:
		GameLogger.debug(GameLogger.Category.COMBAT, "DBG PrimaryActionCommand: Unit found at cell ", cell, " (index: ", idx, ")")
		if unit_manager.is_player_controlled(idx) and turn_controller.can_act_on_index(idx):
			GameLogger.debug(GameLogger.Category.COMBAT, "DBG PrimaryActionCommand: Selecting player unit at index ", idx)
			unit_manager.select_index(idx)
		else:
			GameLogger.debug(GameLogger.Category.COMBAT, "DBG PrimaryActionCommand: Unit at ", idx, " is not selectable (not player controlled or cannot act)")
		return CommandResult.success()
#Disabled for now until submenu selection redesigned
	# # Check for interaction targets (Locations, Loot)
	# var interaction_target: Target = null

	# # Check TaskManager for locations
	# if task_manager:
	# 	var loc = task_manager.get_location_at(cell)
	# 	if loc:
	# 		interaction_target = loc
	# 		var active_unit: Unit = unit_manager.get_selected_unit()
	# 		var faction = active_unit.get_effective_faction() if active_unit else GameConstants.INVALID_INDEX
	# 		var tasks = task_manager.get_active_tasks_for_target(loc, faction)
	# 		if not tasks.is_empty():
	# 			GameLogger.debug(GameLogger.Category.COMBAT, "DBG PrimaryActionCommand: Found active tasks for faction %d at %s" % [faction, loc.name])

	# # Check LootManager if no location found
	# if not interaction_target and loot_manager:
	# 	var loot = loot_manager.get_loot_at(cell)
	# 	if loot:
	# 		interaction_target = loot

	# if interaction_target:
	# 	var active_unit: Unit = unit_manager.get_selected_unit()
	# 	var selected_idx: int = unit_manager.get_selected_index()
	# 	var current_cell: Vector2i = unit_manager.get_coord(selected_idx) if selected_idx != GameConstants.INVALID_INDEX else GameConstants.INVALID_COORD

	# 	if active_unit and current_cell == cell:
	# 		var type = _resolve_interaction_type(interaction_target)
	# 		GameLogger.debug(GameLogger.Category.COMBAT, "PrimaryActionCommand: Already at %s. Interacting with type '%s'." % [interaction_target.name, type])
	# 		interaction_target.interact(active_unit, {"type": type})
	# 		return CommandResult.success()

	# 	GameLogger.debug(GameLogger.Category.COMBAT, "PrimaryActionCommand: Found interaction target %s at cell %s. Requesting move." % [interaction_target.name, cell])
	# 	if move_controller.request_move_to_coord(cell):
	# 		return CommandResult.success()
	# 	else:
	# 		return CommandResult.failed("Could not move to target at %s" % cell)

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

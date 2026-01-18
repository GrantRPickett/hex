class_name PrimaryActionCommand
extends GameCommand

# GameCommand class is auto-global in Godot 4

func execute(context: GameCommandContext, payload = null) -> void:
	if context == null or not context.is_valid():
		if context and context.get_missing_dependencies().size() > 0:
			push_error("PrimaryActionCommand: Missing dependencies: ", context.get_missing_dependencies())
		return

	var grid = context.grid
	var unit_manager = context.unit_manager
	var move_controller = context.move_controller
	var turn_controller = context.turn_controller

	print_debug("DBG PrimaryActionCommand.execute payload=", payload)
	var cell: Vector2i = grid.local_to_map(grid.to_local(payload))
	print_debug("DBG PrimaryActionCommand.execute cell=", cell)
	var idx  = unit_manager.index_of_unit_at(cell)
	if idx != -1:
		print_debug("DBG PrimaryActionCommand: found unit at ", cell)
		if unit_manager.is_player_controlled(idx) and turn_controller.can_act_on_index(idx):
			unit_manager.select_index(idx)
		return

	# Use pathfinding-based movement to allow clicking any reachable hex
	print_debug("DBG PrimaryActionCommand: calling request_move_to_coord with cell=", cell)
	move_controller.request_move_to_coord(cell)


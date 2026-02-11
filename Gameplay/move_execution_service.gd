class_name MoveExecutionService
extends RefCounted

func execute_move(unit_controller, location_controller, unit, selected_idx: int, destination: Vector2i, cost: int) -> void:
	if unit_controller:
		unit_controller.set_coord(selected_idx, destination)
	if location_controller:
		location_controller.check_location_progress()
	if unit:
		unit.consume_move(cost)
		if unit.movement_behavior:
			unit.movement_behavior.set_start_of_turn_grid_coord(destination)

func finalize_tentative_move(unit_controller, location_controller, unit: Unit, selected_idx: int, terrain_map) -> void:
	if unit == null:
		return

	var path = unit.get_tentative_path()
	var final_destination = unit.get_tentative_grid_coord()
	var total_cost = unit.get_tentative_cost()

	if unit.movement_behavior and not path.is_empty():
		var result = unit.movement_behavior.process_path_for_opportunity_attacks(path, terrain_map)
		final_destination = result.destination
		total_cost = result.cost

		if unit.willpower <= 0:
			# Unit was defeated mid-move. The death handler should take care of the unit's state.
			# We just need to clear the tentative move and stop here.
			unit.clear_tentative_move()
			return

	if unit_controller:
		unit_controller.set_coord(selected_idx, final_destination)
	unit.consume_move(total_cost)
	if unit.movement_behavior:
		unit.movement_behavior.set_start_of_turn_grid_coord(final_destination)
	unit.clear_tentative_move()
	if location_controller:
		location_controller.check_location_progress()

func evaluate_post_move(unit, terrain_map, unit_manager, selected_idx: int, action_manager = UnitActionManager) -> Dictionary:
	var result := {
		"emit_actions": false,
		"complete_turn": false,
		"log_message": ""
	}
	if not unit:
		result.complete_turn = true
		return result

	var available_actions: Array = action_manager.get_available_actions(unit, terrain_map, unit_manager)
	var can_perform_action: bool = unit.has_action_available() and not available_actions.is_empty()
	result.emit_actions = can_perform_action

	var coord_text: String = str(unit_manager.get_coord(0)) if unit_manager and unit_manager.has_method("get_coord") else "Vector2i()"
	if not unit.has_move_available():
		if not can_perform_action:
			result.complete_turn = true
			result.log_message = "DBG POST_MOVE player_coord=%s - turn ended (no movement, no actions)" % coord_text
		else:
			result.log_message = "DBG POST_MOVE player_coord=%s - actions available, waiting for action" % coord_text
	else:
		result.log_message = "DBG POST_MOVE player_coord=%s" % coord_text
	return result

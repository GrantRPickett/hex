class_name GoalHoverState
extends "hover_state.gd"

func can_enter(controller: Node, cell: Vector2i) -> bool:
	if not controller._components or not is_instance_valid(controller._components.goal_details):
		return false
	if not is_instance_valid(controller._goal_manager):
		return false
	return controller._goal_manager.get_goal_at_cell(cell) != null

func update(controller: Node, cell: Vector2i) -> void:
	var goal_index = controller._goal_manager.get_goal_index_at(cell)
	if goal_index == -1:
		controller.goal_details_updated.emit(null)
		return
	var payload = controller._goal_manager.get_goal_info(goal_index)
	controller.goal_details_updated.emit(payload)

func exit(controller: Node) -> void:
	controller.goal_details_updated.emit(null)

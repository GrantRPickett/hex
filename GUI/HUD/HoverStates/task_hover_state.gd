class_name TaskHoverState
extends "hover_state.gd"

# Placeholder for Task-specific hover logic

func can_enter(controller: Node, cell: Vector2i) -> bool:
	if not controller._components or not is_instance_valid(controller._components.task_details):
		return false
	if not is_instance_valid(controller._task_controller):
		return false
	return not controller._task_controller.get_task_at_coord(cell).is_empty()

func update(controller: Node, cell: Vector2i) -> void:
	if controller._task_controller:
		var task_data = controller._task_controller.get_task_at_coord(cell)
		controller.task_details_updated.emit(task_data)
	else:
		controller.task_details_updated.emit(null)

func exit(controller: Node) -> void:
	controller.task_details_updated.emit(null)

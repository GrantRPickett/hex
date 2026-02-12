class_name locationHoverState
extends "hover_state.gd"

func can_enter(controller: Node, cell: Vector2i) -> bool:
	if not controller._components or not is_instance_valid(controller._components.location_details):
		return false
	if not is_instance_valid(controller._location_manager):
		return false
	return controller._location_manager.get_location_at_cell(cell) != null

func update(controller: Node, cell: Vector2i) -> void:
	var location_index = controller._location_manager.get_location_index_at(cell)
	if location_index == -1:
		controller.location_details_updated.emit(null)
		return
	var payload = controller._location_manager.get_location_info(location_index)
	controller.location_details_updated.emit(payload)

func exit(controller: Node) -> void:
	controller.location_details_updated.emit(null)

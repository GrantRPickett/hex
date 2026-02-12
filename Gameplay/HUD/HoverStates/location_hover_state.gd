class_name LocationHoverState
extends "hover_state.gd"

func can_enter(controller: Node, cell: Vector2i) -> bool:
	if not controller._components or not is_instance_valid(controller._components.location_details):
		return false
	if not is_instance_valid(controller._location_service):
		return false
	return not controller._location_service.get_location_data_at_coordinate(cell).is_empty()

func update(controller: Node, cell: Vector2i) -> void:
	if controller._location_service:
		var location_data = controller._location_service.get_location_data_at_coordinate(cell)
		controller.location_details_updated.emit(location_data)
	else:
		controller.location_details_updated.emit(null)

func exit(controller: Node) -> void:
	controller.location_details_updated.emit(null)

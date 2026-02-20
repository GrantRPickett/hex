class_name UnitHoverState
extends "hover_state.gd"

func can_enter(controller: Node, cell: Vector2i) -> bool:
	if not controller._components or not is_instance_valid(controller._components.unit_details):
		return false
	var idx = controller._unit_manager.index_of_unit_at(cell)
	if idx == -1: return false
	return controller._unit_manager.get_unit(idx) is Unit

func update(controller: Node, cell: Vector2i) -> void:
	var hovered_unit_idx = controller._unit_manager.index_of_unit_at(cell)
	if hovered_unit_idx != -1:
		var hovered_unit = controller._unit_manager.get_unit(hovered_unit_idx)
		if hovered_unit is Unit:
			controller.unit_details_updated.emit(hovered_unit, controller._terrain_map, controller._unit_manager)

func exit(controller: Node) -> void:
	controller.unit_details_updated.emit(null, null, null)

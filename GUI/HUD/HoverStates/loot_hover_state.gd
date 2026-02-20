class_name LootHoverState
extends "hover_state.gd"

func can_enter(controller: Node, cell: Vector2i) -> bool:
	if not controller._components or not is_instance_valid(controller._components.loot_details):
		return false
	if not is_instance_valid(controller._loot_manager):
		return false
	return controller._loot_manager.has_loot_at(cell)

func update(controller: Node, cell: Vector2i) -> void:
	var hovered_loot = controller._loot_manager.get_loot_at(cell)
	controller.loot_details_updated.emit(hovered_loot)

func exit(controller: Node) -> void:
	controller.loot_details_updated.emit(null)

class_name TerrainHoverState
extends "hover_state.gd"

func can_enter(controller: Node, cell: Vector2i) -> bool:
	if not controller._components or not is_instance_valid(controller._components.terrain_details):
		return false
	if not controller._terrain_map:
		return false
	var terrain = controller._terrain_map.get_terrain(cell)
	return terrain and not (terrain is TerrainTile.NullTerrain)

func update(controller: Node, cell: Vector2i) -> void:
	var terrain = controller._terrain_map.get_terrain(cell)
	var dist_str = controller.calculate_distance_to_cell(cell)
	controller.terrain_details_updated.emit(terrain, dist_str)

func exit(controller: Node) -> void:
	controller.terrain_details_updated.emit(null, "")

class_name CenterFallbackEvaluator
extends AIActionEvaluator

func evaluate(unit: Unit, context: AIContext) -> Array[AIAction]:
	if context.unit_manager == null or context.terrain_map == null:
		return []

	var width: int = context.terrain_map.grid_width
	var height: int = context.terrain_map.grid_height
	if width <= 0 or height <= 0:
		return []

	var center := Vector2i(max(1, int(round(width * GameConstants.AI.RATIO_MOVE_TO_TARGET))), max(1, int(round(height * GameConstants.AI.RATIO_MOVE_TO_TARGET))))
	var axis := TileSet.TILE_OFFSET_AXIS_VERTICAL
	if context.terrain_map.has_method("get_offset_axis"):
		axis = context.terrain_map.get_offset_axis() as TileSet.TileOffsetAxis

	var threatened_hexes: Dictionary = {}
	if unit.movement:
		threatened_hexes = unit.movement.get_threatened_hexes(
			context.unit_manager, context.terrain_map
		)

	# Sort all tiles by distance to center; take the first reachable, unoccupied one
	var candidates: Array[Vector2i] = []
	for x in range(0, width):
		for y in range(0, height):
			candidates.append(Vector2i(x, y))
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da := HexLib.get_distance(center, a, axis)
		var db := HexLib.get_distance(center, b, axis)
		if da == db:
			return a.x < b.x if a.x != b.x else a.y < b.y
		return da < db
	)

	var unit_index := context.unit_manager.get_unit_index(unit)

	for coord in candidates:
		if context.unit_manager.is_occupied(coord):
			continue
		var path := unit.movement.get_path_to_coord(coord, context.terrain_map)
		if path.is_empty():
			continue
		var is_threatened := threatened_hexes.has(coord)
		var score: float = GameConstants.AI.SCORE_MOVE_TO_CENTER - path.size() - (GameConstants.AI.THREAT_PENALTY if is_threatened else 0)

		var action := AIAction.new(GameConstants.ActionType.MOVE_TO_CENTER, score)
		action.command_id = GameConstants.Commands.CommandID.MOVE_TO_COORD
		action.command_payload = MoveToCoordCommand.create_payload(unit_index, coord)
		action.path = path
		action.move_cost = path.size()
		return [action]

	return []

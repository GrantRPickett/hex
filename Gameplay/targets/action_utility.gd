class_name ActionUtility
extends RefCounted

## Builds the target_move_data dictionary for an action.
## reachable_targets: Array of Target objects (Unit, Location, Loot)
## reachable_lookup: Dictionary of coord -> { "cost": int, ... }
static func build_move_data(reachable_targets: Array, reachable_lookup: Dictionary) -> Dictionary:
	var move_data : Dictionary = {}
	for target in reachable_targets:
		if not target or not target.has_method("get_grid_location"):
			continue
		var coord: Vector2i = target.get_grid_location()
		if reachable_lookup.has(coord):
			move_data[target] = _clone_move_info(reachable_lookup[coord], target)
	return move_data

## Standard way to add reachable targets and their move data to an action.
static func set_reachable_info(action: PlayerAction, reachable_targets: Array, reachable_lookup: Dictionary) -> void:
	action.reachable_targets = reachable_targets
	action.target_move_data = {}
	if reachable_lookup.is_empty() or reachable_targets.is_empty():
		return

	if _is_coord_keyed_lookup(reachable_lookup):
		action.target_move_data = build_move_data(reachable_targets, reachable_lookup)
		return

	var move_data := {}
	for target in reachable_targets:
		if not target or not reachable_lookup.has(target):
			continue
		move_data[target] = _clone_move_info(reachable_lookup[target], target)
	action.target_move_data = move_data

static func _is_coord_keyed_lookup(lookup: Dictionary) -> bool:
	if lookup.is_empty():
		return false
	var first_key = lookup.keys()[0]
	return first_key is Vector2i

static func _clone_move_info(raw_data, target) -> Dictionary:
	var coord: Vector2i = GameConstants.INVALID_COORD
	if target and target.has_method("get_grid_location"):
		coord = target.get_grid_location()

	var cost := 0
	if raw_data is Dictionary:
		coord = raw_data.get("coord", coord)
		cost = int(raw_data.get("cost", raw_data.get("move_cost", 0)))
	elif raw_data is Vector2i:
		coord = raw_data
	elif raw_data is int or raw_data is float:
		cost = int(raw_data)
	return {"coord": coord, "cost": cost}

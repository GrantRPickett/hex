class_name ActionUtility
extends RefCounted

## Builds the target_move_data dictionary for an action.
## reachable_targets: Array of Target objects (Unit, Location, Loot)
## reachable_lookup: Dictionary of coord -> { "cost": int, ... }
static func build_move_data(reachable_targets: Array, reachable_lookup: Dictionary) -> Dictionary:
	var move_data := {}
	for target in reachable_targets:
		if not target.has_method("get_grid_location"):
			continue
		var coord: Vector2i = target.get_grid_location()
		if reachable_lookup.has(coord):
			var data = reachable_lookup[coord]
			if data is Dictionary:
				move_data[target] = {
					"coord": coord,
					"cost": data.get("cost", 0)
				}
			elif data is int or data is float:
				move_data[target] = {
					"coord": coord,
					"cost": int(data)
				}
	return move_data

## Standard way to add reachable targets and their move data to an action.
static func set_reachable_info(action: UnitAction, reachable_targets: Array, reachable_lookup: Dictionary) -> void:
	action.reachable_targets = reachable_targets
	action.target_move_data = build_move_data(reachable_targets, reachable_lookup)

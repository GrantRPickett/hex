class_name UnitDiscovery
extends RefCounted

## Generic unit discovery functions.
## These return units based on faction relationship to a source unit.

## Returns all units categorized by relationship to the source unit.
static func get_all_units(unit: Node) -> Dictionary:
	if not is_instance_valid(unit) or not ("query" in unit):
		return {"enemies": [], "allies": [], "neutrals": []}

	var query = unit.get("query")
	if not is_instance_valid(query):
		return {"enemies": [], "allies": [], "neutrals": []}

	var enemies = query.get_hostile_units()
	var allies = query.get_friendly_units()
	var neutrals = query.get_neutral_units()
	return {"enemies": enemies, "allies": allies, "neutrals": neutrals}

## Returns adjacent units categorized by relationship.
static func get_adjacent_units(unit: Node) -> Dictionary:
	if not is_instance_valid(unit) or not ("query" in unit):
		return {"enemies": [], "allies": [], "neutrals": []}

	var query = unit.get("query")
	if not is_instance_valid(query):
		return {"enemies": [], "allies": [], "neutrals": []}

	var hostiles = query.get_hostile_units()
	var adjacent_hostiles = query.get_adjacent_units(hostiles)

	var friendlies = query.get_friendly_units()
	var adjacent_friendlies = query.get_adjacent_units(friendlies)

	var neutral_units = query.get_neutral_units()
	var adjacent_neutrals = query.get_adjacent_units(neutral_units)

	return {
		"enemies": adjacent_hostiles,
		"allies": adjacent_friendlies,
		"neutrals": adjacent_neutrals
	}

## Returns units from the manager that match the specified relationship to the source unit.
static func get_relationship_units(unit: Node, unit_manager: Node, type: String) -> Array:
	if not is_instance_valid(unit) or not is_instance_valid(unit_manager):
		return []

	# type can be "hostile", "friendly", "neutral"
	var player_units = unit_manager.get_player_units() if unit_manager.has_method("get_player_units") else []
	var enemy_units = unit_manager.get_enemy_units() if unit_manager.has_method("get_enemy_units") else []
	var neutral_units = unit_manager.get_neutral_units() if unit_manager.has_method("get_neutral_units") else []
	var result: Array = []

	var my_faction = unit.get("faction") if "faction" in unit else -1
	var my_loyalty = -1
	if "loyalty" in unit and is_instance_valid(unit.get("loyalty")):
		my_loyalty = unit.get("loyalty").get("neutral_loyalty")

	match type:
		"hostile":
			match my_faction:
				0: # PLAYER
					result.append_array(enemy_units)
					for n in neutral_units:
						if not is_instance_valid(n): continue
						var l = n.get("loyalty")
						if is_instance_valid(l) and l.get("neutral_loyalty") != 0:
							result.append(n)
				1: # ENEMY
					result.append_array(player_units)
					for n in neutral_units:
						if not is_instance_valid(n): continue
						var l = n.get("loyalty")
						if is_instance_valid(l) and l.get("neutral_loyalty") != 1:
							result.append(n)
				2: # NEUTRAL
					if my_loyalty == 0:
						result.append_array(enemy_units)
					elif my_loyalty == 1:
						result.append_array(player_units)
					else:
						result.append_array(player_units)
						result.append_array(enemy_units)
		"friendly":
			match my_faction:
				0: # PLAYER
					result.append_array(player_units)
					for n in neutral_units:
						if not is_instance_valid(n): continue
						var l = n.get("loyalty")
						if is_instance_valid(l) and l.get("neutral_loyalty") == 0:
							result.append(n)
				1: # ENEMY
					result.append_array(enemy_units)
					for n in neutral_units:
						if not is_instance_valid(n): continue
						var l = n.get("loyalty")
						if is_instance_valid(l) and l.get("neutral_loyalty") == 1:
							result.append(n)
				2: # NEUTRAL
					for n in neutral_units:
						if n != unit: result.append(n)
					if my_loyalty == 0:
						result.append_array(player_units)
					elif my_loyalty == 1:
						result.append_array(enemy_units)
		"neutral":
			for n in neutral_units:
				if n != unit: result.append(n)
	return result

## Filters targets by range.
static func get_units_in_range(source: Node2D, targets: Array, range_val: float, grid_map: TileMapLayer = null, filter: Callable = Callable()) -> Array:
	var result: Array = []
	if not is_instance_valid(source):
		return result

	var use_grid = is_instance_valid(grid_map) or ("grid_map" in source and is_instance_valid(source.get("grid_map")))
	var my_coord = MapDiscovery.get_grid_location(source, grid_map)
	var axis = 1
	var actual_grid = grid_map if is_instance_valid(grid_map) else (source.get("grid_map") if "grid_map" in source else null)
	if is_instance_valid(actual_grid) and actual_grid.tile_set:
		axis = actual_grid.tile_set.tile_offset_axis

	for target in targets:
		if target == source or not is_instance_valid(target):
			continue
		if filter.is_valid() and not filter.call(target):
			continue

		var in_range = false
		if use_grid and "get_grid_location" in target:
			var target_coord = target.get_grid_location()
			var dist = HexNavigator.get_hex_distance(my_coord, target_coord, axis)
			if dist <= range_val:
				in_range = true
		else:
			var dist = source.global_position.distance_to(target.global_position)
			if dist <= (range_val * 64.0):
				in_range = true
		
		if in_range:
			result.append(target)
	return result

## Returns the closest target from the list.
static func get_closest_target(source: Node2D, targets: Array, grid_map: TileMapLayer = null) -> Node2D:
	if targets.is_empty() or not is_instance_valid(source):
		return null

	var closest: Node2D = null
	var min_dist := INF

	var use_grid = is_instance_valid(grid_map) or ("grid_map" in source and is_instance_valid(source.get("grid_map")))
	var my_coord = MapDiscovery.get_grid_location(source, grid_map)
	var axis = 1
	var actual_grid = grid_map if is_instance_valid(grid_map) else (source.get("grid_map") if "grid_map" in source else null)
	if is_instance_valid(actual_grid) and actual_grid.tile_set:
		axis = actual_grid.tile_set.tile_offset_axis

	for target in targets:
		if target == source or not is_instance_valid(target):
			continue

		var dist = 0.0
		if use_grid and "get_grid_location" in target:
			dist = float(HexNavigator.get_hex_distance(my_coord, target.get_grid_location(), axis))
		else:
			dist = source.global_position.distance_to(target.global_position)

		if dist < min_dist:
			min_dist = dist
			closest = target

	return closest

## Sums the max willpower for all units of a faction.
static func get_fleet_willpower(unit_manager: Node, faction: int) -> int:
	if not is_instance_valid(unit_manager):
		return 0
	
	var total := 0
	var units: Array = []
	match faction:
		0: units = unit_manager.get_player_units()
		1: units = unit_manager.get_enemy_units()
		2: units = unit_manager.get_neutral_units()
	
	for unit in units:
		if is_instance_valid(unit):
			total += unit.get("max_willpower") if "max_willpower" in unit else 0
	return total

## Returns neutral units within range that are persuadable.
static func get_persuadable_neutrals(unit: Node, units: Array, axis: int) -> Array:
	var persuadables: Array = []
	if not is_instance_valid(unit):
		return persuadables
		
	var my_coord = MapDiscovery.get_grid_location(unit)
	
	for target in units:
		if not is_instance_valid(target):
			continue
		if target.get("faction") != 2: # Unit.Faction.NEUTRAL
			continue
		if not target.get("neutral_can_be_persuaded"):
			continue
			
		var target_coord = target.get_grid_location()
		if HexNavigator.get_hex_distance(my_coord, target_coord, axis) <= 1:
			persuadables.append(target)
	return persuadables

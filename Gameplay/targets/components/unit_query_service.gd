class_name UnitQueryService
extends RefCounted

var _unit: Unit
var _cached_hostiles: Array[Unit] = []
var _hostiles_dirty: bool = true
var _cached_friendlies: Array[Unit] = []
var _friendlies_dirty: bool = true
var _cached_neutrals: Array[Unit] = []
var _neutrals_dirty: bool = true

func _init(unit: Unit) -> void:
	_unit = unit

func has_nearby_units(units: Array, detection_range: float) -> bool:
	return not get_units_in_range(units, detection_range).is_empty()

func get_units_in_range(units: Array, detection_range: float) -> Array[Unit]:
	var result: Array[Unit] = []
	result.assign(_collect_targets_in_range(units, detection_range))
	return result

func get_adjacent_units(units: Array, adjacency_range: float = 1.5) -> Array[Unit]:
	# Optimization: Use grid map neighbors if available and range is small (adjacent)
	if adjacency_range <= 1.5 and is_instance_valid(_unit) and _unit.grid_map and _unit.get_unit_manager():
		var result: Array[Unit] = []
		var current_pos = _unit.get_grid_location()
		# Use TileMapLayer/TileMap method to get neighbors
		var neighbors = _unit.grid_map.get_surrounding_cells(current_pos)

		for neighbor in neighbors:
			var unit_at = _unit.get_unit_manager().get_unit_at_coord(neighbor)
			if unit_at and unit_at != _unit:
				# Only include if it's in the candidate list
				if units.has(unit_at):
					result.append(unit_at)
		return result

	var collected = _collect_targets_in_range(units, adjacency_range)
	var result: Array[Unit] = []
	result.assign(collected)
	return result

func get_units_in_range_by_faction(units: Array, detection_range: float, target_faction: int) -> Array[Unit]:
	var result: Array[Unit] = []
	result.assign(_collect_targets_in_range(units, detection_range, func(u): return u.faction == target_faction))
	return result

func get_units_in_range_without_full_morale(units: Array, detection_range: float) -> Array[Unit]:
	return get_units_in_range_without_full_willpower(units, detection_range)

func get_units_in_range_without_full_willpower(units: Array, detection_range: float) -> Array[Unit]:
	var result: Array[Unit] = []
	result.assign(_collect_targets_in_range(units, detection_range, func(u): return u.willpower < u.max_willpower))
	return result

func list_locations_in_range(locations: Array, detection_range: float) -> Array:
	return _collect_targets_in_range(locations, detection_range)

func invalidate_cache() -> void:
	_hostiles_dirty = true
	_friendlies_dirty = true
	_neutrals_dirty = true
	_cached_hostiles.clear()
	_cached_friendlies.clear()
	_cached_neutrals.clear()

func get_hostile_units() -> Array[Unit]:
	return _get_or_build(
		_cached_hostiles,
		"_hostiles_dirty",
		func():
			return _get_relationship_units("hostile")
	)

func get_friendly_units() -> Array[Unit]:
	return _get_or_build(
		_cached_friendlies,
		"_friendlies_dirty",
		func():
			return _get_relationship_units("friendly")
	)

func get_neutral_units() -> Array[Unit]:
	return _get_or_build(
		_cached_neutrals,
		"_neutrals_dirty",
		func():
			return _get_relationship_units("neutral")
	)

func get_all_units_categorized() -> Dictionary:
	return {
		"enemies": get_hostile_units(),
		"allies": get_friendly_units(),
		"neutrals": get_neutral_units()
	}

func get_adjacent_units_categorized(adjacency_range: float = 1.5) -> Dictionary:
	return {
		"enemies": get_adjacent_units(get_hostile_units(), adjacency_range),
		"allies": get_adjacent_units(get_friendly_units(), adjacency_range),
		"neutrals": get_adjacent_units(get_neutral_units(), adjacency_range)
	}

func get_persuadable_neutrals() -> Array[Unit]:
	var persuadables: Array[Unit] = []
	var units = get_neutral_units()
	var axis = _get_axis()
	var my_coord = _unit.get_grid_location()

	for target in units:
		if not is_instance_valid(target):
			continue
		if not target.get("neutral_can_be_persuaded"):
			continue

		var target_coord = target.get_grid_location()
		if HexNavigator.get_hex_distance(my_coord, target_coord, axis) <= 1:
			persuadables.append(target)
	return persuadables

func get_closest_unit(units: Array) -> Unit:
	if units.is_empty() or not is_instance_valid(_unit):
		return null

	var closest: Unit = null
	var min_dist := INF
	var my_coord = _unit.get_grid_location()
	var axis = _get_axis()

	for target in units:
		if target == _unit or not is_instance_valid(target): continue
		var dist = HexLib.get_distance(my_coord, target.get_grid_location(), axis)
		if dist < min_dist:
			min_dist = float(dist)
			closest = target
	return closest

func get_unit_at(coord: Vector2i) -> Unit:
	var um = _unit.get_unit_manager()
	return um.get_unit_at_coord(coord) if is_instance_valid(um) else null

func get_loot_at(coord: Vector2i) -> Loot:
	var lm = _unit.get_loot_manager()
	return lm.get_loot_at(coord) if is_instance_valid(lm) else null

func get_location_at(coord: Vector2i) -> Location:
	var tm = _unit.get_task_manager()
	return tm.get_location_at(coord) if is_instance_valid(tm) else null

func is_occupied(coord: Vector2i) -> bool:
	var um = _unit.get_unit_manager()
	return um.is_occupied(coord) if is_instance_valid(um) else false

func _collect_targets_in_range(targets: Array, detection_range: float, filter: Callable = Callable()) -> Array:
	var result: Array = []
	if not is_instance_valid(_unit): return result

	var my_coord = _unit.get_grid_location()
	var axis = _get_axis()

	for target in targets:
		if target == _unit or not is_instance_valid(target): continue
		if filter.is_valid() and not filter.call(target): continue

		var dist = HexLib.get_distance(my_coord, target.get_grid_location(), axis)
		if dist <= detection_range:
			result.append(target)
	return result

func _get_relationship_units(type: String) -> Array[Unit]:
	var um = _unit.get_unit_manager()
	if not is_instance_valid(um): return []

	var all_units = um.get_all_units()
	var result: Array[Unit] = []

	match type:
		"hostile":
			for u in all_units:
				if _unit.is_hostile(u):
					result.append(u)
		"friendly":
			for u in all_units:
				if _unit.is_friendly(u) or u == _unit:
					result.append(u)
		"neutral":
			for u in all_units:
				if u != _unit and not _unit.is_friendly(u) and not _unit.is_hostile(u):
					result.append(u)
	return result

func _get_axis() -> int:
	return _unit.grid_map.tile_set.tile_offset_axis if _unit.grid_map and _unit.grid_map.tile_set else 1

func _get_or_build(cache: Array, dirty_flag_var: String, builder_callable: Callable) -> Array:
	# Access the dirty flag using Reflection
	var dirty_flag = get(dirty_flag_var)

	if not dirty_flag:
		# Prune invalid references from cache
		var valid_cache: Array[Unit] = []
		var cache_changed := false
		for u in cache:
			if is_instance_valid(u):
				valid_cache.append(u)
			else:
				cache_changed = true
		if cache_changed:
			cache.assign(valid_cache)
		return cache.duplicate()

	var new_list = builder_callable.call()
	cache.assign(new_list)
	set(dirty_flag_var, false) # Set dirty flag to false using Reflection
	return cache.duplicate()

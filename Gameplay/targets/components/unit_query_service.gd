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
			var unit_at = MapDiscovery.get_unit_at(_unit.get_unit_manager(), neighbor)
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
			var hostiles: Array[Unit] = []
			hostiles.assign(UnitDiscovery.get_relationship_units(_unit, _unit.get_unit_manager(), "hostile"))
			return hostiles
	)

func get_friendly_units() -> Array[Unit]:
	return _get_or_build(
		_cached_friendlies,
		"_friendlies_dirty",
		func():
			var friendlies: Array[Unit] = []
			friendlies.assign(UnitDiscovery.get_relationship_units(_unit, _unit.get_unit_manager(), "friendly"))
			return friendlies
	)

func get_neutral_units() -> Array[Unit]:
	return _get_or_build(
		_cached_neutrals,
		"_neutrals_dirty",
		func():
			var neutrals: Array[Unit] = []
			neutrals.assign(UnitDiscovery.get_relationship_units(_unit, _unit.get_unit_manager(), "neutral"))
			return neutrals
	)

func get_closest_unit(units: Array) -> Unit:
	if units.is_empty() or not is_instance_valid(_unit):
		return null
	return UnitDiscovery.get_closest_target(_unit, units) as Unit

func get_unit_at(coord: Vector2i) -> Unit:
	if not is_instance_valid(_unit) or not _unit.get_unit_manager(): return null
	return MapDiscovery.get_unit_at(_unit.get_unit_manager(), coord)

func get_loot_at(coord: Vector2i) -> Loot:
	if not is_instance_valid(_unit) or not _unit.get_loot_manager(): return null
	return MapDiscovery.get_loot_at(_unit.get_loot_manager(), coord)

func get_location_at(coord: Vector2i) -> Location:
	if not is_instance_valid(_unit) or not _unit.get_task_manager(): return null
	return MapDiscovery.get_location_at(_unit.get_task_manager(), coord)

func is_occupied(coord: Vector2i) -> bool:
	if not is_instance_valid(_unit) or not _unit.get_unit_manager(): return false
	return MapDiscovery.is_occupied(_unit.get_unit_manager(), coord)

func _collect_targets_in_range(targets: Array, detection_range: float, filter: Callable = Callable()) -> Array:
	if not is_instance_valid(_unit):
		return []
	return UnitDiscovery.get_units_in_range(_unit, targets, detection_range, _unit.grid_map, filter)

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

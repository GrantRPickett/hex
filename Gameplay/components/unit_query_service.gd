class_name UnitQueryService
extends RefCounted

const HexNavigator := preload("res://Gameplay/hex_navigator.gd")

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

func get_units_in_range(units: Array, detection_range: float) -> Array:
	return _collect_targets_in_range(units, detection_range)

func get_adjacent_units(units: Array, adjacency_range: float = 1.5) -> Array:
	# Optimization: Use grid map neighbors if available and range is small (adjacent)
	if adjacency_range <= 1.5 and _unit.grid_map and _unit._unit_manager:
		var result: Array[Unit] = []
		var current_pos = _unit.get_grid_location()
		# Use TileMapLayer/TileMap method to get neighbors
		var neighbors = _unit.grid_map.get_surrounding_cells(current_pos)

		for neighbor in neighbors:
			var unit_at = _unit._unit_manager.get_unit_at_coord(neighbor)
			if unit_at and unit_at != _unit:
				# Only include if it's in the candidate list
				if units.has(unit_at):
					result.append(unit_at)
		return result

	return _collect_targets_in_range(units, adjacency_range)

func get_units_in_range_by_faction(units: Array, detection_range: float, target_faction: int) -> Array:
	return _collect_targets_in_range(units, detection_range, func(u): return u.faction == target_faction)

func get_units_in_range_without_full_morale(units: Array, detection_range: float) -> Array:
	return get_units_in_range_without_full_willpower(units, detection_range)

func get_units_in_range_without_full_willpower(units: Array, detection_range: float) -> Array:
	return _collect_targets_in_range(units, detection_range, func(u): return u.willpower < u.max_willpower)

func list_goals_in_range(goals: Array, detection_range: float) -> Array:
	return _collect_targets_in_range(goals, detection_range)

func invalidate_cache() -> void:
	_hostiles_dirty = true
	_friendlies_dirty = true
	_neutrals_dirty = true
	_cached_hostiles.clear()
	_cached_friendlies.clear()
	_cached_neutrals.clear()

func get_hostile_units() -> Array[Unit]:
	if not _hostiles_dirty:
		var valid_cache: Array[Unit] = []
		var cache_changed := false
		for u in _cached_hostiles:
			if is_instance_valid(u):
				valid_cache.append(u)
			else:
				cache_changed = true
		if cache_changed:
			_cached_hostiles = valid_cache
		return _cached_hostiles.duplicate()

	if not _unit or not _unit._unit_manager:
		return []

	var manager = _unit._unit_manager
	var hostiles: Array[Unit] = []

	match _unit.faction:
		Unit.Faction.PLAYER:
			hostiles.append_array(manager.get_enemy_units())
			hostiles.append_array(manager.get_neutral_units())
		Unit.Faction.ENEMY:
			hostiles.append_array(manager.get_player_units())
			hostiles.append_array(manager.get_neutral_units())
		Unit.Faction.NEUTRAL:
			hostiles.append_array(manager.get_player_units())
			hostiles.append_array(manager.get_enemy_units())

	_cached_hostiles = hostiles
	_hostiles_dirty = false
	return _cached_hostiles.duplicate()

func get_friendly_units() -> Array[Unit]:
	if not _friendlies_dirty:
		var valid_cache: Array[Unit] = []
		var cache_changed := false
		for u in _cached_friendlies:
			if is_instance_valid(u):
				valid_cache.append(u)
			else:
				cache_changed = true
		if cache_changed:
			_cached_friendlies = valid_cache
		return _cached_friendlies.duplicate()

	if not _unit or not _unit._unit_manager:
		return []
	_cached_friendlies = _unit._unit_manager.get_units_by_faction(_unit.faction)
	_friendlies_dirty = false
	return _cached_friendlies.duplicate()

func get_neutral_units() -> Array[Unit]:
	if not _neutrals_dirty:
		var valid_cache: Array[Unit] = []
		var cache_changed := false
		for u in _cached_neutrals:
			if is_instance_valid(u):
				valid_cache.append(u)
			else:
				cache_changed = true
		if cache_changed:
			_cached_neutrals = valid_cache
		return _cached_neutrals.duplicate()

	if not _unit or not _unit._unit_manager:
		return []

	var neutrals: Array[Unit] = []
	if _unit.faction != Unit.Faction.NEUTRAL:
		neutrals.append_array(_unit._unit_manager.get_neutral_units())

	_cached_neutrals = neutrals
	_neutrals_dirty = false
	return _cached_neutrals.duplicate()

func get_closest_unit(units: Array) -> Unit:
	if units.is_empty():
		return null

	var closest: Unit = null
	var min_dist := INF

	var use_grid = _unit.grid_map != null
	var my_coord = _unit.get_grid_location() if use_grid else Vector2i.ZERO
	var axis = 1
	if use_grid and _unit.grid_map.tile_set:
		axis = _unit.grid_map.tile_set.tile_offset_axis

	for target in units:
		if target == _unit or not is_instance_valid(target):
			continue

		var dist = 0.0
		if use_grid:
			dist = float(HexNavigator.get_hex_distance(my_coord, target.get_grid_location(), axis))
		else:
			dist = _unit.global_position.distance_to(target.global_position)

		if dist < min_dist:
			min_dist = dist
			closest = target

	return closest

func _collect_targets_in_range(targets: Array, detection_range: float, filter: Callable = Callable()) -> Array:
	var result: Array = []
	var my_pos = _unit.global_position

	var use_grid = _unit.grid_map != null
	var my_coord = _unit.get_grid_location() if use_grid else Vector2i.ZERO
	var axis = 1 # Default vertical
	if use_grid and _unit.grid_map.tile_set:
		axis = _unit.grid_map.tile_set.tile_offset_axis

	for target in targets:
		if target == _unit:
			continue
		if not is_instance_valid(target):
			continue

		if filter.is_valid() and not filter.call(target):
			continue

		var in_range = false
		if use_grid and target is Unit:
			var target_coord = target.get_grid_location()
			var dist = HexNavigator.get_hex_distance(my_coord, target_coord, axis)
			if dist <= detection_range:
				in_range = true
		else:
			# Fallback for non-unit targets or no grid
			var dist = my_pos.distance_to(target.global_position)
			if dist <= (detection_range * 64.0):
				in_range = true

		if in_range:
			result.append(target)

	return result
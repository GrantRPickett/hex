class_name UnitQueryService
extends RefCounted

enum RelationshipType { HOSTILE, FRIENDLY, NEUTRAL }

var _unit: Unit
var _caches: Dictionary = {} # Key -> Array[Unit]
var _dirty_flags: Dictionary = {} # Key -> bool

func _init(unit: Unit) -> void:
	_unit = unit
	invalidate_cache()

func has_nearby_units(units: Array, detection_range: float) -> bool:
	return not get_units_in_range(units, detection_range).is_empty()

func get_units_in_range(units: Array, detection_range: float, filter: Callable = Callable()) -> Array[Unit]:
	var result: Array[Unit] = []
	result.assign(_collect_targets_in_range(units, detection_range, filter))
	return result

func get_targets_in_range(targets: Array, detection_range: float, filter: Callable = Callable()) -> Array:
	return _collect_targets_in_range(targets, detection_range, filter)

func get_near_units(units: Array, adjacency_range: float = GameConstants.AI.GRID_ADJACENCY_THRESHOLD) -> Array[Unit]:
	return get_units_in_range(units, adjacency_range)

func get_near_targets(targets: Array, adjacency_range: float = GameConstants.AI.GRID_ADJACENCY_THRESHOLD) -> Array:
	return get_targets_in_range(targets, adjacency_range)

func get_units_in_range_by_faction(units: Array, detection_range: float, target_faction: int) -> Array[Unit]:
	return get_units_in_range(units, detection_range, func(u: Unit) -> bool: return u.faction == target_faction)

func get_units_in_range_without_full_willpower(units: Array, detection_range: float) -> Array[Unit]:
	return get_units_in_range(units, detection_range, func(u: Unit) -> bool: return u.willpower < u.max_willpower)

func get_units_in_range_without_full_morale(units: Array, detection_range: float) -> Array[Unit]:
	return get_units_in_range_without_full_willpower(units, detection_range)

func list_locations_in_range(locations: Array, detection_range: float) -> Array:
	return _collect_targets_in_range(locations, detection_range)

func invalidate_cache() -> void:
	_dirty_flags[RelationshipType.HOSTILE] = true
	_dirty_flags[RelationshipType.FRIENDLY] = true
	_dirty_flags[RelationshipType.NEUTRAL] = true
	_caches[RelationshipType.HOSTILE] = [] as Array[Unit]
	_caches[RelationshipType.FRIENDLY] = [] as Array[Unit]
	_caches[RelationshipType.NEUTRAL] = [] as Array[Unit]

func get_hostile_units() -> Array[Unit]:
	return _get_or_build(
		RelationshipType.HOSTILE,
		func() -> Array[Unit]:
			return _get_relationship_units(RelationshipType.HOSTILE)
	)

func get_friendly_units() -> Array[Unit]:
	return _get_or_build(
		RelationshipType.FRIENDLY,
		func() -> Array[Unit]:
			return _get_relationship_units(RelationshipType.FRIENDLY)
	)

func get_neutral_units() -> Array[Unit]:
	return _get_or_build(
		RelationshipType.NEUTRAL,
		func() -> Array[Unit]:
			return _get_relationship_units(RelationshipType.NEUTRAL)
	)

func get_all_units_categorized() -> Dictionary:
	var enemies: Array[Unit] = get_hostile_units().filter(func(u: Unit) -> bool: return u.willpower > 0)
	var allies: Array[Unit] = get_friendly_units().filter(func(u: Unit) -> bool: return u != _unit and u.willpower > 0)
	var neutrals: Array[Unit] = get_neutral_units().filter(func(u: Unit) -> bool: return u != _unit and u.willpower > 0)
	return {
		"enemies": enemies,
		"allies": allies,
		"neutrals": neutrals
	}

func get_near_units_categorized(adjacency_range: float = GameConstants.AI.GRID_ADJACENCY_THRESHOLD) -> Dictionary:
	var results := TargetDiscoveryService.discover_nearby(_unit.get_grid_location(), adjacency_range, [TargetDiscoveryService.UNIT], {
		"unit_manager": _unit.get_unit_manager(),
		"source_unit": _unit
	})
	return results.get(TargetDiscoveryService.UNIT, {"enemies": [] as Array[Unit], "allies": [] as Array[Unit], "neutrals": [] as Array[Unit]})

func get_persuadable_neutrals() -> Array[Unit]:
	var neutrals := get_neutral_units()
	var result: Array[Unit] = []
	for u in neutrals:
		if TargetDiscoveryService.is_convincable(u):
			var my_coord := _unit.get_grid_location()
			var t_coord := u.get_grid_location()
			if HexLib.get_distance(my_coord, t_coord, _get_axis()) <= GameConstants.AI.GRID_ADJACENCY_THRESHOLD:
				result.append(u)
	return result

func get_closest_unit(units: Array) -> Unit:
	if units.is_empty() or not is_instance_valid(_unit):
		return null

	var closest: Unit = null
	var min_dist: float = INF
	var my_coord: Vector2i = _unit.get_grid_location()
	var axis: int = _get_axis()

	for target: Unit in units:
		if target == _unit or not is_instance_valid(target): continue
		var dist: int = HexLib.get_distance(my_coord, target.get_grid_location(), axis)
		if float(dist) < min_dist:
			min_dist = float(dist)
			closest = target
	return closest

func get_unit_at(coord: Vector2i) -> Unit:
	var um := _unit.get_unit_manager()
	return um.get_unit_at_coord(coord) if is_instance_valid(um) else null

func get_loot_at(coord: Vector2i) -> Loot:
	var lm := _unit.get_loot_manager()
	return lm.get_loot_at(coord) if is_instance_valid(lm) else null

func get_location_at(coord: Vector2i) -> Location:
	var tm := _unit.get_task_manager()
	return tm.get_location_at(coord) if is_instance_valid(tm) else null

func is_occupied(coord: Vector2i) -> bool:
	var um := _unit.get_unit_manager()
	return um.is_occupied(coord) if is_instance_valid(um) else false

func _collect_targets_in_range(targets: Array, detection_range: float, filter: Callable = Callable()) -> Array:
	var result: Array = []
	if not is_instance_valid(_unit): return result

	var my_coord: Vector2i = _unit.get_grid_location()
	var axis: int = _get_axis()

	for target: Node in targets:
		if target == _unit or not is_instance_valid(target): continue
		if filter.is_valid() and not filter.call(target): continue

		var t_coord := Vector2i.MAX
		if target.has_method("get_grid_location"):
			t_coord = target.call("get_grid_location")
		
		if t_coord != Vector2i.MAX:
			var dist: int = HexLib.get_distance(my_coord, t_coord, axis)
			if float(dist) <= detection_range:
				result.append(target)
	return result

func _get_relationship_units(type: RelationshipType) -> Array[Unit]:
	var um := _unit.get_unit_manager()
	if not is_instance_valid(um): return []

	var all_units := um.get_all_units()
	var result: Array[Unit] = []

	match type:
		RelationshipType.HOSTILE:
			for u: Unit in all_units:
				if _unit.is_hostile(u):
					result.append(u)
		RelationshipType.FRIENDLY:
			for u: Unit in all_units:
				if _unit.is_friendly(u) or u == _unit:
					result.append(u)
		RelationshipType.NEUTRAL:
			for u: Unit in all_units:
				if u != _unit and not _unit.is_friendly(u) and not _unit.is_hostile(u):
					result.append(u)
	return result

func _get_axis() -> int:
	return _unit.grid_map.tile_set.tile_offset_axis if _unit.grid_map and _unit.grid_map.tile_set else TileSet.TILE_OFFSET_AXIS_VERTICAL

func _get_or_build(type: RelationshipType, builder_callable: Callable) -> Array[Unit]:
	if not _dirty_flags.get(type, true):
		var cache: Array[Unit] = _caches.get(type, [])
		var valid_cache: Array[Unit] = []
		var cache_changed := false
		for u: Unit in cache:
			if is_instance_valid(u):
				valid_cache.append(u)
			else:
				cache_changed = true
		if cache_changed:
			_caches[type] = valid_cache
		return (_caches[type] as Array[Unit]).duplicate()

	var new_list: Array[Unit] = builder_callable.call()
	var typed_list: Array[Unit] = []
	typed_list.assign(new_list)
	_caches[type] = typed_list
	_dirty_flags[type] = false
	return (_caches[type] as Array[Unit]).duplicate()

func get_total_attribute(idx: GameConstants.AttributeIndex) -> int:
	if _unit == null: return 0
	return _unit.get_attribute(idx)

func get_attribute_bonus(idx: GameConstants.AttributeIndex) -> int:
	if _unit == null: return 0
	var bonus: int = 0
	if _unit.has_method("get_attribute_modifiers"):
		var mods_dict: Dictionary = _unit.call("get_attribute_modifiers")
		for mods in mods_dict.values():
			bonus += GameConstants.get_attribute_value(mods, idx)

	if not _unit.ignore_weather:
		var weather_manager := _get_weather_manager()
		if weather_manager:
			var weather_info: Dictionary = weather_manager.call("get_weather_info")
			var bonuses: Dictionary = weather_info.get("bonuses", {})
			bonus += GameConstants.get_attribute_value(bonuses, idx)

	if int(idx) < 6:
		var pair_idx := int(idx) >> 1
		var aid_buffs := _unit.aid_buffs
		if aid_buffs.size() > pair_idx:
			bonus += int(aid_buffs[pair_idx])

	var consumables := _unit.consumables_active
	var pair_idx_cons := int(idx) >> 1
	if consumables.has(pair_idx_cons):
		bonus += int(consumables[pair_idx_cons])

	return bonus

func _get_weather_manager() -> Node:
	if Engine.has_singleton("WeatherManager"):
		return Engine.get_singleton("WeatherManager")
	if _unit and _unit.is_inside_tree():
		return _unit.get_node_or_null("/root/WeatherManager")
	return null

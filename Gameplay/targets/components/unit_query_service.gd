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

func get_adjacent_units(units: Array, adjacency_range: float = 1.5) -> Array[Unit]:
	return get_units_in_range(units, adjacency_range)

func get_units_in_range_by_faction(units: Array, detection_range: float, target_faction: int) -> Array[Unit]:
	return get_units_in_range(units, detection_range, func(u): return u.faction == target_faction)

func get_units_in_range_without_full_morale(units: Array, detection_range: float) -> Array[Unit]:
	return get_units_in_range_without_full_willpower(units, detection_range)

func get_units_in_range_without_full_willpower(units: Array, detection_range: float) -> Array[Unit]:
	return get_units_in_range(units, detection_range, func(u): return u.willpower < u.max_willpower)

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
		func():
			return _get_relationship_units(RelationshipType.HOSTILE)
	)

func get_friendly_units() -> Array[Unit]:
	return _get_or_build(
		RelationshipType.FRIENDLY,
		func():
			return _get_relationship_units(RelationshipType.FRIENDLY)
	)

func get_neutral_units() -> Array[Unit]:
	return _get_or_build(
		RelationshipType.NEUTRAL,
		func():
			return _get_relationship_units(RelationshipType.NEUTRAL)
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
	return get_units_in_range(get_neutral_units(), 1.5, func(u): return u.get("neutral_can_be_persuaded"))

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

func _get_relationship_units(type: RelationshipType) -> Array[Unit]:
	var um = _unit.get_unit_manager()
	if not is_instance_valid(um): return []

	var all_units = um.get_all_units()
	var result: Array[Unit] = []

	match type:
		RelationshipType.HOSTILE:
			for u in all_units:
				if _unit.is_hostile(u):
					result.append(u)
		RelationshipType.FRIENDLY:
			for u in all_units:
				if _unit.is_friendly(u) or u == _unit:
					result.append(u)
		RelationshipType.NEUTRAL:
			for u in all_units:
				if u != _unit and not _unit.is_friendly(u) and not _unit.is_hostile(u):
					result.append(u)
	return result

func _get_axis() -> int:
	return _unit.grid_map.tile_set.tile_offset_axis if _unit.grid_map and _unit.grid_map.tile_set else 1

func _get_or_build(type: RelationshipType, builder_callable: Callable) -> Array[Unit]:
	if not _dirty_flags.get(type, true):
		# Prune invalid references from cache
		var cache: Array[Unit] = _caches.get(type, [])
		var valid_cache: Array[Unit] = []
		var cache_changed := false
		for u in cache:
			if is_instance_valid(u):
				valid_cache.append(u)
			else:
				cache_changed = true
		if cache_changed:
			_caches[type] = valid_cache
		return _caches[type].duplicate()

	var new_list = builder_callable.call()
	var typed_list: Array[Unit] = []
	typed_list.assign(new_list)
	_caches[type] = typed_list
	_dirty_flags[type] = false
	return _caches[type].duplicate()

func get_total_attribute(idx: GameConstants.Attributes.AttributeIndex) -> int:
	if _unit == null: return 0

	var base := 0
	if idx == GameConstants.Attributes.AttributeIndex.WILLPOWER:
		base = _unit.base_willpower
	else:
		base = _unit.get_base_attribute_from_target(idx)

	return base + get_attribute_bonus(idx)

func get_attribute_bonus(idx: GameConstants.Attributes.AttributeIndex) -> int:
	if _unit == null: return 0
	var bonus := 0
	var attr_name = GameConstants.Attributes.get_attribute_name(idx)
	var capitalized_name = attr_name.capitalize()

	# 1. Item Modifiers
	if _unit.has_method("get_attribute_modifiers"):
		var mods_dict = _unit.get_attribute_modifiers()
		for mods in mods_dict.values():
			# Check multiple key formats for maximum compatibility
			if mods.has(idx):
				bonus += int(mods[idx])
			elif mods.has(attr_name):
				bonus += int(mods[attr_name])
			elif mods.has(capitalized_name):
				bonus += int(mods[capitalized_name])

	# 2. Weather
	if not _unit.get("ignore_weather"):
		var weather_manager = _get_weather_manager()
		if weather_manager:
			var weather_info = weather_manager.get_weather_info()
			var bonuses = weather_info.get("bonuses", {})
			if bonuses.has(idx):
				bonus += int(bonuses[idx])
			elif bonuses.has(attr_name):
				bonus += int(bonuses[attr_name])
			elif bonuses.has(capitalized_name):
				bonus += int(bonuses[capitalized_name])

	# 3. Aid Buffs
	if idx < 6 and "aid_buffs" in _unit:
		var pair_idx = int(idx) / 2
		var aid_buffs = _unit.get("aid_buffs")
		if aid_buffs is Array and pair_idx < aid_buffs.size():
			bonus += int(aid_buffs[pair_idx])

	return bonus


func _get_weather_manager() -> Node:
	if Engine.has_singleton("WeatherManager"):
		return Engine.get_singleton("WeatherManager")
	if _unit and _unit.is_inside_tree():
		return _unit.get_node_or_null("/root/WeatherManager")
	return null

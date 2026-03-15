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

func get_near_units(units: Array, adjacency_range: float = 1.5) -> Array[Unit]:
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
	var enemies = get_hostile_units().filter(func(u): return u.willpower > 0)
	var allies = get_friendly_units().filter(func(u): return u != _unit and u.willpower > 0)
	var neutrals = get_neutral_units().filter(func(u): return u != _unit and u.willpower > 0)
	return {
		"enemies": enemies,
		"allies": allies,
		"neutrals": neutrals
	}

func get_near_units_categorized(adjacency_range: float = 1.5) -> Dictionary:
	# If we are using the default adjacency range (1.5 covers neighbors), use the optimized O(1) grid lookup
	if adjacency_range <= 1.5:
		var enemies: Array[Unit] = []
		var allies: Array[Unit] = []
		var neutrals: Array[Unit] = []

		var my_coord: Vector2i = _unit.get_grid_location()
		var axis = _get_axis()
		var offsets = HexLib.get_neighbor_offsets(my_coord, axis)
		var um = _unit.get_unit_manager()

		if is_instance_valid(um):
			for offset in offsets:
				var target = um.get_unit_at_coord(my_coord + offset)
				if is_instance_valid(target) and target.willpower > 0:
					if _unit.is_hostile(target):
						enemies.append(target)
					elif _unit.is_friendly(target):
						if target != _unit:
							allies.append(target)
					else:
						neutrals.append(target)

		return {
			"enemies": enemies,
			"allies": allies,
			"neutrals": neutrals
		}
	
	# Fallback to O(N) distance check for non-default ranges
	return {
		"enemies": get_near_units(get_hostile_units(), adjacency_range).filter(func(u): return u.willpower > 0),
		"allies": get_near_units(get_friendly_units(), adjacency_range).filter(func(u): return u != _unit and u.willpower > 0),
		"neutrals": get_near_units(get_neutral_units(), adjacency_range).filter(func(u): return u != _unit and u.willpower > 0)
	}

func get_persuadable_neutrals() -> Array[Unit]:
	return get_units_in_range(get_neutral_units(), 1.5, func(u): return u.get("neutral_can_be_persuaded"))

func get_closest_unit(units: Array) -> Unit:
	if units.is_empty() or not is_instance_valid(_unit):
		return null

	var closest: Unit = null
	var min_dist := INF
	var my_coord: Vector2i = _unit.get_grid_location()
	var axis = _get_axis()

	for target in units:
		if target == _unit or not is_instance_valid(target): continue
		var dist: int = HexLib.get_distance(my_coord, target.get_grid_location(), axis)
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
	var tm: TaskManager = _unit.get_task_manager()
	return tm.get_location_at(coord) if is_instance_valid(tm) else null

func is_occupied(coord: Vector2i) -> bool:
	var um = _unit.get_unit_manager()
	return um.is_occupied(coord) if is_instance_valid(um) else false

func _collect_targets_in_range(targets: Array, detection_range: float, filter: Callable = Callable()) -> Array:
	var result: Array = []
	if not is_instance_valid(_unit): return result

	var my_coord: Vector2i = _unit.get_grid_location()
	var axis = _get_axis()

	for target in targets:
		if target == _unit or not is_instance_valid(target): continue
		if filter.is_valid() and not filter.call(target): continue

		var dist: int = HexLib.get_distance(my_coord, target.get_grid_location(), axis)
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

func get_total_attribute(idx: GameConstants.AttributeIndex) -> int:
	if _unit == null: return 0

	var base := 0
	if idx == GameConstants.AttributeIndex.WILLPOWER:
		base = _unit.base_willpower
	else:
		base = _unit.get_base_attribute_from_target(idx)

	var bonus := get_attribute_bonus(idx)
	var total := base + bonus

	if _unit.is_in_group("player"):
		print_debug("[AttrDebug] Unit: %s, Attr: %s, Base: %d, Bonus: %d, Total: %d" % [
			_unit.unit_name if "unit_name" in _unit else "Unknown",
			GameConstants.get_attribute_name(idx),
			base,
			bonus,
			total
		])

	return total

func get_attribute_bonus(idx: GameConstants.AttributeIndex) -> int:
	if _unit == null: return 0
	var bonus := 0
	var item_bonus := 0
	var weather_bonus := 0
	var aid_bonus := 0
	var consumable_bonus := 0

	# 1. Item Modifiers
	if _unit.has_method("get_attribute_modifiers"):
		var mods_dict = _unit.get_attribute_modifiers()
		for mods in mods_dict.values():
			item_bonus += GameConstants.get_attribute_value(mods, idx)
	bonus += item_bonus

	# 2. Weather
	if not _unit.get("ignore_weather"):
		var weather_manager = _get_weather_manager()
		if weather_manager:
			var weather_info: Dictionary = weather_manager.get_weather_info()
			var bonuses: Dictionary = weather_info.get("bonuses", {})
			weather_bonus += GameConstants.get_attribute_value(bonuses, idx)
	bonus += weather_bonus

	# 3. Aid Buffs
	if idx < 6 and "aid_buffs" in _unit:
		var pair_idx: int = int(idx) >> 1
		var aid_buffs = _unit.get("aid_buffs")
		if aid_buffs is Array and pair_idx < aid_buffs.size():
			aid_bonus += int(aid_buffs[pair_idx])
	bonus += aid_bonus

	# 4. Consumables
	if "consumables_active" in _unit:
		var pair_idx: int = int(idx) >> 1
		var consumables = _unit.get("consumables_active")
		if consumables is Dictionary and pair_idx in consumables:
			consumable_bonus += int(consumables[pair_idx])
	bonus += consumable_bonus

	if _unit.is_in_group("player") and bonus != 0:
		print_debug("  [BonusDetails] %s -> Items: %d, Weather: %d, Aid: %d, Consumables: %d" % [
			GameConstants.get_attribute_name(idx),
			item_bonus,
			weather_bonus,
			aid_bonus,
			consumable_bonus
		])

	return bonus


func _get_weather_manager() -> Node:
	if Engine.has_singleton("WeatherManager"):
		return Engine.get_singleton("WeatherManager")
	if _unit and _unit.is_inside_tree():
		return _unit.get_node_or_null("/root/WeatherManager")
	return null

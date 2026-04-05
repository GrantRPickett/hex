class_name TargetDiscoveryService
extends RefCounted

## --- Target Types ---

const UNIT : StringName = &"unit"
const LOOT : StringName = &"loot"
const LOCATION : StringName = &"location"
const ALL : Array[StringName] = [UNIT, LOOT, LOCATION]

static var _registry: Dictionary = {}
static var _counters: Dictionary = {}

## --- Generic Retrieval ---

static func get_target_by_id(target_id: String) -> Target:
	return _registry.get(target_id)

static func register_target(target: Target) -> void:
	if not is_instance_valid(target):
		return

	if target.id.is_empty():
		var prefix = target.get_subtype_prefix()
		var count = _counters.get(prefix, 0) + 1
		_counters[prefix] = count
		target.id = "%s_%d" % [prefix, count]

	_registry[target.id] = target

static func unregister_target(target: Target) -> void:
	if is_instance_valid(target) and not target.id.is_empty():
		_registry.erase(target.id)

static func clear_registry() -> void:
	_registry.clear()
	_counters.clear()

## Returns all targets at a coord using the internal registry.
static func get_targets_at_coord(coord: Vector2i) -> Array[Target]:
	var results: Array[Target] = []
	for t in _registry.values():
		if is_instance_valid(t) and t.get_grid_location() == coord:
			results.append(t)
	return results

## Convenience: returns the first target at a coord, or null.
static func get_target_at_coord(coord: Vector2i) -> Target:
	var all = get_targets_at_coord(coord)
	return all[0] if not all.is_empty() else null

## Typed: returns the target at a coord whose script class name matches the given StringName.
static func get_typed_target_at_coord(coord: Vector2i, type_name: StringName) -> Target:
	for t in get_targets_at_coord(coord):
		if t.get_script().get_global_name() == type_name:
			return t
	return null

## Discovers nearby targets of specified types within a radius.
static func discover_nearby(center: Vector2i, radius: float, types: Array, context: Dictionary) -> Dictionary:
	var results := {}

	# 1. Units (Optionally categorized if source_unit provided)
	if UNIT in types:
		var units = _filter_by_type(_registry.values(), UNIT)
		var nearby_units = _filter_nearby(units, center, radius)
		if context.has("source_unit"):
			results[UNIT] = _categorize_units(nearby_units, context.source_unit)
		else:
			results[UNIT] = nearby_units

	# 2. Non-Units (Loot, Locations)
	for type in types:
		if type == UNIT: continue
		var targets = _filter_by_type(_registry.values(), type)
		results[type] = _filter_nearby(targets, center, radius)

	return results

## Discovers reachable targets of specified types from a ReachableState.
static func discover_reachable(reach: ReachableState, types: Array, context: Dictionary) -> Dictionary:
	var results := {}
	if reach == null: return results
	var lookup := reach.lookup

	# 1. Units
	if UNIT in types:
		var units = _filter_by_type(_registry.values(), UNIT)
		var reachable_units = _filter_reachable(units, lookup)
		if context.has("source_unit"):
			results[UNIT] = _categorize_units(reachable_units, context.source_unit)
		else:
			results[UNIT] = reachable_units

	# 2. Non-Units
	for type in types:
		if type == UNIT: continue
		var targets = _filter_by_type(_registry.values(), type)
		results[type] = _filter_reachable(targets, lookup)

	return results


## --- Filtering & Internal Helpers ---

static func _is_target_of_type(target: Target, type_name: StringName) -> bool:
	if not is_instance_valid(target): return false
	match type_name:
		UNIT: return target is Unit
		LOOT: return target is Loot
		LOCATION: return target is Location
	return true

#todo: These filter functions could be optimized with indexing if needed, but for now we'll keep it simple and iterate over the registry.
static func get_targets_by_type( type_name: StringName) -> Array:
	return _filter_by_type(_registry.values(), type_name)

static func _filter_by_type(collection: Array, type_name: StringName) -> Array:
	var results = []
	for item in collection:
		if _is_target_of_type(item, type_name):
			results.append(item)
	return results

static func _filter_nearby(collection: Array, center: Vector2i, radius: float) -> Array:
	var results = []
	for item in collection:
		if HexLib.get_distance(center, item.get_grid_location()) <= radius:
			results.append(item)
	return results

static func _filter_reachable(collection: Array, lookup: Dictionary) -> Array:
	var results = []
	for item in collection:
		if lookup.has(item.get_grid_location()):
			results.append(item)
	return results

static func _categorize_units(units: Array, source_unit: Unit) -> Dictionary:
	var results := {"enemies": [] as Array[Unit], "allies": [] as Array[Unit], "neutrals": [] as Array[Unit]}
	for unit in units:
		if not is_instance_valid(unit) or unit == source_unit or unit.get_current_willpower() <= 0:
			continue
		if source_unit.is_hostile(unit):
			results.enemies.append(unit)
		elif source_unit.is_friendly(unit):
			results.allies.append(unit)
		else:
			results.neutrals.append(unit)
	return results


## --- Convince & Combat Discovery ---

## Returns true if the unit meets the criteria for being convinced.
static func is_convincable(unit: Unit) -> bool:
	if not is_instance_valid(unit): return false
	if unit.faction != GameConstants.Faction.NEUTRAL: return false

	if unit.loyalty:
		if unit.loyalty.loyalty_locked: return false
		if unit.loyalty.neutral_loyalty != GameConstants.Faction.NEUTRAL: return false

	if not unit.neutral_can_be_persuaded: return false
	if unit.loyalty and unit.loyalty.loyalty_type == GameConstants.Faction.STATIC: return false

	return true

## Splits a set of potential hostiles into those that must be fought and those that can be convinced.
static func split_units_for_combat(units: Array[Unit]) -> Dictionary:
	var fight: Array[Unit] = []
	var convince: Array[Unit] = []
	for u in units:
		if is_convincable(u): convince.append(u)
		else: fight.append(u)
	return {"fight": fight, "convince": convince}

## Compatibility alias for split_units_for_combat
static func split_targets(enemies: Array[Unit]) -> Dictionary:
	return split_units_for_combat(enemies)

## --- Categorized Discovery (UI Helpers) ---

## Gets categorized location information for action options.
static func get_categorized_locations(unit: Unit, reach: ReachableState) -> Dictionary:
	return get_categorized_targets(unit, reach, LOCATION)

## Gets categorized loot information for action options.
static func get_categorized_loot(unit: Unit, reach: ReachableState) -> Dictionary:
	return get_categorized_targets(unit, reach, LOOT)

## Generic function to categorize targets by reach and opposition.
## Context keys: "task_manager" (optional)
static func get_categorized_targets(unit: Unit, reach: ReachableState, type: StringName) -> Dictionary:
	var task_manager = unit.get_task_manager()
	var discovery_results = discover_reachable(reach, [type], {"faction": unit.faction})

	var reachable_list: Array = discovery_results.get(type, [])
	var action_origin := reach.action_origin if reach else unit.get_grid_location()
	var immediate_target: Target = get_target_at_coord(action_origin)

	# Only keep reachable targets that are NOT the immediate one, AND are either unexplored or have a task.
	var filtered_reachable: Array = []
	for target in reachable_list:
		if target == immediate_target: continue
		var has_task = false
		if task_manager:
			has_task = not task_manager.build_target_to_task([target], unit.faction).is_empty()

		var is_unexplored = true
		if target is Location: is_unexplored = not target.is_explored
		elif target is Loot: is_unexplored = not target.is_empty()

		if is_unexplored or has_task:
			filtered_reachable.append(target)

	var targets_to_map = filtered_reachable + ([immediate_target] if immediate_target else [])
	var target_to_task = task_manager.build_target_to_task(targets_to_map, unit.faction) if task_manager else {}

	var result := {
		"immediate_opposed": null,
		"reachable_opposed": [],
		"immediate_unopposed": null,
		"reachable_unopposed": []
	}

	var is_opposed = func(t: Target) -> bool:
		if not is_instance_valid(t): return false
		if t.is_opposed: return true
		var tid = target_to_task.get(t, "")
		if not tid.is_empty() and task_manager:
			var task = task_manager.get_task_by_id(tid)
			if task and task.is_opposed: return true
		return false

	if immediate_target and _is_target_of_type(immediate_target, type):
		var has_task = false
		if task_manager:
			has_task = not task_manager.build_target_to_task([immediate_target], unit.faction).is_empty()

		var is_unexplored = true
		if immediate_target is Location: is_unexplored = not immediate_target.is_explored
		elif immediate_target is Loot: is_unexplored = not immediate_target.is_empty()

		if is_unexplored or has_task:
			if is_opposed.call(immediate_target): result.immediate_opposed = immediate_target
			else: result.immediate_unopposed = immediate_target

	for target in filtered_reachable:
		if is_opposed.call(target): result.reachable_opposed.append(target)
		else: result.reachable_unopposed.append(target)

	# Return the same structure for both types to maintain compatibility
	if type == LOOT: return {"split_loot": result, "target_to_task": target_to_task}
	return {"split_locations": result, "target_to_task": target_to_task}

## --- Immediate Discovery (Action Helpers) ---

## Returns a location at a coordinate if it's actionable (unexplored or has a task).
static func get_immediate_location(unit: Unit, coord: Vector2i) -> Location:
	var target = get_target_at_coord(coord)
	if target is Location:
		var task_manager = unit.get_task_manager() if is_instance_valid(unit) else null
		var has_task = false
		if task_manager:
			has_task = not task_manager.build_target_to_task([target], unit.faction).is_empty()

		if not target.is_explored or has_task:
			return target
	return null

## Returns loot at a coordinate if it's actionable.
static func get_immediate_loot(_unit: Unit, coord: Vector2i, loot_manager: LootManager) -> Loot:
	if not is_instance_valid(loot_manager): return null
	var loot = loot_manager.get_loot_at(coord)
	if is_instance_valid(loot) and not loot.is_empty():
		return loot
	return null

## Returns tasks at a coordinate if they are actionable by the unit.
static func get_immediate_tasks(unit: Unit, coord: Vector2i) -> Array[Task]:
	var task_manager = unit.get_task_manager() if is_instance_valid(unit) else null
	if not is_instance_valid(task_manager): return []
	return task_manager.get_immediate_tasks(unit, coord)

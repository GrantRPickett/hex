class_name TargetDiscoveryService
extends RefCounted

## --- Target Types ---

const UNIT := &"unit"
const LOOT := &"loot"
const LOCATION := &"location"
const ALL := [UNIT, LOOT, LOCATION]

static var _registry: Dictionary = {}
static var _counters: Dictionary = {}

## --- Generic Retrieval ---

static func get_target_by_id (target_id: String) -> Target:
	return _registry.get(target_id)

static func register_target(target: Target) -> void:
	if not is_instance_valid(target):
		return

	if target.id.is_empty():
		var prefix = target._get_subtype_prefix()
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

## Returns all targets at a coord (at most 1 Location, 1 Loot, 1 Unit).
## context keys: "task_manager" (TaskManager), "unit_manager" (UnitManager)
static func get_targets_at_coord(coord: Vector2i, context: Dictionary) -> Array[Target]:
	var results: Array[Target] = []
	var task_manager: TaskManager = context.get("task_manager")
	var unit_manager: UnitManager = context.get("unit_manager")
	if task_manager:
		var loc = task_manager.get_location_at(coord)
		if loc: results.append(loc)
		var loot = task_manager.get_loot_at(coord)
		if loot: results.append(loot)
	if unit_manager:
		var unit = unit_manager.get_unit_at_coord(coord)
		if unit: results.append(unit)
	return results

## Convenience: returns the first target at a coord, or null.
static func get_target_at_coord(coord: Vector2i, context: Dictionary) -> Target:
	var all = get_targets_at_coord(coord, context)
	return all[0] if not all.is_empty() else null

## Typed: returns the target at a coord whose script class name matches the given StringName.
## e.g. get_typed_target_at_coord(coord, ctx, &"Location")
static func get_typed_target_at_coord(coord: Vector2i, context: Dictionary, type_name: StringName) -> Target:
	for t in get_targets_at_coord(coord, context):
		if t.get_script().get_global_name() == type_name:
			return t
	return null

## Discovers nearby targets of specified types within a radius.
static func discover_nearby(center: Vector2i, radius: float, types: Array, context: Dictionary) -> Dictionary:
	var results := {}
	var axis: int = context.get("axis", TileSet.TILE_OFFSET_AXIS_VERTICAL)

	if UNIT in types and context.has("unit_manager"):
		var unit_manager: UnitManager = context.unit_manager
		if context.has("source_unit"):
			results[UNIT] = _get_units_categorized_nearby(center, radius, unit_manager, context.source_unit, axis)
		else:
			results[UNIT] = _get_units_nearby(center, radius, unit_manager, axis)

	if LOOT in types and context.has("loot_manager"):
		results[LOOT] = _get_loot_nearby(center, radius, context.loot_manager, axis)

	if LOCATION in types and context.has("task_manager"):
		results[LOCATION] = _get_locations_nearby(center, radius, context.task_manager, axis)

	return results

## Discovers reachable targets of specified types from a ReachableState.
static func discover_reachable(reach: ReachableState, types: Array, context: Dictionary) -> Dictionary:
	var results := {}
	if reach == null: return results

	var lookup := reach.lookup

	if UNIT in types and context.has("unit_manager") and is_instance_valid(context.unit_manager):
		var unit_manager: UnitManager = context.unit_manager
		if context.has("source_unit"):
			results[UNIT] = _get_units_categorized_reachable(lookup, unit_manager, context.source_unit)
		else:
			results[UNIT] = _get_units_reachable(lookup, unit_manager)

	if LOOT in types and context.has("loot_manager") and is_instance_valid(context.loot_manager):
		results[LOOT] = _get_loot_reachable(lookup, context.loot_manager)

	if LOCATION in types and context.has("task_manager") and is_instance_valid(context.task_manager):
		results[LOCATION] = _get_locations_reachable(lookup, context.task_manager)

	return results


## --- Convince & Combat Discovery ---

## Returns true if the unit meets the criteria for being convinced.
static func is_convincable(unit: Unit) -> bool:
	if not is_instance_valid(unit):
		GameLogger.debug(GameLogger.Category.COMBAT, "[TargetDiscoveryService] is_convincable: unit is invalid")
		return false

	if unit.faction != GameConstants.Faction.NEUTRAL:
		GameLogger.debug(GameLogger.Category.COMBAT, "[TargetDiscoveryService] is_convincable: unit %s faction is not NEUTRAL (%d)" % [unit.unit_name, unit.faction])
		return false

	if unit.loyalty:
		if unit.loyalty.loyalty_locked:
			GameLogger.debug(GameLogger.Category.COMBAT, "[TargetDiscoveryService] is_convincable: unit %s loyalty is LOCKED" % unit.unit_name)
			return false

		if unit.loyalty.neutral_loyalty != GameConstants.Faction.NEUTRAL:
			GameLogger.debug(GameLogger.Category.COMBAT, "[TargetDiscoveryService] is_convincable: unit %s neutral_loyalty is not NEUTRAL (%d)" % [unit.unit_name, unit.loyalty.neutral_loyalty])
			return false

	if not unit.neutral_can_be_persuaded:
		GameLogger.debug(GameLogger.Category.COMBAT, "[TargetDiscoveryService] is_convincable: unit %s neutral_can_be_persuaded is FALSE" % unit.unit_name)
		return false

	if unit.loyalty and unit.loyalty.loyalty_type == GameConstants.Faction.STATIC:
		GameLogger.debug(GameLogger.Category.COMBAT, "[TargetDiscoveryService] is_convincable: unit %s loyalty_type is STATIC" % unit.unit_name)
		return false

	GameLogger.debug(GameLogger.Category.COMBAT, "[TargetDiscoveryService] is_convincable: unit %s is CONVINCABLE" % unit.unit_name)
	return true

## Splits a set of potential hostiles into those that must be fought and those that can be convinced.
static func split_units_for_combat(units: Array[Unit]) -> Dictionary:
	var fight: Array[Unit] = []
	var convince: Array[Unit] = []

	for u in units:
		if is_convincable(u):
			convince.append(u)
		else:
			fight.append(u)

	return {
		"fight": fight,
		"convince": convince
	}

## Compatibility alias for split_units_for_combat
static func split_targets(enemies: Array[Unit]) -> Dictionary:
	return split_units_for_combat(enemies)


## --- Loot Discovery ---

## Gets all loot items in the world, optionally filtered by range.
## Compatibility helper for older callers.
static func get_potential_loot_items(unit: Unit, loot_manager: LootManager, _unused = null, radius: float = GameConstants.AI.GRID_ADJACENCY_THRESHOLD) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	if not is_instance_valid(unit) or not is_instance_valid(loot_manager):
		return results

	var axis: int = unit.grid_map.tile_set.tile_offset_axis if unit.grid_map and unit.grid_map.tile_set else TileSet.TILE_OFFSET_AXIS_VERTICAL
	var center := unit.get_grid_location()

	for loot in loot_manager.get_all_loot():
		if is_instance_valid(loot):
			var loot_coord := loot.get_grid_location()
			if HexLib.get_distance(center, loot_coord, axis) <= radius:
				results.append({
					"item": loot,
					"coord": loot_coord
				})
	return results

## Gets all loot information categorized for a unit's action options.
static func get_categorized_loot(unit: Unit, reach: ReachableState) -> Dictionary:
	var loot_manager := unit.get_loot_manager()
	var task_manager := unit.get_task_manager()

	var discovery_results = discover_reachable(reach, [LOOT], {
		"loot_manager": loot_manager,
		"faction": unit.faction
	})

	var reachable_loot: Array[Loot] = []
	for l in discovery_results.get(LOOT, []):
		reachable_loot.append(l as Loot)

	var action_origin := reach.action_origin if reach else unit.get_grid_location()
	var immediate_loot := get_immediate_loot(unit, action_origin, loot_manager)

	var target_to_task = task_manager.build_target_to_task(reachable_loot + ([immediate_loot] if immediate_loot else []), unit.faction)

	var split_loot := {
		"immediate_opposed": null, # Loot
		"reachable_opposed": [] as Array[Loot],
		"immediate_unopposed": null, # Loot
		"reachable_unopposed": [] as Array[Loot]
	}

	# Identify if a target is opposed (has a task or is inherently opposed)
	var is_opposed_target = func(loot: Loot) -> bool:
		if not is_instance_valid(loot): return false
		if loot.is_opposed: return true
		var tid = target_to_task.get(loot, "")
		if not tid.is_empty():
			var task = task_manager.get_task_by_id(tid)
			if task and task.is_opposed: return true
		return false

	if immediate_loot:
		if is_opposed_target.call(immediate_loot):
			split_loot.immediate_opposed = immediate_loot
		else:
			split_loot.immediate_unopposed = immediate_loot

	for loot in reachable_loot:
		if loot == immediate_loot: continue
		if is_opposed_target.call(loot):
			split_loot.reachable_opposed.append(loot)
		else:
			split_loot.reachable_unopposed.append(loot)

	return {
		"split_loot": split_loot,
		"target_to_task": target_to_task
	}

static func get_immediate_loot(unit: Unit, coord: Vector2i, loot_manager: LootManager) -> Loot:
	if not is_instance_valid(loot_manager):
		return null
	var loot := loot_manager.get_loot_at(coord)
	if loot and is_instance_valid(unit) and can_be_looted_by(unit, loot):
		return loot
	return null

static func can_be_looted_by(unit: Unit, loot: Loot, interaction_range: float = GameConstants.AI.GRID_ADJACENCY_THRESHOLD) -> bool:
	if is_instance_valid(unit) and is_instance_valid(loot):
		return unit.distance_to_target(loot) <= interaction_range
	var axis: int = unit.grid_map.tile_set.tile_offset_axis if unit.grid_map and unit.grid_map.tile_set else TileSet.TILE_OFFSET_AXIS_VERTICAL
	return HexLib.get_distance(unit.get_grid_location(), loot.get_grid_location(), axis) <= interaction_range


## --- Task & Location Discovery ---

## Gets all location information categorized for a unit's action options.
static func get_categorized_locations(unit: Unit, reach: ReachableState) -> Dictionary:
	var task_manager := unit.get_task_manager()
	var discovery_results = discover_reachable(reach, [LOCATION], {
		"faction": unit.faction
	})

	var reachable_locations: Array[Location] = []
	for loc in discovery_results.get(LOCATION, []):
		reachable_locations.append(loc as Location)

	var action_origin := reach.action_origin if reach else unit.get_grid_location()
	var immediate_opposed: Location = task_manager.get_location_at(action_origin)
	var target_to_task = task_manager.build_target_to_task(reachable_locations + ([immediate_opposed] if immediate_opposed else []), unit.faction)

	var split_locations := {
		"immediate_opposed": null, # Location
		"reachable_opposed": [] as Array[Location],
		"immediate_unopposed": null, # Location
		"reachable_unopposed": [] as Array[Location]
	}

	# Identify if a location is opposed (inherently opposed or has a task that is opposed)
	var is_opposed_location = func(loc: Location) -> bool:
		if not is_instance_valid(loc): return false
		if loc.is_opposed: return true
		var tid = target_to_task.get(loc, "")
		if not tid.is_empty():
			var task = task_manager.get_task_by_id(tid)
			if task and task.is_opposed: return true
		return false

	if immediate_opposed:
		if is_opposed_location.call(immediate_opposed):
			split_locations.immediate_opposed = immediate_opposed
		else:
			split_locations.immediate_unopposed = immediate_opposed

	for loc in reachable_locations:
		if loc == immediate_opposed: continue
		if is_opposed_location.call(loc):
			split_locations.reachable_opposed.append(loc)
		else:
			split_locations.reachable_unopposed.append(loc)

	return {
		"split_locations": split_locations,
		"target_to_task": target_to_task
	}


## --- Internal Helpers ---

static func _get_units_nearby(center: Vector2i, radius: float, unit_manager: UnitManager, axis: int = TileSet.TILE_OFFSET_AXIS_VERTICAL) -> Array[Unit]:
	var results: Array[Unit] = []
	for unit in unit_manager.get_all_units():
		if is_instance_valid(unit) and HexLib.get_distance(center, unit.get_grid_location(), axis) <= radius:
			results.append(unit)
	return results

static func _get_units_categorized_nearby(center: Vector2i, radius: float, unit_manager: UnitManager, source_unit: Unit, axis: int = TileSet.TILE_OFFSET_AXIS_VERTICAL) -> Dictionary:
	var results := {"enemies": [] as Array[Unit], "allies": [] as Array[Unit], "neutrals": [] as Array[Unit]}
	for unit in unit_manager.get_all_units():
		if not is_instance_valid(unit) or unit == source_unit or unit.willpower <= 0:
			continue
		if HexLib.get_distance(center, unit.get_grid_location(), axis) <= radius:
			if source_unit.is_hostile(unit):
				results.enemies.append(unit)
			elif source_unit.is_friendly(unit):
				results.allies.append(unit)
			else:
				results.neutrals.append(unit)
	return results

static func _get_units_reachable(lookup: Dictionary, unit_manager: UnitManager) -> Array[Unit]:
	var results: Array[Unit] = []
	for unit in unit_manager.get_all_units():
		if is_instance_valid(unit) and lookup.has(unit.get_grid_location()):
			results.append(unit)
	return results

static func _get_units_categorized_reachable(lookup: Dictionary, unit_manager: UnitManager, source_unit: Unit) -> Dictionary:
	var results := {"enemies": [] as Array[Unit], "allies": [] as Array[Unit], "neutrals": [] as Array[Unit]}
	for unit in unit_manager.get_all_units():
		if not is_instance_valid(unit) or unit == source_unit or unit.willpower <= 0:
			continue
		if lookup.has(unit.get_grid_location()):
			if source_unit.is_hostile(unit):
				results.enemies.append(unit)
			elif source_unit.is_friendly(unit):
				results.allies.append(unit)
			else:
				results.neutrals.append(unit)
	return results

static func _get_loot_nearby(center: Vector2i, radius: float, loot_manager: LootManager, axis: int = TileSet.TILE_OFFSET_AXIS_VERTICAL) -> Array[Loot]:
	var results: Array[Loot] = []
	if not is_instance_valid(loot_manager): return results
	for loot in loot_manager.get_all_loot():
		if is_instance_valid(loot) and HexLib.get_distance(center, loot.get_grid_location(), axis) <= radius:
			results.append(loot)
	return results

static func _get_loot_reachable(lookup: Dictionary, loot_manager: LootManager) -> Array[Loot]:
	var results: Array[Loot] = []
	if not is_instance_valid(loot_manager): return results
	for loot in loot_manager.get_all_loot():
		if is_instance_valid(loot) and lookup.has(loot.get_grid_location()):
			results.append(loot)
	return results

static func _get_locations_nearby(center: Vector2i, radius: float, task_manager: TaskManager, axis: int = TileSet.TILE_OFFSET_AXIS_VERTICAL) -> Array[Location]:
	var results: Array[Location] = []
	if not is_instance_valid(task_manager): return results
	for loc in task_manager.get_all_locations():
		if is_instance_valid(loc) and HexLib.get_distance(center, loc.get_grid_location(), axis) <= radius:
			results.append(loc)
	return results

static func _get_locations_reachable(lookup: Dictionary, task_manager: TaskManager) -> Array[Location]:
	var results: Array[Location] = []
	if not is_instance_valid(task_manager): return results
	for loc in task_manager.get_all_locations():
		if is_instance_valid(loc) and lookup.has(loc.get_grid_location()):
			results.append(loc)
	return results



class_name TargetDiscoveryService
extends RefCounted

## --- Target Types ---

const UNIT := &"unit"
const LOOT := &"loot"
const LOCATION := &"location"
const ALL := [UNIT, LOOT, LOCATION]

## --- Generic Retrieval ---

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

	var target_to_task = _build_target_to_task(reachable_loot + ([immediate_loot] if immediate_loot else []), task_manager, unit.faction)

	var split_loot := {
		"immediate_opposed": null, # Loot
		"reachable_opposed": [] as Array[Loot],
		"immediate_unopposed": null, # Loot
		"reachable_unopposed": [] as Array[Loot]
	}

	# Identify if a target is opposed (has a task or is trapped)
	var is_opposed_target = func(loot: Loot) -> bool:
		if not is_instance_valid(loot): return false
		if loot.is_trapped: return true
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
	var target_to_task = _build_target_to_task(reachable_locations + ([immediate_opposed] if immediate_opposed else []), task_manager, unit.faction)

	var split_locations := {
		"immediate_opposed": null, # Location
		"reachable_opposed": [] as Array[Location],
		"immediate_unopposed": null, # Location
		"reachable_unopposed": [] as Array[Location]
	}

	# Identify if a location is opposed (danger or has a task that is opposed)
	var is_opposed_location = func(loc: Location) -> bool:
		if not is_instance_valid(loc): return false
		if loc.danger: return true
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

static func get_active_tasks(task_manager: TaskManager, faction: int = GameConstants.INVALID_INDEX) -> Array[Task]:
	if not is_instance_valid(task_manager):
		return []

	var active_objective: Objective = task_manager.get_active_objective()
	if not active_objective or not active_objective.current_stage:
		return []

	var tasks: Array[Task] = []
	for task in active_objective.current_stage.active_tasks:
		if is_instance_valid(task) and task.status == 1: # Task.Status.ACTIVE
			if faction == GameConstants.INVALID_INDEX or task.owning_faction == faction:
				tasks.append(task)
	return tasks

## Gets all tasks immediately available at a coordinate.
static func get_immediate_tasks(unit: Unit, coord: Vector2i, task_manager: TaskManager) -> Array[Task]:
	if not is_instance_valid(task_manager):
		return []

	var faction: int = unit.faction if is_instance_valid(unit) else GameConstants.INVALID_INDEX
	var active_tasks := get_active_tasks(task_manager, faction)
	var immediate: Array[Task] = []

	for task in active_tasks:
		var is_relevant_type := (
			task.event_type == GameConstants.TaskEvents.EXPLORE or
			task.event_type == GameConstants.TaskEvents.VISIT or
			task.event_type == GameConstants.TaskEvents.GATHER or
			task.event_type == GameConstants.TaskEvents.TRAPPED or
			task.event_type == GameConstants.TaskEvents.INTERACT
		)

		if not is_relevant_type:
			continue

		var target_id := ""
		var location := task_manager.get_location_at(coord)
		if location != null:
			target_id = TaskManager.resolve_target_id(location)
		else:
			var loot_node := task_manager.get_loot_at(coord)
			if loot_node != null:
				target_id = TaskManager.resolve_target_id(loot_node)

		var matches := false

		# Direct coordinate match
		if task.target_coord != GameConstants.INVALID_COORD and task.target_coord == coord:
			matches = true
		# ID match at this coordinate
		elif not task.target_id.is_empty() and not target_id.is_empty() and task.target_id == target_id:
			matches = true

		if matches:
			if is_instance_valid(unit) and task.can_be_worked_on_by(unit, coord):
				immediate.append(task)

	return immediate

static func get_categorized_location_tasks(unit: Unit, action_origin: Vector2i, reachable_lookup: Dictionary, task_manager: TaskManager) -> Dictionary:
	var result := {
		"immediate_explore": [] as Array[Task],
		"immediate_visit": [] as Array[Task],
		"reachable_explore": [] as Array[Task],
		"reachable_visit": [] as Array[Task]
	}

	if not is_instance_valid(task_manager):
		return result

	var faction: int = unit.faction if is_instance_valid(unit) else GameConstants.INVALID_INDEX
	var active_tasks := get_active_tasks(task_manager, faction)
	for task in active_tasks:
		if task.target_kind != GameConstants.Tasks.KIND_LOCATION:
			continue

		var target_coord: Vector2i = task.target_coord
		if target_coord == GameConstants.INVALID_COORD:
			if not task.target_id.is_empty():
				# Try to resolve coordinate from ID
				for loc in task_manager.get_all_locations():
					if TaskManager.resolve_target_id(loc) == task.target_id:
						target_coord = loc.get_grid_location()
						break

			if target_coord == GameConstants.INVALID_COORD:
				continue

		var loc := task_manager.get_location_at(target_coord)
		if loc == null:
			continue

		# Verify ID matches to prevent "impossible" actions if multiple locations exist (or for ID-locked tasks)
		if not task.target_id.is_empty():
			var resolved_id = TaskManager.resolve_target_id(loc)
			if task.target_id != resolved_id:
				continue

		var is_opposed: bool = (task.event_type == GameConstants.TaskEvents.EXPLORE or task.event_type == GameConstants.TaskEvents.INTERACT or task.is_opposed)
		# Even if the task says it's opposed, if the location has no willpower left, it's a visit.
		if is_opposed and loc.willpower <= 0:
			is_opposed = false

		if target_coord == action_origin:
			if is_opposed:
				result.immediate_explore.append(task)
			else:
				result.immediate_visit.append(task)
		elif reachable_lookup.has(target_coord):
			if is_opposed:
				result.reachable_explore.append(task)
			else:
				result.reachable_visit.append(task)

	return result


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

static func _get_tasks_nearby(center: Vector2i, radius: float, task_manager: TaskManager, faction: int, axis: int = TileSet.TILE_OFFSET_AXIS_VERTICAL) -> Array[Task]:
	var results: Array[Task] = []
	for task in get_active_tasks(task_manager, faction):
		if task.target_coord != GameConstants.INVALID_COORD:
			if HexLib.get_distance(center, task.target_coord, axis) <= radius:
				results.append(task)
	return results

static func _get_tasks_reachable(lookup: Dictionary, task_manager: TaskManager, faction: int) -> Array[Task]:
	var results: Array[Task] = []
	for task in get_active_tasks(task_manager, faction):
		if task.target_coord != GameConstants.INVALID_COORD and lookup.has(task.target_coord):
			results.append(task)
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


static func _build_target_to_task(targets: Array, task_manager: TaskManager, faction: int) -> Dictionary:
	var result := {}
	if not is_instance_valid(task_manager): return result
	var active_tasks := get_active_tasks(task_manager, faction)
	for target in targets:
		if not is_instance_valid(target): continue
		var targ := target as Target
		if not targ: continue
		var tid := TaskManager.resolve_target_id(targ)
		var coord: Vector2i = targ.get_grid_location()
		for t in active_tasks:
			if (not t.target_id.is_empty() and t.target_id == tid) or \
			   (t.target_coord != GameConstants.INVALID_COORD and t.target_coord == coord):
				result[target] = t.id
				break
	return result

class_name UnitQueryService
extends RefCounted

## Component responsible for querying units and targets based on various criteria.
##
## This component handles:
## - Range-based queries (units, goals)
## - Faction filtering
## - Adjacent unit detection
## - Distance calculations
## - Morale-based filtering

var _unit # Unit (type hint removed to avoid circular dependency)

func _init(unit: Unit) -> void:
	_unit = unit

## Checks if there are any units within detection range
func has_nearby_units(units: Array, detection_range: float) -> bool:
	return not get_units_in_range(units, detection_range).is_empty()

## Gets all units within the specified range
func get_units_in_range(units: Array, detection_range: float) -> Array:
	return _collect_targets_in_range(units, detection_range, func(t): return t is Unit)

## Gets all adjacent units (within 1.5 grid units)
func get_adjacent_units(units: Array, adjacency_range: float = 1.5) -> Array:
	return _collect_targets_in_range(units, adjacency_range, func(t): return t is Unit)

## Gets units in range filtered by faction
func get_units_in_range_by_faction(units: Array, detection_range: float, target_faction: Unit.Faction) -> Array:
	return _collect_targets_in_range(
		units,
		detection_range,
		func(target: Target) -> bool:
			return target is Unit and target.faction == target_faction
	)

## Gets units in range that don't have full morale
func get_units_in_range_without_full_morale(units: Array, detection_range: float) -> Array:
	return _collect_targets_in_range(
		units,
		detection_range,
		func(target: Target) -> bool:
			return target is Unit and not target.is_at_full_morale()
	)

## Lists all goals within the specified detection range
func list_goals_in_range(goals: Array, detection_range: float) -> Array:
	var result: Array = []
	for goal in goals:
		if goal == null:
			continue
		if not goal is Node2D:
			continue
		if _unit.global_position.distance_to(goal.global_position) <= detection_range:
			result.append(goal)
	return result

## Private: Collects targets in range with optional filtering
func _collect_targets_in_range(targets: Array, detection_range: float, filter: Callable = Callable()) -> Array:
	var result: Array = []
	for other in targets:
		if other == null or other == _unit:
			continue
		if not (other is Target):
			continue

		var dist: int = _unit.distance_to_target(other)

		if dist > detection_range:
			continue

		if not filter.is_null() and not filter.call(other):
			continue
		result.append(other)
	return result

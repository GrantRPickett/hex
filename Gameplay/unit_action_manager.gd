class_name UnitActionManager
extends RefCounted

const HexNavigator := preload("res://Gameplay/hex_navigator.gd")
const ActionAvailabilityService := preload("res://Gameplay/action_availability_service.gd")
const CombatActionCalculator := preload("res://Gameplay/combat_action_calculator.gd")
const GoalActionProvider := preload("res://Gameplay/goal_action_provider.gd")
const LootActionProvider := preload("res://Gameplay/loot_action_provider.gd")

## Checks if a unit is completely stuck (cannot move or act on current/adjacent spaces)
static func is_unit_stuck(unit: Unit, terrain_map, unit_manager: UnitManager) -> bool:
	var availability_service = ActionAvailabilityService.new()
	return availability_service.is_unit_stuck(unit, terrain_map, unit_manager)


## Returns array of available actions for a unit
static func get_available_actions(unit: Unit, terrain_map, unit_manager: UnitManager) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []

	if not is_instance_valid(unit) or unit.willpower <= 0 or unit_manager == null:
		return actions

	var unit_index := unit_manager.get_unit_index(unit)

	var movement_origin := _get_movement_origin(unit, unit_manager, unit_index)
	var action_origin := _get_action_origin(unit, movement_origin)
	var axis := _get_grid_axis(unit)

	var reach_state := _calculate_reachable_state(unit, terrain_map, unit_manager, unit_index, movement_origin, action_origin)
	var reachable_coords: Array[Vector2i] = reach_state.coords
	var reachable_lookup: Dictionary = reach_state.lookup
	var reachable_move_spaces: int = reach_state.move_spaces

	_append_move_action(actions, reachable_move_spaces)

	if unit.has_action_available():
		_append_combat_actions(actions, unit, unit_manager, reachable_coords, axis)

	_append_goal_action(actions, unit, action_origin)
	_append_loot_action(actions, unit, action_origin, reachable_coords, reachable_lookup)
	_append_wait_action(actions)

	return actions

static func _get_movement_origin(unit: Unit, unit_manager: UnitManager, unit_index: int) -> Vector2i:
	var movement_origin := unit.get_grid_location()
	if unit_manager:
		var manager_coord := unit_manager.get_coord(unit_index)
		if manager_coord != Vector2i(-999, -999):
			movement_origin = manager_coord
	return movement_origin

static func _get_action_origin(unit: Unit, movement_origin: Vector2i) -> Vector2i:
	if unit.has_tentative_move():
		return unit.get_tentative_grid_coord()
	return movement_origin

static func _get_grid_axis(unit: Unit) -> int:
	if unit.grid_map and unit.grid_map.tile_set:
		return unit.grid_map.tile_set.tile_offset_axis
	return TileSet.TILE_OFFSET_AXIS_VERTICAL

static func _calculate_reachable_state(unit: Unit, terrain_map, unit_manager: UnitManager, unit_index: int, movement_origin: Vector2i, action_origin: Vector2i) -> Dictionary:
	var reachable_coords: Array[Vector2i] = []
	var reachable_lookup := {}
	reachable_coords.append(action_origin)
	reachable_lookup[action_origin] = true
	var reachable_move_spaces := 0

	if unit.has_move_available() and terrain_map:
		var movement_range = unit.compute_movement_range(movement_origin, terrain_map)
		if not movement_range.is_empty():
			for coord in movement_range.keys():
				var coord_v2: Vector2i = coord
				if not reachable_lookup.has(coord_v2):
					reachable_coords.append(coord_v2)
					reachable_lookup[coord_v2] = true
				if not unit_manager.is_occupied(coord_v2, unit_index):
					reachable_move_spaces += 1

	return {
		"coords": reachable_coords,
		"lookup": reachable_lookup,
		"move_spaces": reachable_move_spaces
	}

static func _append_move_action(actions: Array[Dictionary], reachable_move_spaces: int) -> void:
	if reachable_move_spaces > 0:
		actions.append({
			"type": "move",
			"label": "Move (%d spaces)" % reachable_move_spaces,
			"available": true
		})

static func _append_combat_actions(actions: Array[Dictionary], unit: Unit, unit_manager: UnitManager, reachable_coords: Array[Vector2i], axis: int) -> void:
	var calculator = CombatActionCalculator.new()
	calculator.append_combat_actions(actions, unit, unit_manager, reachable_coords, axis)

static func _append_goal_action(actions: Array[Dictionary], unit: Unit, action_origin: Vector2i) -> void:
	var provider = GoalActionProvider.new()
	provider.append_goal_action(actions, unit, action_origin)

static func _append_loot_action(actions: Array[Dictionary], unit: Unit, action_origin: Vector2i, reachable_coords: Array[Vector2i], reachable_lookup: Dictionary) -> void:
	var provider = LootActionProvider.new()
	provider.append_loot_action(actions, unit, action_origin, reachable_coords, reachable_lookup)

static func _append_wait_action(actions: Array[Dictionary]) -> void:
	actions.append({
		"type": "wait",
		"label": "Wait / End Turn",
		"available": true
	})

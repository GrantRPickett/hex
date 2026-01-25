class_name UnitActionManager
extends RefCounted

const HexNavigator := preload("res://Gameplay/hex_navigator.gd")
const ActionAvailabilityService := preload("res://Gameplay/action_availability_service.gd")
const ReachableStateCalculator := preload("res://Gameplay/reachable_state_calculator.gd")
const CombatActionCalculator := preload("res://Gameplay/combat_action_calculator.gd")
const GoalActionProvider := preload("res://Gameplay/goal_action_provider.gd")
const LootActionProvider := preload("res://Gameplay/loot_action_provider.gd")

static func _get_adjacent_coords(coord: Vector2i, axis: int) -> Array[Vector2i]:
	var adjacent_coords: Array[Vector2i] = []
	var directions: Array[Vector2i] = []
	# Directions for flat-top hexes (TILE_OFFSET_AXIS_VERTICAL)
	# https://www.redblobgames.com/grids/hexagons/#neighbors-axial
	if axis == TileSet.TILE_OFFSET_AXIS_VERTICAL:
		directions = [
			Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1),
			Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1)
		]
	# Directions for pointy-top hexes (TILE_OFFSET_AXIS_HORIZONTAL)
	# https://www.redblobgames.com/grids/hexagons/#neighbors-axial
	else:
		directions = [
			Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0),
			Vector2i(0, -1), Vector2i(-1, 1), Vector2i(1, -1)
		]
	for dir in directions:
		adjacent_coords.append(coord + dir)
	return adjacent_coords


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
	var axis := _get_grid_axis(unit)

	var reach_state := ReachableStateCalculator.calculate(unit, terrain_map, unit_manager, unit_index)
	var action_origin: Vector2i = reach_state.action_origin
	var reachable_coords: Array[Vector2i] = reach_state.coords
	var reachable_lookup: Dictionary = reach_state.lookup
	var reachable_move_spaces: int = reach_state.move_spaces

	_append_move_action(actions, reachable_move_spaces)

	if unit.has_action_available():
		_append_combat_actions(actions, unit, unit_manager, reachable_coords, axis)
		_append_goal_action(actions, unit, action_origin)
		_append_loot_action(actions, unit, action_origin, reachable_coords, reachable_lookup)
		#_append_move_and_interact_actions(actions, unit, terrain_map, unit_manager, reachable_lookup, axis)

	_append_wait_action(actions)

	return actions


static func _get_grid_axis(unit: Unit) -> int:
	if unit.grid_map and unit.grid_map.tile_set:
		return unit.grid_map.tile_set.tile_offset_axis
	return TileSet.TILE_OFFSET_AXIS_VERTICAL


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

static func _append_move_and_interact_actions(actions: Array[Dictionary], unit: Unit, terrain_map, unit_manager: UnitManager, reachable_lookup: Dictionary, axis: int) -> void:
	if not unit.has_action_available():
		return

	var current_unit_index = unit_manager.get_unit_index(unit)

	# --- Handle Enemies (Move & Attack) ---
	var all_units = unit_manager.get_all_units()
	var interaction_ap_cost_attack = 1 # Assuming 1 AP for basic attack

	for i in range(all_units.size()):
		var target_unit = all_units[i]
		if not is_instance_valid(target_unit) or target_unit == unit or target_unit.willpower <= 0:
			continue
		# Only suggest attacking hostile units
		if unit_manager.is_player_controlled(i) == unit_manager.is_player_controlled(current_unit_index):
			continue

		var target_coord = target_unit.get_grid_location()
		var adjacent_to_target_coords = _get_adjacent_coords(target_coord, axis)

		if not unit.has_action_available_with_cost(interaction_ap_cost_attack):
			continue

		for adj_coord in adjacent_to_target_coords:
			if reachable_lookup.has(adj_coord):
				var move_cost_data = reachable_lookup[adj_coord]
				var move_cost = move_cost_data.cost # Movement cost to reach adj_coord

				# Check if unit can afford both move and action
				if unit.get_remaining_movement_points() >= move_cost:
					actions.append({
						"type": "move_and_interact",
						"label": "Move & Attack %s (M%d/A%d)" % [target_unit.unit_name, move_cost, interaction_ap_cost_attack],
						"available": true,
						"target_move_coord": adj_coord, # The coord to move to
						"interact_target_uid": i, # Unit index
						"interact_target_coord": target_coord, # Actual target's coord
						"interact_action_type": "attack",
						"movement_cost": move_cost,
						"action_cost": interaction_ap_cost_attack,
						"interact_target_type": "unit"
					})

	# --- Handle Loot (Move & Loot) ---
	var loot_manager = unit.get_loot_manager()
	if loot_manager:
		var all_loot_items = loot_manager.get_all_loot()
		var interaction_ap_cost_loot = 0 # Looting might be free, or cost 1 AP

		for loot_item in all_loot_items:
			if not is_instance_valid(loot_item):
				continue

			var loot_coord = loot_item.get_grid_location()
			var adjacent_to_loot_coords = _get_adjacent_coords(loot_coord, axis)

			# If looting costs AP, check here:
			if interaction_ap_cost_loot > 0 and not unit.has_action_available_with_cost(interaction_ap_cost_loot):
				continue

			for adj_coord in adjacent_to_loot_coords:
				if reachable_lookup.has(adj_coord):
					var move_cost_data = reachable_lookup[adj_coord]
					var move_cost = move_cost_data.cost

					if unit.get_remaining_movement_points() >= move_cost:
						actions.append({
							"type": "move_and_interact",
							"label": "Move & Loot (%d MP/A%d)" % [move_cost, interaction_ap_cost_loot],
							"available": true,
							"target_move_coord": adj_coord,
							"interact_target_coord": loot_coord, # Using coord as UID for loot
							"interact_action_type": "loot",
							"movement_cost": move_cost,
							"action_cost": interaction_ap_cost_loot,
							"interact_target_type": "loot"
						})

	# --- Handle Goals (Move & Work on Goal) ---
	var goal_manager = unit.get_goal_manager()
	if goal_manager:
		var all_goals = goal_manager.get_all_goals()
		var interaction_ap_cost_goal = 1 # Assuming working on a goal costs 1 AP

		for goal_item in all_goals:
			if not is_instance_valid(goal_item):
				continue

			var goal_coord = goal_item.get_grid_location()
			var adjacent_to_goal_coords = _get_adjacent_coords(goal_coord, axis)

			if not unit.has_action_available_with_cost(interaction_ap_cost_goal):
				continue

			for adj_coord in adjacent_to_goal_coords:
				if reachable_lookup.has(adj_coord):
					var move_cost_data = reachable_lookup[adj_coord]
					var move_cost = move_cost_data.cost

					if unit.get_remaining_movement_points() >= move_cost:
						actions.append({
							"type": "move_and_interact",
							"label": "Move & Goal (%d MP/A%d)" % [move_cost, interaction_ap_cost_goal],
							"available": true,
							"target_move_coord": adj_coord,
							"interact_target_coord": goal_coord, # Using coord as UID for goal
							"interact_action_type": "goal",
							"movement_cost": move_cost,
							"action_cost": interaction_ap_cost_goal,
							"interact_target_type": "goal"
						})


static func _append_wait_action(actions: Array[Dictionary]) -> void:
	actions.append({
		"type": "wait",
		"label": "Wait / End Turn",
		"available": true
	})

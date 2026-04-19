class_name MoveAndInteractProvider
extends RefCounted

const PerformInteractionCommand = preload("res://Gameplay/commands/perform_interaction_command.gd")

## Top-level entry point for appending all move-and-interact actions for a unit.
static func append_move_and_interact_actions(actions: Array[PlayerAction], unit: Unit, reach: ReachableState, axis: int) -> void:
	if not unit.res.has_action_available(): return
	var unit_manager = unit.get_unit_manager()
	var unit_index: int = unit_manager.get_unit_index(unit)
	if unit_index == GameConstants.INVALID_INDEX or not unit.movement: return
	var remaining_move := unit.movement.get_remaining_movement_points()
	if remaining_move <= 0: return

	_append_unit_interactions(actions, unit, reach, axis, remaining_move)
	_append_loot_interactions(actions, unit, reach, remaining_move)
	_append_location_interactions(actions, unit, reach, remaining_move)

## Builds a PlayerAction that includes both a move path and an interaction command.
static func build_specialized_action(unit: Unit, target: Target, move_coord: Vector2i, move_cost: int, interaction_type: String, action_id: String, extra_params: Dictionary = {}) -> PlayerAction:
	var unit_manager = unit.get_unit_manager()
	var unit_index = unit_manager.get_unit_index(unit)
	var terrain_map = unit_manager.get_terrain_map()

	# 1. Build the movement part
	var action = _build_move_action(unit, terrain_map, unit_index, move_coord, move_cost)
	action.action_id = action_id
	action.target_object = target

	# 2. Setup the interaction command
	var target_coord: Vector2i = target.get_grid_location() if target.has_method("get_grid_location") else move_coord
	var final_params = extra_params.duplicate()
	if target.has_method("get_target_id"):
		final_params["target_id"] = target.get_target_id()

	action.command_id = GameConstants.ActionType.INTERACT
	action.command_payload = PerformInteractionCommand.create_payload(unit_index, target_coord, interaction_type, final_params)
	action.command_payload[GameConstants.Payload.TARGET_MOVE_COORD] = move_coord

	return action

# --- Internal Appenders ---

static func _append_unit_interactions(actions: Array[PlayerAction], unit: Unit, reach: ReachableState, axis: int, remaining_move: int) -> void:
	var all_targets = unit.query.get_all_units_categorized()
	var split = TargetDiscoveryService.split_units_for_combat(all_targets["enemies"])

	_process_interaction_list(actions, unit, split["fight"], GameConstants.Activity.FIGHT, GameConstants.Activity.FIGHT, reach, axis, remaining_move, true)
	_process_interaction_list(actions, unit, split["convince"], GameConstants.Activity.CONVINCE, GameConstants.Activity.CONVINCE, reach, axis, remaining_move, true)

static func _append_loot_interactions(actions: Array[PlayerAction], unit: Unit, reach: ReachableState, remaining_move: int) -> void:
	var loot_manager = unit.get_loot_manager()
	if loot_manager == null: return

	var potential_targets : Array = TargetDiscoveryService.get_targets_by_type("loot")
	var loot_items: Array = []
	for t in potential_targets:
		loot_items.append(t.item)

	_process_interaction_list(actions, unit, loot_items, "", "", reach, -1, remaining_move, false)

static func _append_location_interactions(actions: Array[PlayerAction], unit: Unit, reach: ReachableState, remaining_move: int) -> void:
	var loc_res := TargetDiscoveryService.get_categorized_locations(unit, reach)
	var locations: Array = []
	# For simplicity, we process all reachable locations.
	var sx = loc_res.split_locations
	locations.append_array(sx.reachable_opposed)
	locations.append_array(sx.reachable_unopposed)

	_process_interaction_list(actions, unit, locations, "", "", reach, -1, remaining_move, false)

# --- Generic Processor ---

static func _process_interaction_list(actions: Array[PlayerAction], unit: Unit, targets: Array, forced_interaction: String, forced_action_id: String, reach: ReachableState, axis: int, remaining_move: int, move_adjacent: bool) -> void:
	var unit_manager = unit.get_unit_manager()
	var unit_index = unit_manager.get_unit_index(unit)

	for target in targets:
		if not is_instance_valid(target) or target == unit: continue
		if target is Unit and target.willpower <= 0: continue

		var target_coord: Vector2i = target.get_grid_location()
		var best_coord: Vector2i = GameConstants.INVALID_COORD
		var best_cost: int = -1

		if move_adjacent:
			var near_coords = _get_near_coords(target_coord, axis)
			for adj_coord in near_coords:
				var cost: int = _resolve_move_cost(reach, adj_coord, remaining_move)
				if cost < 0: continue
				if unit_manager.is_occupied(adj_coord, unit_index): continue

				if best_coord == GameConstants.INVALID_COORD or cost < best_cost:
					best_cost = cost
					best_coord = adj_coord
		else:
			var cost: int = _resolve_move_cost(reach, target_coord, remaining_move)
			if cost >= 0 and not unit_manager.is_occupied(target_coord, unit_index):
				best_cost = cost
				best_coord = target_coord

		if best_coord != GameConstants.INVALID_COORD:
			var interaction_type = forced_interaction
			var action_id = forced_action_id
			var extra = {}

			if interaction_type.is_empty() and target.has_method("get_interaction_type"):
				interaction_type = target.get_interaction_type()

			if action_id.is_empty():
				var is_opposed = target.is_opposed if "is_opposed" in target else (target.is_trapped if "is_trapped" in target else false)
				if target is Loot:
					action_id = GameConstants.Activity.TRAPPED if is_opposed else GameConstants.Activity.GATHER
					if interaction_type.is_empty(): interaction_type = action_id
				elif target is Location:
					action_id = GameConstants.Activity.EXPLORE if is_opposed else GameConstants.Activity.VISIT
					if interaction_type.is_empty(): interaction_type = action_id

			if interaction_type == GameConstants.Activity.FIGHT:
				extra["attribute_index"] = _select_best_attack_attribute(unit)

			# Ensure interaction_type is always passed in extra to avoid null context
			if not extra.has("type"):
				extra["type"] = interaction_type

			actions.append(build_specialized_action(unit, target, best_coord, best_cost, interaction_type, action_id, extra))
# --- Helpers ---

static func _get_near_coords(coord: Vector2i, axis: int) -> Array[Vector2i]:
	var directions: Array[Vector2i] = []
	if axis == TileSet.TILE_OFFSET_AXIS_VERTICAL:
		directions.assign([Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1)])
	else:
		directions.assign([Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, 1), Vector2i(1, -1)])

	var near_coords: Array[Vector2i] = []
	for dir in directions:
		near_coords.append(coord + dir)
	return near_coords

static func _resolve_move_cost(reach: ReachableState, coord: Vector2i, remaining_move: int) -> int:
	if reach == null or not reach.lookup.has(coord): return -1
	var data = reach.lookup[coord]
	var cost: int = int(data.get("cost", 0)) if data is Dictionary else int(data)
	return cost if cost <= remaining_move else -1

static func _resolve_move_origin(unit: Unit, unit_manager: UnitManager, unit_index: int) -> Vector2i:
	var start_coord: Vector2i = unit_manager.get_coord(unit_index) if unit_manager else GameConstants.INVALID_COORD
	if unit.movement and unit.movement.has_tentative_move():
		var committed: Vector2i = unit.movement.get_start_of_turn_grid_coord()
		if committed != Vector2i.MAX and committed != GameConstants.INVALID_COORD:
			start_coord = committed
	if start_coord == GameConstants.INVALID_COORD or start_coord == Vector2i.MAX:
		start_coord = unit.get_grid_location()
	return start_coord

static func _build_move_action(unit: Unit, terrain_map: TerrainMap, unit_idx: int, move_coord: Vector2i, movement_cost: int) -> PlayerAction:
	var action: PlayerAction = PlayerAction.create(GameConstants.ActionType.MOVE_AND_INTERACT)
	action.move_cost = movement_cost
	if unit.movement:
		action.path = unit.movement.get_path_to_coord(move_coord, terrain_map, _resolve_move_origin(unit, unit.get_unit_manager(), unit_idx), unit.movement.get_remaining_movement_points())
	else:
		action.path = []
	return action

static func _select_best_attack_attribute(unit: Unit) -> int:
	var best_index := 0
	var best_value := -INF
	for attr_idx: GameConstants.AttributeIndex in GameConstants.COMBAT_ATTRIBUTE_INDICES:
		var val := unit.get_attribute(attr_idx)
		if val > best_value:
			best_value = val
			best_index = attr_idx
	return best_index

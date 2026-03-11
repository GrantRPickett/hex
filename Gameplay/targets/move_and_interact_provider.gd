class_name MoveAndInteractProvider
extends RefCounted

const _CombatDiscovery = preload("res://Gameplay/targets/discovery/combat_discovery.gd")
const _LootDiscovery = preload("res://Gameplay/targets/discovery/loot_discovery.gd")  
const _TaskDiscovery = preload("res://Gameplay/targets/discovery/task_discovery.gd")  
const _ConvinceDiscovery = preload("res://Gameplay/targets/discovery/convince_discovery.gd")

static func append_move_and_interact_actions(actions: Array[UnitAction], unit: Unit, terrain_map, unit_manager: UnitManager, reachable_lookup: Dictionary, axis: int) -> void:
	if not unit.res.has_action_available(): return
	var unit_index = unit_manager.get_unit_index(unit)
	if unit_index == -1 or not unit.movement: return
	var remaining_move := unit.movement.get_remaining_movement_points()
	if remaining_move <= 0: return

	_append_move_and_attack_actions(actions, unit, terrain_map, unit_manager, unit_index, reachable_lookup, axis, remaining_move)
	_append_move_and_loot_actions(actions, unit, terrain_map, unit_manager, unit_index, reachable_lookup, remaining_move)
	_append_move_and_task_actions(actions, unit, terrain_map, unit_manager, unit_index, reachable_lookup, remaining_move)

static func _append_move_and_attack_actions(actions: Array[UnitAction], unit: Unit, terrain_map, unit_manager: UnitManager, unit_index: int, reachable_lookup: Dictionary, axis: int, remaining_move: int) -> void:
	var all_targets = _CombatDiscovery.get_all_targets(unit)
	var split = _ConvinceDiscovery.split_targets(all_targets["enemies"])

	for target in split["fight"]:
		_process_move_and_unit_interaction(actions, unit, target, GameConstants.ActionIds.UNIT_OPPOSED, UnitAction.Type.ATTACK, terrain_map, unit_manager, unit_index, reachable_lookup, axis, remaining_move)
		break

	for target in split["convince"]:
		_process_move_and_unit_interaction(actions, unit, target, GameConstants.ActionIds.UNIT_OPPOSED, UnitAction.Type.CONVINCE, terrain_map, unit_manager, unit_index, reachable_lookup, axis, remaining_move)
		break

static func _process_move_and_unit_interaction(actions: Array[UnitAction], unit: Unit, target: Unit, action_role_id: String, action_type: UnitAction.Type, terrain_map, unit_manager: UnitManager, unit_index: int, reachable_lookup: Dictionary, axis: int, remaining_move: int) -> void:
	if not is_instance_valid(target) or target == unit or target.willpower <= 0: return
	var target_index = unit_manager.get_unit_index(target)
	if target_index == -1: return

	var target_coord = target.get_grid_location()
	var adjacent_coords = _get_adjacent_coords(target_coord, axis)
	var best_coord := GameConstants.INVALID_COORD
	var best_cost := INF

	for adj_coord in adjacent_coords:
		var move_cost = int(_resolve_move_cost(reachable_lookup, adj_coord, remaining_move))
		if move_cost < 0: continue
		if not _has_unblocked_path(unit, terrain_map, unit_manager, unit_index, adj_coord, remaining_move): continue
		if move_cost < best_cost:
			best_cost = move_cost
			best_coord = adj_coord

	if best_coord != GameConstants.INVALID_COORD:
		var action = _build_move_and_interact_action(best_coord, action_type, int(best_cost), 1)
		action.interact_target_uid = target_index
		action.interact_target_coord = target_coord
		action.action_id = action_role_id
		action.target = target

		if action_type == UnitAction.Type.ATTACK:
			action.attribute_index = _select_best_attack_attribute(unit)  
		actions.append(action)

static func _append_move_and_loot_actions(actions: Array[UnitAction], unit: Unit, terrain_map, unit_manager: UnitManager, unit_index: int, reachable_lookup: Dictionary, remaining_move: int) -> void:
	var loot_manager = unit.get_loot_manager()
	if loot_manager == null: return

	var potential_targets = _LootDiscovery.get_potential_loot_targets(unit, loot_manager)
	for target in potential_targets:
		var loot_item = target.item
		var loot_coord = target.coord
		var move_cost = _resolve_move_cost(reachable_lookup, loot_coord, remaining_move)
		if move_cost < 0: continue
		if not _has_unblocked_path(unit, terrain_map, unit_manager, unit_index, loot_coord, remaining_move): continue

		var is_trapped: bool = "is_trapped" in loot_item and bool(loot_item.is_trapped)
		var action_type = UnitAction.Type.TRAPPED if is_trapped else UnitAction.Type.GATHER
		var action_cost = 1 if is_trapped else 0
		var interaction_id = GameConstants.ActionIds.ITEM_OPPOSED if is_trapped else GameConstants.ActionIds.ITEM_UNOPPOSED

		var action = _build_move_and_interact_action(loot_coord, action_type, move_cost, action_cost)
		action.interact_target_coord = loot_coord
		action.target = loot_item
		action.action_id = interaction_id
		actions.append(action)

static func _append_move_and_task_actions(actions: Array[UnitAction], unit: Unit, terrain_map, unit_manager: UnitManager, unit_index: int, reachable_lookup: Dictionary, remaining_move: int) -> void:
	var task_manager = unit.get_task_manager()
	if task_manager == null: return

	var active_tasks = _TaskDiscovery.get_active_tasks(task_manager)
	for task in active_tasks:
		var target_coord: Vector2i = task.target_coord
		if target_coord == GameConstants.INVALID_COORD or not reachable_lookup.has(target_coord): continue

		if not task.target_id.is_empty():
			var location = task_manager.get_location_at(target_coord)     
			if location == null or task.target_id != location.loc_name: continue

		var move_cost = _resolve_move_cost(reachable_lookup, target_coord, remaining_move)
		if move_cost <= 0: continue
		if not _has_unblocked_path(unit, terrain_map, unit_manager, unit_index, target_coord, remaining_move): continue

		var is_explore = (task.event_type == GameConstants.Interactions.EXPLORE or task.event_type == GameConstants.Commands.INTERACT)
		var action_type = UnitAction.Type.EXPLORE if is_explore else UnitAction.Type.VISIT
		var interaction_id = GameConstants.ActionIds.LOCATION_OPPOSED if is_explore else GameConstants.ActionIds.LOCATION_UNOPPOSED

		var action = _build_move_and_interact_action(target_coord, action_type, move_cost, 1)
		action.interact_target_coord = target_coord
		action.task_id = String(task.id)
		action.needs_attribute = is_explore
		action.action_id = interaction_id
		action.target = task_manager.get_location_at(target_coord)
		actions.append(action)
		break

# Helpers

static func _get_adjacent_coords(coord: Vector2i, axis: int) -> Array[Vector2i]:      
	var adjacent_coords: Array[Vector2i] = []
	var directions: Array[Vector2i] = []
	if axis == TileSet.TILE_OFFSET_AXIS_VERTICAL:
		directions.assign([Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1)])
	else:
		directions.assign([Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, 1), Vector2i(1, -1)])

	for dir in directions:
		adjacent_coords.append(coord + dir)
	return adjacent_coords

static func _resolve_move_cost(reachable_lookup: Dictionary, coord: Vector2i, remaining_move: int) -> int:
	if not reachable_lookup.has(coord): return -1
	var data = reachable_lookup[coord]
	var cost = int(data.get("cost", 0)) if data is Dictionary else int(data)      
	return cost if cost <= remaining_move else -1

static func _has_unblocked_path(unit: Unit, terrain_map, unit_manager: UnitManager, unit_index: int, target_coord: Vector2i, remaining_move: int) -> bool:
	if terrain_map == null or unit_manager == null: return true
	if not is_instance_valid(unit) or target_coord == GameConstants.INVALID_COORD or remaining_move <= 0: return false
	if unit_manager.is_occupied(target_coord, unit_index): return false

	var start_coord = unit_manager.get_coord(unit_index)
	if unit.movement.has_tentative_move():
		var committed = unit.movement.get_start_of_turn_grid_coord()
		if committed != Vector2i.MAX and committed != GameConstants.INVALID_COORD: start_coord = committed
	if start_coord == GameConstants.INVALID_COORD or start_coord == Vector2i.MAX: 
		start_coord = unit.get_grid_location()

	if start_coord == target_coord: return true
	return not unit.movement.get_path_to_coord(target_coord, terrain_map, start_coord, remaining_move).is_empty()

static func _build_move_and_interact_action(move_coord: Vector2i, interact_action_type: UnitAction.Type, movement_cost: int, action_cost: int) -> UnitAction:
	var action = UnitAction.new(UnitAction.Type.MOVE_AND_INTERACT)
	action.action_id = GameConstants.ActionIds.MOVE_AND_INTERACT
	action.target_move_coord = move_coord
	action.interact_action_type = interact_action_type
	action.movement_cost = movement_cost
	action.action_cost = action_cost
	return action

static func _select_best_attack_attribute(unit: Unit) -> int:
	var attrs = unit.inv.get_attributes() if unit.inv else null
	if attrs == null: return 0
	var best_index := 0
	var best_value := -INF
	for i in range(Target.COMBAT_ATTRIBUTE_NAMES.size()):
		var val = attrs.get_attribute(Target.COMBAT_ATTRIBUTE_NAMES[i])       
		if val > best_value:
			best_value = val
			best_index = i
	return best_index

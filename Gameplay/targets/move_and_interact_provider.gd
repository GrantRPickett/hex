class_name MoveAndInteractProvider
extends RefCounted

const AttackUnitCommand = preload("res://Gameplay/commands/attack_unit_command.gd")
const ConvinceUnitCommand = preload("res://Gameplay/commands/convince_unit_command.gd")
const LootCommand = preload("res://Gameplay/commands/loot_command.gd")
const ExploreCommand = preload("res://Gameplay/commands/explore_command.gd")
const VisitCommand = preload("res://Gameplay/commands/visit_command.gd")
const TrappedCommand = preload("res://Gameplay/commands/trapped_command.gd")

static func append_move_and_interact_actions(actions: Array[PlayerAction], unit: Unit, terrain_map, unit_manager: UnitManager, reachable_lookup: Dictionary, axis: int) -> void:
	if not unit.res.has_action_available(): return
	var unit_index: int = unit_manager.get_unit_index(unit)
	if unit_index == GameConstants.INVALID_INDEX or not unit.movement: return
	var remaining_move := unit.movement.get_remaining_movement_points()
	if remaining_move <= 0: return

	_append_move_and_attack_actions(actions, unit, terrain_map, unit_manager, unit_index, reachable_lookup, axis, remaining_move)
	_append_move_and_loot_actions(actions, unit, terrain_map, unit_manager, unit_index, reachable_lookup, remaining_move)
	_append_move_and_task_actions(actions, unit, terrain_map, unit_manager, unit_index, reachable_lookup, remaining_move)

static func _append_move_and_attack_actions(actions: Array[PlayerAction], unit: Unit, terrain_map, unit_manager: UnitManager, unit_index: int, reachable_lookup: Dictionary, axis: int, remaining_move: int) -> void:
	var all_targets = unit.query.get_all_units_categorized()
	var split = TargetDiscoveryService.split_units_for_combat(all_targets["enemies"])

	for target in split["fight"]:
		_process_move_and_unit_interaction(actions, unit, target, GameConstants.ActionIds.UNIT_OPPOSED, GameConstants.ActionType.ATTACK, terrain_map, unit_manager, unit_index, reachable_lookup, axis, remaining_move)

	for target in split["convince"]:
		_process_move_and_unit_interaction(actions, unit, target, GameConstants.ActionIds.UNIT_OPPOSED, GameConstants.ActionType.CONVINCE, terrain_map, unit_manager, unit_index, reachable_lookup, axis, remaining_move)

static func _process_move_and_unit_interaction(actions: Array[PlayerAction], unit: Unit, target: Unit, action_role_id: String, action_type: GameConstants.ActionType, terrain_map, unit_manager: UnitManager, unit_index: int, reachable_lookup: Dictionary, axis: int, remaining_move: int) -> void:
	if not is_instance_valid(target) or target == unit or target.willpower <= 0: return
	var target_index: int = unit_manager.get_unit_index(target)
	if target_index == GameConstants.INVALID_INDEX: return

	var target_coord: Vector2i = target.get_grid_location()
	var near_coords = _get_near_coords(target_coord, axis)
	var best_coord: Vector2i = GameConstants.INVALID_COORD
	var best_cost: float = INF

	for adj_coord in near_coords:
		var move_cost: int = int(_resolve_move_cost(reachable_lookup, adj_coord, remaining_move))
		if move_cost < 0: continue
		if not _has_unblocked_path(unit, terrain_map, unit_manager, unit_index, adj_coord, remaining_move): continue
		if move_cost < best_cost:
			best_cost = move_cost
			best_coord = adj_coord

	if best_coord != GameConstants.INVALID_COORD:
		var action = _build_move_action(unit, terrain_map, unit_index, best_coord, int(best_cost))
		action.action_id = action_role_id
		action.target_object = target

		match action_type:
			GameConstants.ActionType.ATTACK:
				var best_attr = _select_best_attack_attribute(unit)
				action.command_id = GameConstants.Commands.CommandID.ATTACK
				action.command_payload = AttackUnitCommand.create_payload(unit_index, target_index, best_attr)
			GameConstants.ActionType.CONVINCE:
				action.command_id = GameConstants.Commands.CommandID.CONVINCE
				action.command_payload = ConvinceUnitCommand.create_payload(unit_index, target_index)

		actions.append(action)

static func _append_move_and_loot_actions(actions: Array[PlayerAction], unit: Unit, terrain_map, unit_manager: UnitManager, unit_index: int, reachable_lookup: Dictionary, remaining_move: int) -> void:
	var loot_manager = unit.get_loot_manager()
	if loot_manager == null: return

	var potential_targets = TargetDiscoveryService.get_potential_loot_items(unit, loot_manager, null, 100.0)
	for target in potential_targets:
		var loot_item = target.item
		var loot_coord = target.coord
		var move_cost = int(_resolve_move_cost(reachable_lookup, loot_coord, remaining_move))
		if move_cost < 0: continue
		if not _has_unblocked_path(unit, terrain_map, unit_manager, unit_index, loot_coord, remaining_move): continue

		var is_trapped: bool = "is_trapped" in loot_item and bool(loot_item.is_trapped)
		var interaction_id = GameConstants.ActionIds.ITEM_OPPOSED if is_trapped else GameConstants.ActionIds.ITEM_UNOPPOSED

		var action = _build_move_action(unit, terrain_map, unit_index, loot_coord, move_cost)
		action.target_object = loot_item
		action.action_id = interaction_id

		if is_trapped:
			action.command_id = GameConstants.Commands.CommandID.TRAPPED
			# TrappedCommand expects worker_idx and task_id
			# Note: We need a task_id if it exists, otherwise TrappedCommand might fail.
			# But for loot, it's often implicit.
			action.command_payload = TrappedCommand.create_payload(unit_index, loot_item.get("task_id", ""))
		else:
			action.command_id = GameConstants.Commands.CommandID.LOOT
			action.command_payload = LootCommand.create_payload(unit_index, loot_coord)

		actions.append(action)

static func _append_move_and_task_actions(actions: Array[PlayerAction], unit: Unit, terrain_map, unit_manager: UnitManager, unit_index: int, reachable_lookup: Dictionary, remaining_move: int) -> void:
	var task_manager: TaskManager = unit.get_task_manager()
	if task_manager == null: return

	var active_tasks = TargetDiscoveryService.get_active_tasks(task_manager)
	for task in active_tasks:
		var target_coord: Vector2i = task.target_coord
		if target_coord == GameConstants.INVALID_COORD or not reachable_lookup.has(target_coord): continue

		var location: Node = task_manager.get_location_at(target_coord)
		if not task.target_id.is_empty():
			if location == null or task.target_id != location.loc_name: continue

		var move_cost = int(_resolve_move_cost(reachable_lookup, target_coord, remaining_move))
		if move_cost < 0: continue
		if not _has_unblocked_path(unit, terrain_map, unit_manager, unit_index, target_coord, remaining_move): continue

		var is_explore = (task.event_type == GameConstants.Interactions.EXPLORE or task.event_type == GameConstants.Commands.INTERACT)
		var interaction_id = GameConstants.ActionIds.LOCATION_OPPOSED if is_explore else GameConstants.ActionIds.LOCATION_UNOPPOSED

		var action = _build_move_action(unit, terrain_map, unit_index, target_coord, move_cost)
		action.target_object = location
		action.action_id = interaction_id

		if is_explore:
			action.command_id = GameConstants.Commands.CommandID.EXPLORE
			action.command_payload = ExploreCommand.create_payload(unit_index, String(task.id))
		else:
			action.command_id = GameConstants.Commands.CommandID.VISIT
			action.command_payload = VisitCommand.create_payload(unit_index, String(task.id))

		actions.append(action)

# Helpers

static func _get_near_coords(coord: Vector2i, axis: int) -> Array[Vector2i]:
	var near_coords: Array[Vector2i] = []
	var directions: Array[Vector2i] = []
	if axis == TileSet.TILE_OFFSET_AXIS_VERTICAL:
		directions.assign([Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1)])
	else:
		directions.assign([Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, 1), Vector2i(1, -1)])

	for dir in directions:
		near_coords.append(coord + dir)
	return near_coords

static func _resolve_move_cost(reachable_lookup: Dictionary, coord: Vector2i, remaining_move: int) -> int:
	if not reachable_lookup.has(coord): return -1
	var data = reachable_lookup[coord]
	var cost: int = int(data.get("cost", 0)) if data is Dictionary else int(data)
	return cost if cost <= remaining_move else -1

static func _has_unblocked_path(unit: Unit, terrain_map, unit_manager: UnitManager, unit_index: int, target_coord: Vector2i, remaining_move: int) -> bool:
	if terrain_map == null or unit_manager == null: return true
	if not is_instance_valid(unit) or target_coord == GameConstants.INVALID_COORD or remaining_move <= 0: return false
	if unit_manager.is_occupied(target_coord, unit_index): return false

	var start_coord = _resolve_move_origin(unit, unit_manager, unit_index)
	if start_coord == target_coord: return true
	return not unit.movement.get_path_to_coord(target_coord, terrain_map, start_coord, remaining_move).is_empty()

static func _resolve_move_origin(unit: Unit, unit_manager: UnitManager, unit_index: int) -> Vector2i:
	var start_coord: Vector2i = unit_manager.get_coord(unit_index)
	if unit.movement.has_tentative_move():
		var committed: Vector2i = unit.movement.get_start_of_turn_grid_coord()
		if committed != Vector2i.MAX and committed != GameConstants.INVALID_COORD:
			start_coord = committed
	if start_coord == GameConstants.INVALID_COORD or start_coord == Vector2i.MAX:
		start_coord = unit.get_grid_location()
	return start_coord

static func _build_move_action(unit: Unit, terrain_map, unit_idx: int, move_coord: Vector2i, movement_cost: int) -> PlayerAction:
	var action: PlayerAction = PlayerAction.new(GameConstants.ActionType.MOVE_AND_INTERACT)
	action.move_cost = movement_cost
	action.path = unit.movement.get_path_to_coord(move_coord, terrain_map, _resolve_move_origin(unit, unit.get_unit_manager(), unit_idx), unit.movement.get_remaining_movement_points())
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

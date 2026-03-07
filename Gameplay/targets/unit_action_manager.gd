class_name UnitActionManager
extends RefCounted

const _CombatDiscovery = preload("res://Gameplay/targets/discovery/combat_discovery.gd")
const _LootDiscovery = preload("res://Gameplay/targets/discovery/loot_discovery.gd")
const _TaskDiscovery = preload("res://Gameplay/targets/discovery/task_discovery.gd")
const _ConvinceDiscovery = preload("res://Gameplay/targets/discovery/convince_discovery.gd")
const _LocationActionProvider = preload("res://Gameplay/targets/location_action_provider.gd")

static var _dialogue_service: DialogueActionService

static func set_dialogue_service(service: DialogueActionService) -> void:
	print_debug("[UnitActionManager] dialogue service set -> %s" % (str(service) if service else "null"))
	_dialogue_service = service

static func get_dialogue_service() -> DialogueActionService:
	print_debug("[UnitActionManager] get_dialogue_service -> %s" % ("available" if _dialogue_service else "null"))
	return _dialogue_service

static func _get_adjacent_coords(coord: Vector2i, axis: int) -> Array[Vector2i]:
	var adjacent_coords: Array[Vector2i] = []
	var directions: Array[Vector2i] = []
	if axis == TileSet.TILE_OFFSET_AXIS_VERTICAL:
		directions = [
			Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1),
			Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1)
		]
	else:
		directions = [
			Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0),
			Vector2i(0, -1), Vector2i(-1, 1), Vector2i(1, -1)
		]
	for dir in directions:
		adjacent_coords.append(coord + dir)
	return adjacent_coords

static func is_unit_stuck(unit: Unit, terrain_map, unit_manager: UnitManager) -> bool:
	var availability_service = ActionAvailabilityService.new()
	return availability_service.is_unit_stuck(unit, terrain_map, unit_manager)

static func get_available_actions(unit: Unit, terrain_map, unit_manager: UnitManager) -> Array[Dictionary]:
	return _collect_actions(unit, terrain_map, unit_manager, null)

static func get_available_actions_with_weather(unit: Unit, terrain_map, unit_manager: UnitManager, weather_manager) -> Array[Dictionary]:
	return _collect_actions(unit, terrain_map, unit_manager, weather_manager)

static func _collect_actions(unit: Unit, terrain_map, unit_manager: UnitManager, weather_manager) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []

	if not is_instance_valid(unit) or unit.willpower <= 0 or unit_manager == null:
		return actions

	var unit_index := unit_manager.get_unit_index(unit)
	var axis := _get_grid_axis(unit)

	var reach_state := ReachableStateCalculator.calculate(unit, terrain_map, unit_manager, unit_index)
	var action_origin: Vector2i = reach_state.action_origin
	var reachable_coords: Array[Vector2i] = reach_state.coords
	var reachable_lookup: Dictionary = reach_state.lookup
	var _reachable_move_spaces: int = reach_state.move_spaces

	#_append_move_action(actions, _reachable_move_spaces)

	if unit.res.has_action_available():
		_append_combat_actions(actions, unit, unit_manager, reach_state, axis)
		_append_task_action(actions, unit, action_origin)
		_append_location_action(actions, unit, action_origin)
		_append_loot_action(actions, unit, action_origin, reachable_coords, reachable_lookup)
		_append_skill_actions(actions, unit, weather_manager)
		_append_move_and_interact_actions(actions, unit, terrain_map, unit_manager, reachable_lookup, axis)
		if _dialogue_service:
			_dialogue_service.append_dialogue_actions(actions, unit, unit_manager)

	_append_wait_action(actions)

	return actions

static func _get_grid_axis(unit: Unit) -> int:
	if unit.grid_map and unit.grid_map.tile_set:
		return unit.grid_map.tile_set.tile_offset_axis
	return TileSet.TILE_OFFSET_AXIS_VERTICAL

static func _append_move_action(actions: Array[Dictionary], reachable_move_spaces: int) -> void:
	if reachable_move_spaces > 0:
		actions.append({
			"type": GameConstants.Commands.MOVE_ACTION,
			"action_id": GameConstants.ActionIds.MOVE,
			"label_params": {"spaces": reachable_move_spaces},
			"available": true
		})

static func _append_combat_actions(actions: Array[Dictionary], unit: Unit, unit_manager: UnitManager, reach_state: Dictionary, axis: int) -> void:
	var calculator = CombatActionCalculator.new()
	calculator.append_combat_actions(actions, unit, unit_manager, reach_state, axis)

	# Add Convince for adjacent neutral units
	var targets = _CombatDiscovery.get_all_targets(unit)
	for target in targets["enemies"]:
		if target.faction == Unit.Faction.NEUTRAL and target.neutral_can_be_persuaded:
			# Check if adjacent
			var dist = HexNavigator.get_hex_distance(unit.get_grid_location(), target.get_grid_location(), axis)
			if dist <= 1:
				actions.append({
					"type": GameConstants.Interactions.CONVINCE,
					"action_id": GameConstants.ActionIds.UNIT_OPPOSED,
					"label_params": {"unit": target.unit_name},
					"available": true,
					"target": target,
					"needs_attribute": true,
				})
				break

static func _append_task_action(actions: Array[Dictionary], unit: Unit, action_origin: Vector2i) -> void:
	var provider = TaskActionProvider.new()
	provider.append_task_action(actions, unit, action_origin)

static func _append_location_action(actions: Array[Dictionary], unit: Unit, action_origin: Vector2i) -> void:
	var provider = LocationActionProvider.new()
	provider.append_location_action(actions, unit, action_origin)

static func _append_skill_actions(actions: Array[Dictionary], unit: Unit, weather_manager) -> void:
	var skills: Array = unit.skills if unit.skills is Array else []
	for skill in skills:
		if skill == null:
			continue
		if skill.is_passive: continue

		if skill is WeatherChangeSkill:
			var can_channel = true
			if weather_manager == null or not weather_manager.has_method("get_channeling_unit"):
				can_channel = false
			else:
				can_channel = weather_manager.get_channeling_unit() == null

			actions.append({
				"type": GameConstants.Interactions.SKILL,
				"action_id": GameConstants.ActionIds.SKILL,
				"label_params": {"skill_name": skill.skill_name},
				"available": can_channel,
				"skill": skill,
			})
		else:
			actions.append({
				"type": GameConstants.Interactions.SKILL,
				"label": skill.skill_name,
				"available": true,
				"skill": skill,
				"hint": skill.get_tooltip_text()
			})

static func _append_loot_action(actions: Array[Dictionary], unit: Unit, action_origin: Vector2i, reachable_coords: Array[Vector2i], reachable_lookup: Dictionary) -> void:
	var provider = LootActionProvider.new()
	provider.append_loot_action(actions, unit, action_origin, reachable_coords, reachable_lookup)

static func _append_wait_action(actions: Array[Dictionary]) -> void:
	actions.append({
		"type": GameConstants.Commands.WAIT,
		"action_id": GameConstants.ActionIds.WAIT,
		"available": true
	})

static func _append_move_and_interact_actions(actions: Array[Dictionary], unit: Unit, terrain_map, unit_manager: UnitManager, reachable_lookup: Dictionary, axis: int) -> void:
	if not unit.res.has_action_available():
		return

	var unit_index = unit_manager.get_unit_index(unit)
	if unit_index == -1:
		return
	if not unit.movement:
		return
	var remaining_move := unit.movement.get_remaining_movement_points()
	if remaining_move <= 0:
		return

	_append_move_and_attack_actions(actions, unit, terrain_map, unit_manager, unit_index, reachable_lookup, axis, remaining_move)
	_append_move_and_loot_actions(actions, unit, terrain_map, unit_manager, unit_index, reachable_lookup, axis, remaining_move)
	_append_move_and_task_actions(actions, unit, terrain_map, unit_manager, unit_index, reachable_lookup, axis, remaining_move)


static func _append_move_and_attack_actions(actions: Array[Dictionary], unit: Unit, terrain_map, unit_manager: UnitManager, unit_index: int, reachable_lookup: Dictionary, axis: int, remaining_move: int) -> void:
	var all_targets = _CombatDiscovery.get_all_targets(unit)
	var split = _ConvinceDiscovery.split_targets(all_targets["enemies"])
	var to_fight: Array = split["fight"]
	var to_convince: Array = split["convince"]

	# Resolve Move & Fight
	for target in to_fight:
		_process_move_and_unit_interaction(actions, unit, target, GameConstants.ActionIds.UNIT_OPPOSED, GameConstants.Interactions.ATTACK, terrain_map, unit_manager, unit_index, reachable_lookup, axis, remaining_move)
		break # Limit to first reachable for now to avoid menu clutter, or similar logic to existing

	# Resolve Move & Convince
	for target in to_convince:
		_process_move_and_unit_interaction(actions, unit, target, GameConstants.ActionIds.UNIT_OPPOSED, GameConstants.Interactions.CONVINCE, terrain_map, unit_manager, unit_index, reachable_lookup, axis, remaining_move)
		break

static func _process_move_and_unit_interaction(actions: Array[Dictionary], unit: Unit, target: Unit, action_role_id: String, action_type: String, terrain_map, unit_manager: UnitManager, unit_index: int, reachable_lookup: Dictionary, axis: int, remaining_move: int) -> void:
	if not is_instance_valid(target) or target == unit or target.willpower <= 0:
		return
	var target_index = unit_manager.get_unit_index(target)
	if target_index == -1:
		return
	var target_coord = target.get_grid_location()
	var adjacent_coords = _get_adjacent_coords(target_coord, axis)
	var best_coord := GameConstants.INVALID_COORD
	var best_cost := INF
	for adj_coord in adjacent_coords:
		var move_cost = int(_resolve_move_cost(reachable_lookup, adj_coord, remaining_move))
		if move_cost < 0:
			continue
		if not _has_unblocked_path(unit, terrain_map, unit_manager, unit_index, adj_coord, remaining_move):
			continue
		if move_cost < best_cost:
			best_cost = move_cost
			best_coord = adj_coord
	if best_coord != GameConstants.INVALID_COORD:
		var extra := {
			"interact_target_uid": target_index,
			"interact_target_coord": target_coord,
			"interaction_id": action_role_id,
			"target": target
		}
		if action_type == GameConstants.Interactions.ATTACK:
			extra["attribute_index"] = _select_best_attack_attribute(unit)

		actions.append(_build_move_and_interact_action(best_coord, action_type, int(best_cost), 1, extra))

static func _append_move_and_loot_actions(actions: Array[Dictionary], unit: Unit, terrain_map, unit_manager: UnitManager, unit_index: int, reachable_lookup: Dictionary, _axis: int, remaining_move: int) -> void:
	var loot_manager = unit.get_loot_manager()
	if loot_manager == null:
		return

	var potential_targets = _LootDiscovery.get_potential_loot_targets(unit, loot_manager)
	for target in potential_targets:
		var loot_item = target.item
		var loot_coord = target.coord

		# Loot requires reaching the tile itself so the follow-up command succeeds.
		var move_cost = _resolve_move_cost(reachable_lookup, loot_coord, remaining_move)
		if move_cost < 0:
			continue
		if not _has_unblocked_path(unit, terrain_map, unit_manager, unit_index, loot_coord, remaining_move):
			continue
		var is_trapped := false
		if "is_trapped" in loot_item and loot_item.is_trapped:
			is_trapped = true

		var action_type = GameConstants.Interactions.TRAPPED if is_trapped else GameConstants.Interactions.GATHER
		var action_cost = 1 if is_trapped else 0
		var interaction_id = GameConstants.ActionIds.ITEM_OPPOSED if is_trapped else GameConstants.ActionIds.ITEM_UNOPPOSED
		var extra := {
			"interact_target_coord": loot_coord,
			"target": loot_item,
			"interaction_id": interaction_id
		}
		actions.append(_build_move_and_interact_action(loot_coord, action_type, move_cost, action_cost, extra))
		break

static func _append_move_and_task_actions(actions: Array[Dictionary], unit: Unit, terrain_map, unit_manager: UnitManager, unit_index: int, reachable_lookup: Dictionary, _axis: int, remaining_move: int) -> void:
	var task_manager = unit.get_task_manager()
	if task_manager == null:
		return

	var active_tasks = _TaskDiscovery.get_active_tasks(task_manager)
	for task in active_tasks:
		var target_coord: Vector2i = task.target_coord
		if target_coord == GameConstants.INVALID_COORD:
			continue
		if not reachable_lookup.has(target_coord):
			continue

		if not task.target_id.is_empty():
			var location = task_manager.get_location_at(target_coord)
			if location == null or task.target_id != location.loc_name:
				continue

		# Working a task requires standing on the task tile itself.
		var move_cost = _resolve_move_cost(reachable_lookup, target_coord, remaining_move)
		if move_cost <= 0:
			continue
		if not _has_unblocked_path(unit, terrain_map, unit_manager, unit_index, target_coord, remaining_move):
			continue
		var is_explore = (task.event_type == GameConstants.Interactions.EXPLORE or task.event_type == GameConstants.Commands.INTERACT)

		var action_type = GameConstants.Interactions.EXPLORE if is_explore else GameConstants.Interactions.VISIT
		var interaction_id = GameConstants.ActionIds.LOCATION_OPPOSED if is_explore else GameConstants.ActionIds.LOCATION_UNOPPOSED
		var extra := {
			"interact_target_coord": target_coord,
			"task_id": String(task.id),
			"needs_attribute": is_explore,
			"interaction_id": interaction_id,
			"target": task_manager.get_location_at(target_coord)
		}
		actions.append(_build_move_and_interact_action(target_coord, action_type, move_cost, 1, extra))
		break

static func _extract_move_cost(reachable_lookup: Dictionary, coord: Vector2i) -> int:
	if not reachable_lookup.has(coord):
		return -1
	var data = reachable_lookup[coord]
	if data is Dictionary:
		return int(data.get("cost", 0))
	if data is int or data is float:
		return int(data)
	return 0

static func _resolve_move_cost(reachable_lookup: Dictionary, coord: Vector2i, remaining_move: int) -> int:
	var move_cost = _extract_move_cost(reachable_lookup, coord)
	if move_cost < 0 or move_cost > remaining_move:
		return -1
	return move_cost

static func _has_unblocked_path(unit: Unit, terrain_map, unit_manager: UnitManager, unit_index: int, target_coord: Vector2i, remaining_move: int) -> bool:
	if terrain_map == null or unit_manager == null:
		return true
	if not is_instance_valid(unit) or target_coord == GameConstants.INVALID_COORD:
		return false
	if remaining_move <= 0:
		return false
	# Don't offer a move action to a tile that is already occupied by another unit
	if unit_manager.is_occupied(target_coord, unit_index):
		return false
	var start_coord = _resolve_move_origin(unit, unit_manager, unit_index)
	if start_coord == GameConstants.INVALID_COORD:
		start_coord = unit.get_grid_location()
	if start_coord == GameConstants.INVALID_COORD:
		return false
	if start_coord == target_coord:
		return true
	var path := unit.movement.get_path_to_coord(target_coord, terrain_map, start_coord, remaining_move)
	return not path.is_empty()

static func _resolve_move_origin(unit: Unit, unit_manager: UnitManager, unit_index: int) -> Vector2i:
	if unit_manager == null or unit_index < 0:
		return unit.get_grid_location()
	var start_coord = unit_manager.get_coord(unit_index)
	if unit.movement.has_tentative_move():
		var committed_coord = unit.movement.get_start_of_turn_grid_coord()
		if committed_coord != Vector2i.MAX and committed_coord != GameConstants.INVALID_COORD:
			start_coord = committed_coord
	if start_coord == GameConstants.INVALID_COORD or start_coord == Vector2i.MAX:
		start_coord = unit.get_grid_location()
	return start_coord

static func _build_move_and_interact_action(move_coord: Vector2i, interact_action_type: String, movement_cost: int, action_cost: int, extra_fields: Dictionary = {}) -> Dictionary:
	var action := {
		"type": GameConstants.Commands.MOVE_AND_INTERACT_TYPE,
		"action_id": GameConstants.ActionIds.MOVE_AND_INTERACT,
		"available": true,
		"target_move_coord": move_coord,
		"interact_action_type": interact_action_type,
		"movement_cost": movement_cost,
		"action_cost": action_cost
	}
	for field in extra_fields:
		action[field] = extra_fields[field]
	return action

static func _select_best_attack_attribute(unit: Unit) -> int:
	var attrs = unit.inv.get_attributes() if unit.inv else null
	if attrs == null:
		return 0
	var best_index := 0
	var best_value := -INF
	for i in range(Target.COMBAT_ATTRIBUTE_NAMES.size()):
		var attr_name = Target.COMBAT_ATTRIBUTE_NAMES[i]
		var attr_value = attrs.get_attribute(attr_name)
		if attr_value > best_value:
			best_value = attr_value
			best_index = i
	return best_index

static func _select_best_task_attribute_name(unit: Unit) -> String:
	var attrs = unit.inv.get_attributes() if unit.inv else null
	if attrs == null:
		return GameConstants.Attributes.GRIT
	var best_name := GameConstants.Attributes.GRIT
	var best_value := -INF
	for attr_name in Target.COMBAT_ATTRIBUTE_NAMES:
		var attr_value = attrs.get_attribute(attr_name)
		if attr_value > best_value:
			best_value = attr_value
			best_name = attr_name
	return best_name

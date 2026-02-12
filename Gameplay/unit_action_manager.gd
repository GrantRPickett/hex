class_name UnitActionManager
extends RefCounted

const HexNavigator := preload("res://Gameplay/hex_navigator.gd")
const ActionAvailabilityService := preload("res://Gameplay/action_availability_service.gd")
const ReachableStateCalculator := preload("res://Gameplay/reachable_state_calculator.gd")
const CombatActionCalculator := preload("res://Gameplay/combat_action_calculator.gd")
const LootActionProvider := preload("res://Gameplay/loot_action_provider.gd")
const UnitAttributes := preload("res://Gameplay/unit_attributes.gd")

static var _dialogue_service: DialogueActionService

static func set_dialogue_service(service: DialogueActionService) -> void:
	print_debug("[UnitActionManager] dialogue service set -> %s" % (service if service else "null"))
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
	var reachable_move_spaces: int = reach_state.move_spaces

	#_append_move_action(actions, reachable_move_spaces)

	if unit.has_action_available():
		_append_combat_actions(actions, unit, unit_manager, reachable_coords, axis)
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
			"type": "move",
			"label": "Move (%d spaces)" % reachable_move_spaces,
			"available": true
		})

static func _append_combat_actions(actions: Array[Dictionary], unit: Unit, unit_manager: UnitManager, reachable_coords: Array[Vector2i], axis: int) -> void:
	var calculator = CombatActionCalculator.new()
	calculator.append_combat_actions(actions, unit, unit_manager, reachable_coords, axis)

static func _append_location_action(actions: Array[Dictionary], unit: Unit, action_origin: Vector2i) -> void:
	var provider = locationActionProvider.new()
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
				"type": "skill",
				"label": skill.skill_name,
				"available": can_channel,
				"skill": skill,
				"hint": skill.get_tooltip_text() if can_channel else "Weather already being channeled this round."
			})
		else:
			actions.append({
				"type": "skill",
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
		"type": "wait",
		"label": "Wait / End Turn",
		"available": true
	})

static func _append_move_and_interact_actions(actions: Array[Dictionary], unit: Unit, terrain_map, unit_manager: UnitManager, reachable_lookup: Dictionary, axis: int) -> void:
	if not unit.has_action_available():
		return

	var unit_index = unit_manager.get_unit_index(unit)
	if unit_index == -1:
		return
	var remaining_move := unit.get_remaining_movement_points() if unit.has_method("get_remaining_movement_points") else unit.movement_points
	if remaining_move <= 0:
		return

	_append_move_and_attack_actions(actions, unit, terrain_map, unit_manager, unit_index, reachable_lookup, axis, remaining_move)
	_append_move_and_loot_actions(actions, unit, terrain_map, unit_manager, unit_index, reachable_lookup, axis, remaining_move)
	_append_move_and_location_actions(actions, unit, terrain_map, unit_manager, unit_index, reachable_lookup, axis, remaining_move)



static func _append_move_and_attack_actions(actions: Array[Dictionary], unit: Unit, terrain_map, unit_manager: UnitManager, unit_index: int, reachable_lookup: Dictionary, axis: int, remaining_move: int) -> void:
	var hostiles: Array = unit.get_hostile_units()
	for enemy in hostiles:
		if not is_instance_valid(enemy) or enemy == unit or enemy.willpower <= 0:
			continue
		var enemy_index = unit_manager.get_unit_index(enemy)
		if enemy_index == -1:
			continue
		var target_coord = enemy.get_grid_location()
		var adjacent_coords = _get_adjacent_coords(target_coord, axis)
		var best_coord := Vector2i(-999, -999)
		var best_cost := INF
		for adj_coord in adjacent_coords:
			var move_cost = _resolve_move_cost(reachable_lookup, adj_coord, remaining_move)
			if move_cost < 0:
				continue
			if not _has_unblocked_path(unit, terrain_map, unit_manager, unit_index, adj_coord, remaining_move):
				continue
			if move_cost < best_cost:
				best_cost = move_cost
				best_coord = adj_coord
		if best_coord != Vector2i(-999, -999):
			var label = "Move & Attack %s (M%d/A1)" % [enemy.unit_name, best_cost]
			var extra := {
				"interact_target_uid": enemy_index,
				"interact_target_coord": target_coord,
				"attribute_index": _select_best_attack_attribute(unit)
			}
			actions.append(_build_move_and_interact_action(label, best_coord, "attack", best_cost, 1, extra))
			break

static func _append_move_and_loot_actions(actions: Array[Dictionary], unit: Unit, terrain_map, unit_manager: UnitManager, unit_index: int, reachable_lookup: Dictionary, axis: int, remaining_move: int) -> void:
	var loot_manager = unit.get_loot_manager()
	if loot_manager == null:
		return
	var loot_count = loot_manager.get_loot_count()
	for loot_index in range(loot_count):
		var loot_item = loot_manager.get_loot(loot_index)
		if not is_instance_valid(loot_item):
			continue
		var loot_coord = loot_manager.get_coord(loot_index)
		# Loot requires reaching the tile itself so the follow-up command succeeds.
		var move_cost = _resolve_move_cost(reachable_lookup, loot_coord, remaining_move)
		if move_cost < 0:
			continue
		if not _has_unblocked_path(unit, terrain_map, unit_manager, unit_index, loot_coord, remaining_move):
			continue
		var label = "Move & Loot (M%d)" % move_cost
		var extra := {
			"interact_target_coord": loot_coord
		}
		actions.append(_build_move_and_interact_action(label, loot_coord, "loot", move_cost, 0, extra))
		break

static func _append_move_and_location_actions(actions: Array[Dictionary], unit: Unit, terrain_map, unit_manager: UnitManager, unit_index: int, reachable_lookup: Dictionary, axis: int, remaining_move: int) -> void:
	var task_manager = unit.get_task_manager()
	if task_manager == null:
		return
	var location_count = task_manager.get_location_count() if task_manager.has_method("get_location_count") else 0
	for location_index in range(location_count):
		var location_coord = task_manager.get_target(location_index) if task_manager.has_method("get_target") else Vector2i(-1, -1)
		if location_coord == Vector2i(-1, -1):
			continue
		# Working a location requires standing on the location tile itself.
		var move_cost = _resolve_move_cost(reachable_lookup, location_coord, remaining_move)
		if move_cost <= 0:
			continue
		if not _has_unblocked_path(unit, terrain_map, unit_manager, unit_index, location_coord, remaining_move):
			continue
		var attr_type = task_manager.get_required_type(location_index, unit.faction) if task_manager.has_method("get_required_type") else ""
		var attr_label = attr_type.capitalize() if not attr_type.is_empty() else "location"
		var label = "Move & Work %s (M%d/A1)" % [attr_label, move_cost]
		var extra := {
			"interact_target_coord": location_coord,
			"location_index": location_index
		}
		actions.append(_build_move_and_interact_action(label, location_coord, "location", move_cost, 1, extra))
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
	if not is_instance_valid(unit) or target_coord == Vector2i(-999, -999):
		return false
	if remaining_move <= 0:
		return false
	var start_coord = _resolve_move_origin(unit, unit_manager, unit_index)
	if start_coord == Vector2i(-999, -999):
		start_coord = unit.get_grid_location()
	if start_coord == Vector2i(-999, -999):
		return false
	if start_coord == target_coord:
		return true
	var path := unit.get_path_to_coord(target_coord, terrain_map, start_coord, remaining_move)
	return not path.is_empty()

static func _resolve_move_origin(unit: Unit, unit_manager: UnitManager, unit_index: int) -> Vector2i:
	if unit_manager == null or unit_index < 0:
		return unit.get_grid_location()
	var start_coord = unit_manager.get_coord(unit_index)
	if unit.has_tentative_move():
		var committed_coord = unit.get_start_of_turn_grid_coord()
		if committed_coord != Vector2i.MAX and committed_coord != Vector2i(-999, -999):
			start_coord = committed_coord
	if start_coord == Vector2i(-1, -1) or start_coord == Vector2i(-999, -999) or start_coord == Vector2i.MAX:
		start_coord = unit.get_grid_location()
	return start_coord

static func _build_move_and_interact_action(label: String, move_coord: Vector2i, interact_action_type: String, movement_cost: int, action_cost: int, extra_fields: Dictionary = {}) -> Dictionary:
	var action := {
		"type": "move_and_interact",
		"label": label,
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
	var attrs = unit.get_attributes()
	if attrs == null:
		return 0
	var best_index := 0
	var best_value := -INF
	for i in range(UnitAttributes.ATTRIBUTE_NAMES.size()):
		var attr_name = UnitAttributes.ATTRIBUTE_NAMES[i]
		var attr_value = attrs.get_attribute(attr_name)
		if attr_value > best_value:
			best_value = attr_value
			best_index = i
	return best_index

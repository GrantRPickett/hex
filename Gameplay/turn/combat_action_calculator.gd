class_name CombatActionCalculator
extends RefCounted

const LocalizationStrings := preload("res://Resources/Localization/localization_strings.gd")

func append_combat_actions(actions: Array[PlayerAction], unit: Unit, unit_manager: UnitManager, reach_state: ReachableState, axis: int) -> void:
	var near_targets : Dictionary = _find_near_combat_targets(unit, unit_manager)
	var reachable_results : Dictionary = _find_reachable_combat_targets(
		unit, unit_manager, reach_state, axis, near_targets)
	var reachable_targets: Dictionary = reachable_results.targets
	var target_move_data: Dictionary = reachable_results.move_data

	var all_hostile_near: Array[Unit] = []
	all_hostile_near.append_array(near_targets["enemies"])
	all_hostile_near.append_array(near_targets["neutrals"])
	var near_split : Dictionary = TargetDiscoveryService.split_units_for_combat(all_hostile_near)
	var fight_near: Array[Unit] = near_split["fight"]
	var convince_near: Array[Unit] = near_split["convince"]

	var all_hostile_reachable: Array[Unit] = []
	all_hostile_reachable.append_array(reachable_targets["enemies"])
	all_hostile_reachable.append_array(reachable_targets["neutrals"])
	var reachable_split : Dictionary = TargetDiscoveryService.split_units_for_combat(all_hostile_reachable)
	var fight_reachable: Array[Unit] = reachable_split["fight"]
	var convince_reachable: Array[Unit] = reachable_split["convince"]

	_add_convince_action(actions, unit, convince_near, convince_reachable, target_move_data)
	_add_attack_action(actions, unit, fight_near, fight_reachable, target_move_data)
	_add_aid_action(actions, unit, near_targets.allies, reachable_targets.allies, target_move_data)

func _find_near_combat_targets(unit: Unit, unit_manager: UnitManager) -> Dictionary:
	var results : Dictionary = TargetDiscoveryService.discover_nearby(unit.get_grid_location(), unit.action_range, [TargetDiscoveryService.UNIT], {
		"unit_manager": unit_manager,
		"source_unit": unit
	})
	var units_result = results.get(TargetDiscoveryService.UNIT, {})
	if units_result is Dictionary:
		return units_result
	return {"enemies": [] as Array[Unit], "allies": [] as Array[Unit], "neutrals": [] as Array[Unit]}

func _find_reachable_combat_targets(unit: Unit, unit_manager: UnitManager, reach_state: ReachableState, axis: int, near_targets: Dictionary) -> Dictionary:
	if reach_state.coords.size() <= 1:
		return {"targets": {"enemies": [] as Array[Unit], "allies": [] as Array[Unit], "neutrals": [] as Array[Unit]}, "move_data": {}}

	var discovery_results := TargetDiscoveryService.discover_nearby(unit.get_grid_location(), GameConstants.AI.AI_DISCOVERY_RADIUS, [TargetDiscoveryService.UNIT], {
		"unit_manager": unit_manager,
		"source_unit": unit
	})
	var units_result = discovery_results.get(TargetDiscoveryService.UNIT, {})
	var all_targets := {"enemies": [] as Array[Unit], "allies": [] as Array[Unit], "neutrals": [] as Array[Unit]}
	if units_result is Dictionary:
		all_targets = units_result

	var move_data := {}

	var reachable_friendlies := _find_reachable_targets_with_move(all_targets["allies"], unit, unit_manager, reach_state, axis, near_targets, move_data)
	var reachable_hostiles := _find_reachable_targets_with_move(all_targets["enemies"], unit, unit_manager, reach_state, axis, near_targets, move_data)
	var reachable_neutral_units := _find_reachable_targets_with_move(all_targets["neutrals"], unit, unit_manager, reach_state, axis, near_targets, move_data)

	return {
		"targets": {"enemies": reachable_hostiles, "allies": reachable_friendlies, "neutrals": reachable_neutral_units},
		"move_data": move_data
	}

func _find_reachable_targets_with_move(units: Array, unit: Unit, unit_manager: UnitManager, reach_state: ReachableState, axis: int, near_targets: Dictionary, out_move_data: Dictionary) -> Array:
	var list: Array = []
	for other in units:
		if _should_skip_target(unit, other, near_targets):
			continue
		var idx: int = unit_manager.get_unit_index(other)
		var other_coord: Vector2i = unit_manager.get_coord(idx)
		if other_coord == Vector2i(-999, -999):
			continue

		var move_info := _find_best_near_coord(other_coord, reach_state.coords, reach_state.lookup, axis, unit.action_range, unit_manager, reach_state.unit_index)
		if move_info.coord != GameConstants.INVALID_COORD:
			list.append(other)
			out_move_data[other] = move_info
	return list

func _should_skip_target(unit: Unit, other: Unit, near_targets: Dictionary) -> bool:
	if other == null or other == unit:
		return true
	return near_targets["enemies"].has(other) or near_targets["allies"].has(other) or near_targets["neutrals"].has(other)

func _add_attack_action(actions: Array[PlayerAction], _unit: Unit, enemies: Array, reachable_enemies: Array, target_move_data: Dictionary) -> void:
	var attack_near_count: int = enemies.size()
	var attack_reachable_count: int = reachable_enemies.size()

	if attack_near_count > 0 or attack_reachable_count > 0:
		var attack_action := PlayerAction.new(GameConstants.ActionType.OPEN_ATTACK_MENU)
		attack_action.actor = _unit
		attack_action.action_id = GameConstants.Activity.FIGHT
		attack_action.ui_label_params = {
			"near": attack_near_count,
			"far": attack_reachable_count
		}
		attack_action.available = attack_near_count > 0 or attack_reachable_count > 0
		attack_action.needs_attribute = true

		for e in enemies:
			attack_action.targets.append(e)
		for re in reachable_enemies:
			attack_action.reachable_targets.append(re)

		if not enemies.is_empty():
			attack_action.target_object = enemies[0]
		elif not reachable_enemies.is_empty():
			attack_action.target_object = reachable_enemies[0]

		if attack_reachable_count > 0:
			ActionUtility.set_reachable_info(attack_action, reachable_enemies, target_move_data)

		actions.append(attack_action)

func _add_convince_action(actions: Array[PlayerAction], _unit: Unit, convince_targets: Array, reachable_convince: Array, target_move_data: Dictionary) -> void:
	var convince_near_count: int = convince_targets.size()
	var convince_reachable_count: int = reachable_convince.size()

	if convince_near_count > 0 or convince_reachable_count > 0:
		var convince_action := PlayerAction.new(GameConstants.ActionType.CONVINCE)
		convince_action.actor = _unit
		convince_action.action_id = GameConstants.Activity.CONVINCE
		convince_action.ui_label_params = {
			"near": convince_near_count,
			"far": convince_reachable_count,
			"is_convince": true
		}
		convince_action.available = convince_near_count > 0 or convince_reachable_count > 0
		convince_action.needs_attribute = true

		if not convince_targets.is_empty():
			for t in convince_targets:
				convince_action.targets.append(t)
			convince_action.target_object = convince_targets[0]
		elif not reachable_convince.is_empty():
			convince_action.target_object = reachable_convince[0]

		for t in reachable_convince:
			convince_action.reachable_targets.append(t)

		if convince_reachable_count > 0:
			ActionUtility.set_reachable_info(convince_action, reachable_convince, target_move_data)

		actions.append(convince_action)

func _add_aid_action(actions: Array[PlayerAction], _unit: Unit, allies: Array, reachable_allies: Array, target_move_data: Dictionary) -> void:
	var aid_near_count: int = allies.size()
	var aid_reachable_count: int = reachable_allies.size()

	if aid_near_count > 0 or aid_reachable_count > 0:
		var aid_action := PlayerAction.new(GameConstants.ActionType.AID)
		aid_action.actor = _unit
		aid_action.action_id = LocalizationStrings.HUD_ACTION_AID
		aid_action.ui_label_params = {"near": aid_near_count, "far": aid_reachable_count}
		aid_action.available = aid_near_count > 0 or aid_reachable_count > 0
		aid_action.needs_attribute = true
		aid_action.ui_hint = LocalizationStrings.get_text(LocalizationStrings.HUD_HINT_AID)

		var aid_targets: Array[Target] = []
		aid_targets.assign(allies)
		aid_targets.append_array(reachable_allies)
		if not aid_targets.is_empty():
			for t in aid_targets:
				aid_action.targets.append(t)
			aid_action.target_object = aid_targets[0]

		if aid_reachable_count > 0:
			ActionUtility.set_reachable_info(aid_action, reachable_allies, target_move_data)
			aid_action.ui_hint = LocalizationStrings.get_text(LocalizationStrings.HUD_HINT_AID)

		actions.append(aid_action)

func _find_best_near_coord(target_coord: Vector2i, reachable_coords: Array[Vector2i], reachable_lookup: Dictionary, axis: int, action_range: float, unit_manager: UnitManager = null, unit_index: int = -1) -> Dictionary:
	var best_coord: Vector2i = GameConstants.INVALID_COORD
	var best_cost := INF
	for coord in reachable_coords:
		if coord == target_coord: continue

		# Check if the coordinate is occupied by ANOTHER unit (can't end there)
		if unit_manager and unit_manager.is_occupied(coord, unit_index):
			continue

		var distance := HexLib.get_distance(coord, target_coord, axis)
		if distance > 0 and distance <= action_range:
			var cost: float = INF
			var data = reachable_lookup.get(coord)
			if data is Dictionary:
				cost = data.get("cost", INF)
			elif data is int or data is float:
				cost = data

			if cost < best_cost:
				best_cost = cost
				best_coord = coord
	return {"coord": best_coord, "cost": best_cost}

func has_reachable_near(reachable_coords: Array[Vector2i], target_coord: Vector2i, axis: int, action_range: float, unit_manager: UnitManager = null, unit_index: int = -1) -> bool:
	var result := _find_best_near_coord(target_coord, reachable_coords, {}, axis, action_range, unit_manager, unit_index)
	return result.coord != GameConstants.INVALID_COORD

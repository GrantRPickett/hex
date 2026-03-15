class_name CombatActionCalculator
extends RefCounted

const _ConvinceDiscovery = preload("res://Gameplay/targets/discovery/convince_discovery.gd")
const LocalizationStrings := preload("res://Resources/Localization/localization_strings.gd")

func append_combat_actions(actions: Array[UnitAction], unit: Unit, unit_manager: UnitManager, reach_state: ReachableState, axis: int) -> void:
	var near_targets := _find_near_combat_targets(unit, unit_manager)
	var reachable_results := _find_reachable_combat_targets(unit, unit_manager, reach_state, axis, near_targets)
	var reachable_targets: Dictionary = reachable_results.targets
	var target_move_data: Dictionary = reachable_results.move_data

	var near_split = _ConvinceDiscovery.split_targets(near_targets["enemies"])
	var fight_near = near_split["fight"]
	var convince_near = near_split["convince"]

	var reachable_split = _ConvinceDiscovery.split_targets(reachable_targets["enemies"])
	var fight_reachable = reachable_split["fight"]
	var convince_reachable = reachable_split["convince"]

	_add_attack_action(actions, unit, fight_near, fight_reachable, target_move_data)
	_add_convince_action(actions, unit, convince_near, convince_reachable, target_move_data)
	_add_aid_action(actions, unit, near_targets.allies, reachable_targets.allies, target_move_data)

func _find_near_combat_targets(unit: Unit, _unit_manager: UnitManager) -> Dictionary:
	return unit.query.get_near_units_categorized()

func _find_reachable_combat_targets(unit: Unit, unit_manager: UnitManager, reach_state: ReachableState, axis: int, near_targets: Dictionary) -> Dictionary:
	if reach_state.coords.size() <= 1:
		return {"targets": {"enemies": [], "allies": [], "neutrals": []}, "move_data": {}}

	var all_targets = unit.query.get_all_units_categorized()
	var move_data := {}

	var reachable_friendlies = _find_reachable_targets_with_move(all_targets["allies"], unit, unit_manager, reach_state, axis, near_targets, move_data)
	var reachable_hostiles = _find_reachable_targets_with_move(all_targets["enemies"], unit, unit_manager, reach_state, axis, near_targets, move_data)
	var reachable_neutral_units = _find_reachable_targets_with_move(all_targets["neutrals"], unit, unit_manager, reach_state, axis, near_targets, move_data)

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

		var move_info = _find_best_near_coord(other_coord, reach_state.coords, reach_state.lookup, axis, unit.action_range, unit_manager, reach_state.unit_index)
		if move_info.coord != GameConstants.INVALID_COORD:
			list.append(other)
			out_move_data[other] = move_info
	return list

func _should_skip_target(unit: Unit, other: Unit, near_targets: Dictionary) -> bool:
	if other == null or other == unit:
		return true
	return near_targets["enemies"].has(other) or near_targets["allies"].has(other)

func _add_attack_action(actions: Array[UnitAction], _unit: Unit, enemies: Array, reachable_enemies: Array, target_move_data: Dictionary) -> void:
	var attack_near_count: int = enemies.size()
	var attack_reachable_count: int = reachable_enemies.size()

	if attack_near_count > 0 or attack_reachable_count > 0:
		var attack_action: UnitAction = UnitAction.new(UnitAction.Type.OPEN_ATTACK_MENU)
		attack_action.action_id = GameConstants.ActionIds.UNIT_OPPOSED
		attack_action.label_params = {"near": attack_near_count, "far": attack_reachable_count, "imm_label": "near"}
		attack_action.available = attack_near_count > 0 or attack_reachable_count > 0
		attack_action.needs_attribute = true

		var attack_targets: Array = []
		attack_targets.append_array(enemies)
		attack_targets.append_array(reachable_enemies)
		if not attack_targets.is_empty():
			attack_action.targets = attack_targets
			attack_action.target = attack_targets[0]

		if attack_reachable_count > 0:
			attack_action.reachable_targets = reachable_enemies
			attack_action.target_move_data = target_move_data
			attack_action.hint = "Move near to attack reachable enemies."

		actions.append(attack_action)

func _add_convince_action(actions: Array[UnitAction], _unit: Unit, convince_targets: Array, reachable_convince: Array, target_move_data: Dictionary) -> void:
	var convince_near_count: int = convince_targets.size()
	var convince_reachable_count: int = reachable_convince.size()

	if convince_near_count > 0 or convince_reachable_count > 0:
		var convince_action: UnitAction = UnitAction.new(UnitAction.Type.CONVINCE)
		convince_action.action_id = GameConstants.ActionIds.UNIT_OPPOSED
		convince_action.label_params = {"near": convince_near_count, "far": convince_reachable_count, "is_convince": true, "imm_label": "near"}
		convince_action.available = convince_near_count > 0 or convince_reachable_count > 0
		convince_action.needs_attribute = true

		var all_targets: Array = []
		all_targets.append_array(convince_targets)
		all_targets.append_array(reachable_convince)
		if not all_targets.is_empty():
			convince_action.targets = all_targets
			convince_action.target = all_targets[0]

		if convince_reachable_count > 0:
			convince_action.reachable_targets = reachable_convince
			convince_action.target_move_data = target_move_data
			convince_action.hint = "Move near to convince reachable neutrals."

		actions.append(convince_action)

func _add_aid_action(actions: Array[UnitAction], _unit: Unit, allies: Array, reachable_allies: Array, target_move_data: Dictionary) -> void:
	var aid_near_count: int = allies.size()
	var aid_reachable_count: int = reachable_allies.size()

	if aid_near_count > 0 or aid_reachable_count > 0:
		var aid_action: UnitAction = UnitAction.new(UnitAction.Type.AID)
		aid_action.action_id = LocalizationStrings.HUD_ACTION_AID
		aid_action.label_params = {"near": aid_near_count, "far": aid_reachable_count, "imm_label": "near"}
		aid_action.available = aid_near_count > 0 or aid_reachable_count > 0
		aid_action.needs_attribute = true
		aid_action.hint = LocalizationStrings.get_text(LocalizationStrings.HUD_HINT_AID)

		var aid_targets: Array = []
		aid_targets.append_array(allies)
		aid_targets.append_array(reachable_allies)
		if not aid_targets.is_empty():
			aid_action.targets = aid_targets
			aid_action.target = aid_targets[0]

		if aid_reachable_count > 0:
			aid_action.reachable_targets = reachable_allies
			aid_action.target_move_data = target_move_data
			aid_action.hint = LocalizationStrings.get_text(LocalizationStrings.HUD_HINT_AID)

		actions.append(aid_action)

func _find_best_near_coord(target_coord: Vector2i, reachable_coords: Array[Vector2i], reachable_lookup: Dictionary, axis: int, action_range: float, unit_manager: UnitManager = null, unit_index: int = -1) -> Dictionary:
	var best_coord: Vector2i = GameConstants.INVALID_COORD
	var best_cost := INF
	for coord in reachable_coords:
		if coord == target_coord: continue

		# Check if the coordinate is occupied by ANOTHER unit (can't end there)
		if unit_manager and unit_manager.is_occupied(coord, unit_index):
			continue

		var distance = HexLib.get_distance(coord, target_coord, axis)
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
	var result = _find_best_near_coord(target_coord, reachable_coords, {}, axis, action_range, unit_manager, unit_index)
	return result.coord != GameConstants.INVALID_COORD

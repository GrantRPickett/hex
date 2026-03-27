class_name PlayerActionManager
extends RefCounted

static var _dialogue_service: DialogueActionService

static func set_dialogue_service(service: DialogueActionService) -> void:
	_dialogue_service = service

static func get_dialogue_service() -> DialogueActionService:
	return _dialogue_service

static func is_unit_stuck(unit: Unit, terrain_map, unit_manager: UnitManager) -> bool:
	var availability_service := ActionAvailabilityService.new()
	return availability_service.is_unit_stuck(unit, terrain_map, unit_manager)

static func get_available_actions(unit: Unit, terrain_map, unit_manager: UnitManager) -> Array[PlayerAction]:
	return _collect_actions(unit, terrain_map, unit_manager, null)

static func get_available_actions_with_weather(unit: Unit, terrain_map, unit_manager: UnitManager, weather_manager) -> Array[PlayerAction]:
	return _collect_actions(unit, terrain_map, unit_manager, weather_manager)

static func _collect_actions(unit: Unit, terrain_map, unit_manager: UnitManager, weather_manager) -> Array[PlayerAction]:
	var actions: Array[PlayerAction] = []
	if not is_instance_valid(unit) or unit.willpower <= 0 or unit_manager == null: return actions

	var reach_state := MovementRangeService.calculate_reachable_state(unit, terrain_map, unit_manager)
	var axis := _get_grid_axis(unit)

	if unit.res.has_action_available():
		_append_combat_actions(actions, unit, unit_manager, reach_state, axis)
		_append_target_interactions(actions, unit, reach_state)
		_append_skill_actions(actions, unit, weather_manager)

	_append_wait_action(actions)
	return actions

static func _get_grid_axis(unit: Unit) -> int:
	return unit.grid_map.tile_set.tile_offset_axis if unit.grid_map and unit.grid_map.tile_set else TileSet.TILE_OFFSET_AXIS_VERTICAL

static func _append_combat_actions(actions: Array[PlayerAction], unit: Unit, unit_manager: UnitManager, reach_state: ReachableState, axis: int) -> void:
	CombatActionCalculator.new().append_combat_actions(actions, unit, unit_manager, reach_state, axis)

static func _append_skill_actions(actions: Array[PlayerAction], unit: Unit, weather_manager) -> void:
	var skills: Array = unit.skills if unit.skills is Array else []
	for skill in skills:
		if not skill or skill.is_passive: continue
		if skill is WeatherChangeSkill:
			var can_channel: bool = weather_manager.get_channeling_unit() == null if weather_manager and weather_manager.has_method("get_channeling_unit") else false
			var action := PlayerAction.create(GameConstants.ActionType.SKILL, GameConstants.ActionIds.SKILL)
			action.actor = unit
			action.ui_label_params = {"skill_name": skill.skill_name}
			action.available = can_channel
			# SkillCommand is not yet standardized in create_payload but we'll adapt.
			action.command_id = GameConstants.Commands.CommandID.USE_SKILL
			action.command_payload = {GameConstants.Payload.SKILL: skill}
			actions.append(action)
		else:
			var action := PlayerAction.new(GameConstants.ActionType.SKILL)
			action.actor = unit
			action.ui_label = skill.skill_name
			action.available = true
			action.ui_hint = skill.get_tooltip_text()
			action.command_id = GameConstants.Commands.CommandID.USE_SKILL
			action.command_payload = {GameConstants.Payload.SKILL: skill}
			actions.append(action)

static func _append_target_interactions(actions: Array[PlayerAction], unit: Unit, reach: ReachableState) -> void:
	var lookup := reach.lookup if reach else {}

	# 1. Loot
	var loot_res := TargetDiscoveryService.get_categorized_loot(unit, reach)
	var sl: Dictionary = loot_res.split_loot
	_add_inter(actions, unit, sl.immediate_opposed, sl.reachable_opposed, lookup, GameConstants.ActionType.TRAPPED, GameConstants.ActionIds.ITEM_OPPOSED, loot_res.target_to_task)
	_add_inter(actions, unit, sl.immediate_unopposed, sl.reachable_unopposed, lookup, GameConstants.ActionType.GATHER, GameConstants.ActionIds.ITEM_UNOPPOSED, loot_res.target_to_task)

	# 2. Locations
	var loc_res := TargetDiscoveryService.get_categorized_locations(unit, reach)
	var sx: Dictionary = loc_res.split_locations
	_add_inter(actions, unit, sx.immediate_opposed, sx.reachable_opposed, lookup, GameConstants.ActionType.EXPLORE, GameConstants.ActionIds.LOCATION_OPPOSED, loc_res.target_to_task)
	_add_inter(actions, unit, sx.immediate_unopposed, sx.reachable_unopposed, lookup, GameConstants.ActionType.VISIT, GameConstants.ActionIds.LOCATION_UNOPPOSED, loc_res.target_to_task)

static func _add_inter(actions: Array[PlayerAction], actor: Unit, imm: Target, reach: Array, lookup: Dictionary, type: GameConstants.ActionType, id: String, t2t: Dictionary) -> void:
	var n = 1 if imm else 0
	var f = reach.size()
	if n > 0 or f > 0:
		var a = PlayerAction.create(type, id)
		a.actor = actor
		a.ui_label_params = {"near": n, "far": f}
		a.available = true
		a.needs_attribute = true
		a.target_to_task = t2t
		if n > 0:
			a.target_object = imm
			a.targets.append(imm)
		if f > 0:
			ActionUtility.set_reachable_info(a, reach, lookup)
			if n == 0: a.target_object = reach[0]
			for r in reach: a.reachable_targets.append(r)
		actions.append(a)

static func _append_wait_action(actions: Array[PlayerAction]) -> void:
	var action := PlayerAction.create(GameConstants.ActionType.WAIT, GameConstants.ActionIds.WAIT)
	action.command_id = GameConstants.Commands.CommandID.WAIT
	actions.append(action)

static func create_move_and_interact_action(base_action: PlayerAction, target: Target, move_data: Dictionary, unit_manager: UnitManager, attr_idx: int = -1, _attr_name: String = "") -> PlayerAction:
	var final: PlayerAction = base_action.clone()
	final.target_object = target

	var actor = base_action.actor if is_instance_valid(base_action.actor) else unit_manager.get_selected_unit()
	var unit_index: int = unit_manager.get_unit_index(actor)

	# 1. Base Interaction setup
	var itype = base_action.type
	if itype == GameConstants.ActionType.OPEN_ATTACK_MENU:
		itype = GameConstants.ActionType.FIGHT

	var extra_params = {
		"attribute_index": attr_idx,
		"task_id": base_action.target_to_task.get(target, "")
	}

	# 2. Setup Move and Interact if moving
	var m = move_data.get(target)
	if m:
		final.type = GameConstants.ActionType.MOVE_AND_INTERACT
		final.action_id = GameConstants.ActionIds.MOVE_AND_INTERACT

		if m is Dictionary:
			final.move_cost = int(m.get("cost", 0))
			var m_coord = m.get("coord", GameConstants.INVALID_COORD)
			if m_coord != GameConstants.INVALID_COORD:
				extra_params[GameConstants.Payload.TARGET_MOVE_COORD] = m_coord
		else:
			final.move_cost = int(m)

	# 3. Finalize Command Payload
	if itype == GameConstants.ActionType.SKILL:
		final.command_id = GameConstants.Commands.CommandID.USE_SKILL
		final.command_payload[GameConstants.Payload.UNIT_INDEX] = unit_index
		final.command_payload[GameConstants.Payload.TARGET_COORD] = target.get_grid_location()
		if extra_params.has(GameConstants.Payload.TARGET_MOVE_COORD):
			final.command_payload[GameConstants.Payload.TARGET_MOVE_COORD] = extra_params[GameConstants.Payload.TARGET_MOVE_COORD]
	else:
		final.command_id = GameConstants.Commands.CommandID.INTERACT
		var interaction_type = GameConstants.get_interaction_for_action_type(itype)
		final.command_payload = PerformInteractionCommand.create_payload(unit_index, target.get_grid_location(), interaction_type, extra_params)

	return final

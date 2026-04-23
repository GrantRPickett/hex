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
	if not is_instance_valid(unit) or unit.get_current_willpower() <= 0 or unit_manager == null: return actions

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
		var skill_action_id: String = skill.skill_name
		if skill_action_id.is_empty():
			skill_action_id = GameConstants.Activity.SKILL
		if skill is WeatherChangeSkill:
			var can_channel: bool = weather_manager.get_channeling_unit() == null if weather_manager and weather_manager.has_method("get_channeling_unit") else false
			var action := PlayerAction.create(GameConstants.ActionType.SKILL)
			action.actor = unit
			action.action_id = skill_action_id
			action.ui_label_params = {"skill_name": skill.skill_name}
			action.available = can_channel
			# SkillCommand is not yet standardized in create_payload but we'll adapt.
			action.command_id = GameConstants.ActionType.SKILL
			action.command_payload = {GameConstants.Payload.SKILL: skill}
			actions.append(action)
		else:
			var action := PlayerAction.create(GameConstants.ActionType.SKILL)
			action.actor = unit
			action.action_id = skill_action_id
			action.ui_label = skill.skill_name
			action.available = true
			action.ui_hint = skill.get_tooltip_text()
			action.command_id = GameConstants.ActionType.SKILL
			action.command_payload = {GameConstants.Payload.SKILL: skill}
			actions.append(action)

static func _append_target_interactions(actions: Array[PlayerAction], unit: Unit, reach: ReachableState) -> void:
	var lookup := reach.lookup if reach else {}

	# 1. Loot
	var loot_res := TargetDiscoveryService.get_categorized_loot(unit, reach)
	var sl: Dictionary = loot_res.split_loot
	_add_inter(actions, unit, sl.immediate_opposed, sl.reachable_opposed, lookup, GameConstants.ActionType.TRAPPED, GameConstants.Activity.TRAPPED, loot_res.target_to_task)
	_add_inter(actions, unit, sl.immediate_unopposed, sl.reachable_unopposed, lookup, GameConstants.ActionType.GATHER, GameConstants.Activity.GATHER, loot_res.target_to_task)

	# 2. Locations
	var loc_res := TargetDiscoveryService.get_categorized_locations(unit, reach)
	var sx: Dictionary = loc_res.split_locations
	_add_inter(actions, unit, sx.immediate_opposed, sx.reachable_opposed, lookup, GameConstants.ActionType.EXPLORE, GameConstants.Activity.EXPLORE, loc_res.target_to_task)
	_add_inter(actions, unit, sx.immediate_unopposed, sx.reachable_unopposed, lookup, GameConstants.ActionType.VISIT, GameConstants.Activity.VISIT, loc_res.target_to_task)

static func _add_inter(actions: Array[PlayerAction], actor: Unit, imm: Target, reach: Array, lookup: Dictionary, type: GameConstants.ActionType, id: String, t2t: Dictionary) -> void:
	var n = 1 if imm else 0
	var f = reach.size()
	if n > 0 or f > 0:
		var a = PlayerAction.create(type)
		a.action_id = id
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
	var action := PlayerAction.create(GameConstants.ActionType.WAIT)
	action.action_id = GameConstants.ActionIds.WAIT
	action.command_id = GameConstants.ActionType.WAIT
	actions.append(action)

static func create_move_and_interact_action(base_action: PlayerAction, target: Target, move_data: Dictionary, unit_manager: UnitManager, attr_idx: int = -1, _attr_name: String = "") -> PlayerAction:
	var actor = base_action.actor if is_instance_valid(base_action.actor) else unit_manager.get_selected_unit()
	var m = move_data.get(target)
	var move_coord: Vector2i = m.coord if m is Dictionary else actor.get_grid_location()
	var move_cost: int = 0
	if m is Dictionary:
		move_cost = m.get("cost", 0)
	elif m != null:
		move_cost = int(m)

	var itype = base_action.type
	var interaction_type = GameConstants.get_activity_from_type(itype)
	var action_id = GameConstants.ActionIds.MOVE_AND_INTERACT

	var extra_params = {
		"attribute_index": attr_idx,
		"target_id": target.get_target_id() if target.has_method("get_target_id") else "",
		"type": interaction_type # Ensure type is always present for sequencer
	}

	var final: PlayerAction
	if itype == GameConstants.ActionType.SKILL or itype == GameConstants.ActionType.AID:
		final = _create_skill_action(actor, target, move_coord, move_cost, unit_manager, interaction_type, action_id, extra_params, base_action)
	else:
		final = MoveAndInteractProvider.build_specialized_action(actor, target, move_coord, move_cost, interaction_type, action_id, extra_params)

	# --- Enrichment (Shared across all paths) ---
	var unit_index := unit_manager.get_unit_index(actor)
	if not final.command_payload.has(GameConstants.Payload.UNIT_INDEX):
		final.command_payload[GameConstants.Payload.UNIT_INDEX] = unit_index

	if is_instance_valid(target) and attr_idx != -1:
		var combat_system = actor.get_combat_system()
		if combat_system:
			var forecast = combat_system.get_preview_forecast(actor, target, attr_idx, interaction_type)
			if forecast:
				combat_system.get_attack_quality(forecast)
				final.command_payload[GameConstants.Payload.FORECAST_RESULTS] = forecast.to_dict()
				final.command_payload[GameConstants.Payload.ATTRIBUTE_INDEX] = attr_idx

	return final

static func _create_skill_action(actor: Unit, target: Target, move_coord: Vector2i, move_cost: int, unit_manager: UnitManager, interaction_type: String, action_id: String, extra_params: Dictionary, base_action: PlayerAction) -> PlayerAction:
	var unit_index = unit_manager.get_unit_index(actor)
	var final = MoveAndInteractProvider.build_specialized_action(actor, target, move_coord, move_cost, interaction_type, action_id, extra_params)

	var is_aid_action := base_action.type == GameConstants.ActionType.AID
	if interaction_type == GameConstants.Activity.AID:
		is_aid_action = true
	if is_aid_action:
		final.command_id = GameConstants.ActionType.AID
		var target_index = unit_manager.get_unit_index(target)
		final.command_payload = {
			GameConstants.Payload.HELPER_INDEX: unit_index,
			GameConstants.Payload.TARGET_INDEX: target_index,
			GameConstants.Payload.ATTRIBUTE_INDEX: extra_params.get("attribute_index", 0)
		}
	else:
		final.command_id = GameConstants.ActionType.SKILL
		var skill = base_action.command_payload.get(GameConstants.Payload.SKILL)
		if skill == null:
			final.command_id = GameConstants.ActionType.NONE
			final.command_payload = {}
		else:
			final.command_payload = {
				GameConstants.Payload.UNIT_INDEX: unit_index,
				GameConstants.Payload.TARGET_COORD: target.get_grid_location(),
				GameConstants.Payload.SKILL: skill
			}

	if move_coord != GameConstants.INVALID_COORD:
		final.command_payload[GameConstants.Payload.TARGET_MOVE_COORD] = move_coord
	return final

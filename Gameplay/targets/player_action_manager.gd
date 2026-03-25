class_name PlayerActionManager
extends RefCounted

const AttackUnitCommand = preload("res://Gameplay/commands/attack_unit_command.gd")
const ConvinceUnitCommand = preload("res://Gameplay/commands/convince_unit_command.gd")
const LootCommand = preload("res://Gameplay/commands/loot_command.gd")
const ExploreCommand = preload("res://Gameplay/commands/explore_command.gd")
const VisitCommand = preload("res://Gameplay/commands/visit_command.gd")
const TrappedCommand = preload("res://Gameplay/commands/trapped_command.gd")
const WaitCommand = preload("res://Gameplay/commands/wait_command.gd")

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
		_append_location_action(actions, unit, reach_state)
		_append_loot_action(actions, unit, reach_state)
		_append_task_action(actions, unit, reach_state.action_origin)
		_append_skill_actions(actions, unit, weather_manager)
		if _dialogue_service: _dialogue_service.append_dialogue_actions(actions, unit, unit_manager)

	_append_wait_action(actions)
	return actions

static func _get_grid_axis(unit: Unit) -> int:
	return unit.grid_map.tile_set.tile_offset_axis if unit.grid_map and unit.grid_map.tile_set else TileSet.TILE_OFFSET_AXIS_VERTICAL

static func _append_combat_actions(actions: Array[PlayerAction], unit: Unit, unit_manager: UnitManager, reach_state: ReachableState, axis: int) -> void:
	CombatActionCalculator.new().append_combat_actions(actions, unit, unit_manager, reach_state, axis)

static func _append_location_action(actions: Array[PlayerAction], unit: Unit, reach: ReachableState) -> void:
	LocationActionProvider.new().append_location_action(actions, unit, reach)

static func _append_loot_action(actions: Array[PlayerAction], unit: Unit, reach: ReachableState) -> void:
	LootActionProvider.new().append_loot_action(actions, unit, reach)

static func _append_task_action(actions: Array[PlayerAction], unit: Unit, action_origin: Vector2i) -> void:
	TaskActionProvider.new().append_task_action(actions, unit, action_origin)

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

static func _append_wait_action(actions: Array[PlayerAction]) -> void:
	var action := PlayerAction.create(GameConstants.ActionType.WAIT, GameConstants.ActionIds.WAIT)
	action.command_id = GameConstants.Commands.CommandID.WAIT
	actions.append(action)

static func create_move_and_interact_action(base_action: PlayerAction, target: Target, move_data: Dictionary, unit_manager: UnitManager, attr_idx: int = -1, _attr_name: String = "") -> PlayerAction:
	var final: PlayerAction = base_action.clone()
	final.target_object = target

	var unit_index: int = unit_manager.get_unit_index(unit_manager.get_selected_unit()) # Assumption: selected unit is the one acting
	var target_index: int = unit_manager.get_unit_index(target) if target is Unit else GameConstants.INVALID_INDEX

	# 1. Setup movement if applicable
	if move_data.has(target):
		var m = move_data[target]
		final.type = GameConstants.ActionType.MOVE_AND_INTERACT
		final.action_id = GameConstants.ActionIds.MOVE_AND_INTERACT

		if m is Dictionary:
			final.move_cost = int(m.get("cost", 0))
		else:
			final.move_cost = int(m)

	# 2. Map Payload based on interaction type
	var itype = base_action.type
	if itype == GameConstants.ActionType.OPEN_ATTACK_MENU: itype = GameConstants.ActionType.ATTACK

	match itype:
		GameConstants.ActionType.ATTACK:
			final.command_id = GameConstants.Commands.CommandID.ATTACK
			final.command_payload = AttackUnitCommand.create_payload(unit_index, target_index, attr_idx)
		GameConstants.ActionType.CONVINCE:
			final.command_id = GameConstants.Commands.CommandID.CONVINCE
			final.command_payload = ConvinceUnitCommand.create_payload(unit_index, target_index)
		GameConstants.ActionType.GATHER:
			final.command_id = GameConstants.Commands.CommandID.LOOT
			final.command_payload = LootCommand.create_payload(unit_index, target.get_grid_location())
		GameConstants.ActionType.EXPLORE:
			final.command_id = GameConstants.Commands.CommandID.EXPLORE
			final.command_payload = ExploreCommand.create_payload(unit_index, base_action.target_to_task.get(target, ""))
		GameConstants.ActionType.VISIT:
			final.command_id = GameConstants.Commands.CommandID.VISIT
			final.command_payload = VisitCommand.create_payload(unit_index, base_action.target_to_task.get(target, ""))
		GameConstants.ActionType.SKILL:
			final.command_id = GameConstants.Commands.CommandID.USE_SKILL
			final.command_payload[GameConstants.Payload.TARGET_COORD] = target.get_grid_location()

	# 3. Add move coordinate for MOVE_AND_INTERACT
	if final.type == GameConstants.ActionType.MOVE_AND_INTERACT:
		var m = move_data.get(target)
		if m is Dictionary:
			final.command_payload[GameConstants.Payload.TARGET_MOVE_COORD] = m.get("coord", GameConstants.INVALID_COORD)
	
	return final

class_name HudActionExecutor
extends RefCounted

var _hud: Node
var _unit_manager: UnitManager
var _input_controller: InputController

func _init(hud: Node, unit_manager: UnitManager, input_controller: InputController) -> void:
	_hud = hud
	_unit_manager = unit_manager
	_input_controller = input_controller

func execute_action(action: UnitAction, current_unit: Unit, current_unit_index: int) -> bool:
	if action.type == UnitAction.Type.OPEN_ATTACK_MENU:
		_hud.menu_requested.emit("attack_menu", action)
		return true

	if action.type == UnitAction.Type.MOVE_AND_INTERACT:
		return await _execute_move_and_interact_action(action, current_unit, current_unit_index)

	if not _input_controller:
		return false

	var result = _try_execute_mapped_command(action, current_unit, current_unit_index)
	return _command_success(result)

func _try_execute_mapped_command(action: UnitAction, current_unit: Unit, current_unit_index: int) -> CommandResult:
	match action.type:
		UnitAction.Type.WAIT:
			return _run_input_command(GameConstants.Commands.WAIT)
		UnitAction.Type.ATTACK:
			return _execute_attack_command(action, current_unit_index)
		UnitAction.Type.AID:
			return _execute_aid_command(action, current_unit_index)
		UnitAction.Type.VISIT:
			return _run_input_command(GameConstants.Commands.VISIT, action)
		UnitAction.Type.EXPLORE:
			return _run_input_command(GameConstants.Commands.EXPLORE, action)
		UnitAction.Type.TRAPPED:
			return _run_input_command(GameConstants.Commands.TRAPPED, action)
		UnitAction.Type.CONVINCE:
			return _execute_convince_command(action, current_unit_index)
		UnitAction.Type.LOOT, UnitAction.Type.GATHER:
			return _execute_loot_command(action, current_unit, current_unit_index)
		UnitAction.Type.SKILL:
			return _execute_skill_command(action, current_unit_index)
		UnitAction.Type.TALK:
			return _execute_talk_command(action, current_unit_index)
	return null

func _run_input_command(command_name: String, payload = null) -> CommandResult:
	if _input_controller == null: return null
	# Special handling for UnitAction payload since InputController expects Dictionaries for now
	if payload is UnitAction:
		return _input_controller._execute_command(command_name, _convert_action_to_dict(payload))
	return _input_controller._execute_command(command_name, payload)

func _command_success(result) -> bool:
	return result is CommandResult and not result.is_failure()

func _execute_attack_command(action: UnitAction, current_unit_index: int) -> CommandResult:
	var target = action.target
	if not target or not _unit_manager: return null
	var target_idx = _unit_manager.get_unit_index(target)
	return _execute_attack_payload(current_unit_index, target_idx, action.attribute_index)

func _execute_attack_payload(attacker_idx: int, target_idx: int, attr_idx: int) -> CommandResult:
	if target_idx < 0: return null
	return _run_input_command(GameConstants.Commands.ATTACK, {
		"attacker_index": attacker_idx,
		"target_index": target_idx,
		"attribute_index": attr_idx
	})

func _execute_aid_command(action: UnitAction, current_unit_index: int) -> CommandResult:
	var target = action.target
	if not target or not _unit_manager: return null
	var target_idx = _unit_manager.get_unit_index(target)
	if target_idx < 0: return null
	return _run_input_command(GameConstants.Commands.AID, {
		"helper_index": current_unit_index,
		"target_index": target_idx,
		"attribute_index": action.attribute_index
	})

func _execute_convince_command(action: UnitAction, current_unit_index: int) -> CommandResult:
	var target = action.target
	if not target or not _unit_manager: return null
	var target_idx = _unit_manager.get_unit_index(target)
	return _execute_convince_payload(current_unit_index, target_idx)

func _execute_convince_payload(initiator_idx: int, target_idx: int) -> CommandResult:
	if target_idx < 0: return null
	return _run_input_command(GameConstants.Commands.CONVINCE, {
		"initiator_index": initiator_idx,
		"target_index": target_idx
	})

func _execute_loot_command(action: UnitAction, current_unit: Unit, current_unit_index: int) -> CommandResult:
	var coord = action.interact_target_coord
	if coord == GameConstants.INVALID_COORD and current_unit:
		coord = current_unit.get_grid_location()
	return _execute_loot_payload(current_unit_index, coord)

func _execute_loot_payload(looter_idx: int, coord: Vector2i) -> CommandResult:
	if coord == GameConstants.INVALID_COORD: return null
	return _run_input_command(GameConstants.Commands.LOOT, {
		"looter_index": looter_idx,
		"loot_coord": coord
	})

func _execute_skill_command(action: UnitAction, current_unit_index: int) -> CommandResult:
	var skill = action.skill
	if not skill: return null
	return _run_input_command(GameConstants.Commands.USE_SKILL, {
		"unit_index": current_unit_index,
		"skill": skill
	})

func _execute_talk_command(action: UnitAction, current_unit_index: int) -> CommandResult:
	var target_idx = action.target_index
	var dialogue_id = action.dialogue_id
	if target_idx < 0 or dialogue_id.is_empty(): return null
	return _run_input_command(GameConstants.Commands.TALK, {
		"initiator_index": action.initiator_index if action.initiator_index >= 0 else current_unit_index,
		"target_index": target_idx,
		"dialogue_id": dialogue_id
	})

func _execute_move_and_interact_action(action: UnitAction, current_unit: Unit, current_unit_index: int) -> bool:
	if _input_controller == null: return false
	var move_coord = action.target_move_coord
	if move_coord == GameConstants.INVALID_COORD: return false
	
	if not await _move_unit_to_coord(move_coord, current_unit, current_unit_index):
		return false

	match action.interact_action_type:
		UnitAction.Type.ATTACK:
			var target_idx = action.interact_target_uid
			var attr_idx = action.attribute_index
			return _command_success(_execute_attack_payload(current_unit_index, target_idx, attr_idx))
		UnitAction.Type.LOOT, UnitAction.Type.GATHER:
			var loot_coord = action.interact_target_coord
			if loot_coord == GameConstants.INVALID_COORD and current_unit:
				loot_coord = current_unit.get_grid_location()
			return _command_success(_execute_loot_payload(current_unit_index, loot_coord))
		UnitAction.Type.TRAPPED:
			return _command_success(_run_input_command(GameConstants.Interactions.TRAPPED, action))
		UnitAction.Type.EXPLORE:
			return _command_success(_run_input_command(GameConstants.Interactions.EXPLORE, action))
		UnitAction.Type.VISIT:
			return _command_success(_run_input_command(GameConstants.Interactions.VISIT, action))
		UnitAction.Type.CONVINCE:
			var target_idx = action.interact_target_uid
			return _command_success(_execute_convince_payload(current_unit_index, target_idx))
		_:
			return false

func _move_unit_to_coord(target_coord: Vector2i, _current_unit: Unit, current_unit_index: int) -> bool:
	if _input_controller == null or _unit_manager == null: return false
	var current_coord = _unit_manager.get_coord(current_unit_index)
	if current_coord == target_coord: return true
	
	var move_result = _input_controller._execute_command(GameConstants.Commands.MOVE_TO_COORD, {"coord": target_coord})
	if move_result == null or move_result.is_failure(): return false
	
	if _hud.has_method("_await_tentative_resolution"):
		await _hud.call("_await_tentative_resolution")
		
	var unit = _unit_manager.get_selected_unit()
	if unit == null: return false
	
	if not unit.movement.has_tentative_move():
		return _unit_manager.get_coord(current_unit_index) == target_coord
		
	var tentative_coord = unit.movement.get_tentative_grid_coord()
	if tentative_coord != target_coord:
		_input_controller._execute_command(GameConstants.Commands.CANCEL_MOVE)
		if _hud.has_method("_await_tentative_resolution"): await _hud.call("_await_tentative_resolution")
		return _unit_manager.get_coord(current_unit_index) == target_coord
		
	var confirm_result = _input_controller._execute_command(GameConstants.Commands.CONFIRM_MOVE)
	if confirm_result == null or confirm_result.is_failure(): return false
	if _hud.has_method("_await_tentative_resolution"): await _hud.call("_await_tentative_resolution")
	
	return _unit_manager.get_coord(current_unit_index) == target_coord

func _convert_action_to_dict(action: UnitAction) -> Dictionary:
	# Temporary bridge until InputController uses UnitAction
	return {
		"type": action.type, # This might need mapping if InputController expects strings
		"action_id": action.action_id,
		"target": action.target,
		"attribute_index": action.attribute_index,
		"skill": action.skill,
		"dialogue_id": action.dialogue_id,
		"target_index": action.target_index,
		"initiator_index": action.initiator_index,
		"task_id": action.task_id,
		"interact_target_coord": action.interact_target_coord
	}

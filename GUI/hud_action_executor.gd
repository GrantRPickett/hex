class_name HudActionExecutor
extends RefCounted

var _hud: Node
var _unit_manager: UnitManager
var _input_controller: InputController
var _sequencer: InteractionSequencer

func _init(hud: Node, unit_manager: UnitManager, input_controller: InputController, sequencer: InteractionSequencer) -> void:
	_hud = hud
	_unit_manager = unit_manager
	_input_controller = input_controller
	_sequencer = sequencer

func execute_action(action: PlayerAction, current_unit: Unit, current_unit_index: int) -> bool:
	if action.type == GameConstants.ActionType.OPEN_ATTACK_MENU:
		_hud.menu_requested.emit(GameConstants.MenuType.ATTACK, action)
		return true

	if action.type == GameConstants.ActionType.MOVE_AND_INTERACT:
		return await _execute_move_and_interact_action(action, current_unit, current_unit_index)

	if action.command_id == GameConstants.ActionType.NONE:
		GameLogger.warning(GameLogger.Category.UI, "[HudActionExecutor] Action %d has no command_id" % action.type)
		return false

	var result = _run_input_command(action.command_id, action.command_payload)
	return _command_success(result)

func _run_input_command(command_id: GameConstants.ActionType, payload = null) -> CommandResult:
	if _input_controller == null:
		return null
	return _input_controller.execute_command(command_id, payload)

func _command_success(result) -> bool:
	return result is CommandResult and not result.is_failure()

func _execute_move_and_interact_action(action: PlayerAction, current_unit: Unit, current_unit_index: int) -> bool:
	if _input_controller == null:
		return false

	var move_coord: Vector2i = action.command_payload.get(GameConstants.Payload.TARGET_MOVE_COORD, GameConstants.INVALID_COORD)
	if move_coord == GameConstants.INVALID_COORD:
		GameLogger.warning(GameLogger.Category.UI, "[HudActionExecutor] MOVE_AND_INTERACT requires TARGET_MOVE_COORD in payload")
		return false

	if not await _move_unit_to_coord(move_coord, current_unit, current_unit_index):
		return false

	# After moving, execute the interaction using the action's command payload
	if action.command_id != GameConstants.ActionType.NONE:
		var target_id = action.command_payload.get("target_id")
		var target = TargetDiscoveryService.get_target_by_id(target_id)
		var context = _input_controller.get_command_context()

		if _sequencer and is_instance_valid(target) and context:
			var combat_params = CombatResult.from_payload(action.command_payload, context)
			# Ensure metadata is set for the sequencer to resolve correctly
			if combat_params:
				combat_params.set_meta("action_type", action.command_payload.get("type", "unknown"))
				# Sequencer is visuals-only; avoid double HUD barks/feedback when mechanics execute after.
				combat_params.set_meta("suppress_hud_feedback", true)

			# Resolve interaction entirely through the sequencer
			await _sequencer.resolve_interaction(current_unit, target, combat_params)

			# Apply mechanics using the precomputed forecast payload (do not re-forecast here).
			var anim_service = current_unit._animation_service if is_instance_valid(current_unit) else null
			if anim_service:
				anim_service.set_suppress_requests(true)
			var result = _run_input_command(action.command_id, action.command_payload)
			if anim_service:
				anim_service.set_suppress_requests(false)
			return _command_success(result)
		else:
			return _command_success(_run_input_command(action.command_id, action.command_payload))

	return false

func _move_unit_to_coord(target_coord: Vector2i, _current_unit: Unit, current_unit_index: int) -> bool:
	if _input_controller == null or _unit_manager == null:
		return false
	var current_coord: Vector2i = _unit_manager.get_coord(current_unit_index)
	if current_coord == target_coord:
		return true

	var move_result = _input_controller.execute_command(GameConstants.ActionType.MOVE_TO_COORD, {
		GameConstants.Payload.UNIT_INDEX: current_unit_index,
		GameConstants.Payload.TARGET_COORD: target_coord
	})
	if move_result == null or move_result.is_failure():
		return false

	# If MOVE_TO_COORD set a tentative move, we must confirm it to actually reach the destination
	if _current_unit and _current_unit.movement.has_tentative_move():
		_input_controller.execute_command(GameConstants.ActionType.CONFIRM_MOVE)

	if _hud.has_method("_await_tentative_resolution"):
		await _hud.call("_await_tentative_resolution")

	var unit: Unit = _unit_manager.get_selected_unit()
	if unit == null:
		return false
	return _unit_manager.get_coord(current_unit_index) == target_coord

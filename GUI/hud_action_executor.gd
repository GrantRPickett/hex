class_name HudActionExecutor
extends RefCounted

var _hud: Node
var _unit_manager: UnitManager
var _input_controller: InputController

func _init(hud: Node, unit_manager: UnitManager, input_controller: InputController) -> void:
	_hud = hud
	_unit_manager = unit_manager
	_input_controller = input_controller

func execute_action(action: PlayerAction, current_unit: Unit, current_unit_index: int) -> bool:
	if action.type == GameConstants.ActionType.OPEN_ATTACK_MENU:
		_hud.menu_requested.emit("attack_menu", action)
		return true

	if action.type == GameConstants.ActionType.MOVE_AND_INTERACT:
		return await _execute_move_and_interact_action(action, current_unit, current_unit_index)

	if action.command_id == GameConstants.Commands.CommandID.NONE:
		# Fallback for actions that aren't mapped to commands yet or are purely UI
		return false

	var result = _run_input_command(action.command_id, action.command_payload)
	return _command_success(result)

func _run_input_command(command_id: GameConstants.Commands.CommandID, payload = null) -> CommandResult:
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
		return false
	
	if not await _move_unit_to_coord(move_coord, current_unit, current_unit_index):
		return false

	# After moving, execute the interaction using the action's command payload
	if action.command_id != GameConstants.Commands.CommandID.NONE:
		return _command_success(_run_input_command(action.command_id, action.command_payload))
			
	return false

func _move_unit_to_coord(target_coord: Vector2i, _current_unit: Unit, current_unit_index: int) -> bool:
	if _input_controller == null or _unit_manager == null: 
		return false
	var current_coord: Vector2i = _unit_manager.get_coord(current_unit_index)
	if current_coord == target_coord: 
		return true

	var move_result = _input_controller.execute_command(GameConstants.Commands.CommandID.MOVE_TO_COORD, {
		GameConstants.Payload.UNIT_INDEX: current_unit_index,
		GameConstants.Payload.TARGET_COORD: target_coord
	})
	if move_result == null or move_result.is_failure(): 
		return false

	# If MOVE_TO_COORD set a tentative move, we must confirm it to actually reach the destination
	if _current_unit and _current_unit.movement.has_tentative_move():
		_input_controller.execute_command(GameConstants.Commands.CommandID.CONFIRM_MOVE)

	if _hud.has_method("_await_tentative_resolution"):
		await _hud.call("_await_tentative_resolution")

	var unit: Unit = _unit_manager.get_selected_unit()
	if unit == null: 
		return false
	return _unit_manager.get_coord(current_unit_index) == target_coord

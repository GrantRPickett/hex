## Input state for combat/unit-selection mode.
class_name CombatInputState
extends InputState

func handle_action(command_id: GameConstants.Commands.CommandID, payload: Dictionary = {}) -> CommandResult:
	var um: UnitManager = _context.unit_manager
	var tc: TurnController = _context.turn_controller
	var selected_index: int = um.get_selected_index()

	# 1. Selection and Camera commands always pass through
	var passthrough = [
		GameConstants.Commands.CommandID.SELECT_INDEX,
		GameConstants.Commands.CommandID.SELECTION_CYCLE,
		GameConstants.Commands.CommandID.TOGGLE_FREE_CAM,
		GameConstants.Commands.CommandID.ZOOM_CAMERA,
		GameConstants.Commands.CommandID.JOY_MOVE,
		GameConstants.Commands.CommandID.TOGGLE_ENEMY_RANGE
	]
	if command_id in passthrough:
		return _router.execute(command_id, payload)

	# 2. Check Auto-battle/Turn lock constraints
	if tc.is_player_auto_battle_enabled() or tc.is_player_auto_control_locked():
		var reason := "Auto battle resolving action" if tc.is_player_auto_control_locked() else "Auto battle active"
		return CommandResult.precondition_failed(reason)

	# 3. Check if current unit can act
	var is_player_unit: bool = um.is_player_controlled(selected_index)
	var is_player_turn: bool = tc.can_act_on_index(selected_index)

	if not (is_player_unit and is_player_turn):
		return CommandResult.precondition_failed("Unit cannot act")

	# 4. Handle State-Changing commands (Checkpoints, Turn Locking)
	var locking_commands = [
		GameConstants.Commands.CommandID.WAIT,
		GameConstants.Commands.CommandID.CONFIRM_MOVE,
		GameConstants.Commands.CommandID.USE_SKILL,
		GameConstants.Commands.CommandID.INTERACT,
		GameConstants.Commands.CommandID.AID,
		GameConstants.Commands.CommandID.MOVE_AND_INTERACT
	]
	var result: CommandResult = _router.execute(command_id, payload)

	if result.is_success() and command_id in locking_commands:
		tc.lock_active_player_unit(selected_index)

	return result

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_undo"):
		_manager.emit_signal("undo_requested")
	elif event.is_action_pressed("ui_redo"):
		_manager.emit_signal("redo_requested")

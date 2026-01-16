class_name JoyMoveCommand
extends GameCommand

const GameCommand := preload("res://Gameplay/input_commands/game_command.gd")

func execute(context: GameCommandContext, payload = null) -> void:
	if context == null or payload == null:
		return
	var axis: Vector2 = payload.get("axis", Vector2.ZERO)
	if axis == Vector2.ZERO:
		return
	var unit_manager = context.unit_manager
	var hex_navigator = context.hex_navigator
	var camera_controller = context.camera_controller
	var move_controller = context.move_controller
	var grid = context.grid
	if unit_manager == null or hex_navigator == null or camera_controller == null or move_controller == null or grid == null:
		return
	var action: String = hex_navigator.get_action_from_joy_axis(axis, camera_controller.get_rotation(), unit_manager.get_selected_coord(), grid)
	if action.is_empty():
		return
	move_controller.request_move(action)

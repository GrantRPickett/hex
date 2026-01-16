
class_name MoveActionCommand
extends GameCommand

const GameCommand := preload("res://Gameplay/input_commands/game_command.gd")

func execute(context: GameCommandContext, action = null) -> void:
	if context == null or action == null:
		return
	var unit_manager = context.unit_manager
	var hex_navigator = context.hex_navigator
	var camera_controller = context.camera_controller
	var move_controller = context.move_controller
	var grid = context.grid
	if unit_manager == null or hex_navigator == null or camera_controller == null or move_controller == null or grid == null:
		return
	var from_coord  = unit_manager.get_selected_coord()
	var mapped_action  = hex_navigator.map_action_by_camera(action, from_coord, camera_controller.get_rotation(), grid)
	move_controller.request_move(mapped_action)

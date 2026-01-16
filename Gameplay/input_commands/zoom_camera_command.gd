class_name ZoomCameraCommand
extends GameCommand

const GameCommand := preload("res://Gameplay/input_commands/game_command.gd")

func execute(context: GameCommandContext, payload = null) -> void:
	if context == null or context.camera_controller == null:
		return
	context.camera_controller.zoom(payload)

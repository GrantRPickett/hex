class_name ToggleFreeCamCommand
extends GameCommand

const GameCommand := preload("res://Gameplay/input_commands/game_command.gd")

func execute(context: GameCommandContext, _payload = null) -> void:
	if context == null or context.camera_controller == null:
		return
	context.camera_controller.toggle_free_cam()

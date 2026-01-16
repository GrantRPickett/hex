
class_name SelectIndexCommand
extends GameCommand

const GameCommand := preload("res://Gameplay/input_commands/game_command.gd")

func execute(context: GameCommandContext, payload = null) -> void:
	if context == null or context.unit_manager == null or context.turn_controller == null:
		return
	var index: int = payload
	if not context.turn_controller.can_act_on_index(index): return
	context.unit_manager.select_index(index)

class_name WaitCommand
extends GameCommand

const GameCommand := preload("res://Gameplay/input_commands/game_command.gd")

func execute(context: GameCommandContext, _payload = null) -> void:
	if context == null:
		return
	var goal_controller = context.goal_controller
	var move_controller = context.move_controller
	var unit_manager = context.unit_manager
	var turn_controller = context.turn_controller
	if goal_controller == null or move_controller == null or unit_manager == null or turn_controller == null:
		return
	if goal_controller.is_goal_reached() or move_controller.is_move_locked():
		return
	var selected_idx  = unit_manager.get_selected_index()
	if not turn_controller.can_act_on_index(selected_idx):
		return
	turn_controller.complete_player_activation(selected_idx)

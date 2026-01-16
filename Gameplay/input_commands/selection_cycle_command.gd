class_name SelectionCycleCommand
extends GameCommand

const GameCommand := preload("res://Gameplay/input_commands/game_command.gd")

func execute(context: GameCommandContext, payload = null) -> void:
	if context == null or context.unit_manager == null:
		return
	var unit_manager = context.unit_manager
	var count  = unit_manager.get_unit_count()
	if count <= 1:
		return
	var direction: int = payload
	var turn_controller = context.turn_controller
	if turn_controller == null or not turn_controller.is_enabled():
		unit_manager.cycle_selection(direction)
		return
	var start  = unit_manager.get_selected_index()
	var current  = start
	for _i in range(count):
		current = int((current + direction) % count)
		if current < 0:
			current = count - 1
		if not turn_controller.can_act_on_index(current):
			continue
		if unit_manager.is_player_controlled(current):
			unit_manager.select_index(current)
			return

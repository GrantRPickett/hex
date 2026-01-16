class_name PrimaryActionCommand
extends GameCommand

const GameCommand := preload("res://Gameplay/input_commands/game_command.gd")

func execute(context: GameCommandContext, payload = null) -> void:
	if context == null:
		return
	var grid = context.grid
	var unit_manager = context.unit_manager
	var move_controller = context.move_controller
	var hex_navigator = context.hex_navigator
	var turn_controller = context.turn_controller
	if grid == null or unit_manager == null or move_controller == null or hex_navigator == null or turn_controller == null:
		return
	var cell: Vector2i = grid.local_to_map(grid.to_local(payload))
	var idx  = unit_manager.index_of_unit_at(cell)
	if idx != -1:
		if unit_manager.is_player_controlled(idx) and turn_controller.can_act_on_index(idx):
			unit_manager.select_index(idx)
		return
	var from: Vector2i = unit_manager.get_selected_coord()
	var dir_map: Dictionary = hex_navigator.get_direction_map(from, grid)
	var diff: Vector2i = cell - from
	for action in dir_map.keys():
		if dir_map[action] == diff:
			move_controller.request_move(action)
			return

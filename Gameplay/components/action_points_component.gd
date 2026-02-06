class_name ActionPointsComponent
extends Resource

signal willpower_changed

@export var max_willpower: int = 10
@export var willpower: int = 10
@export var movement_points: int = 6

var _turn_movement_points: int = 0
var _can_act_this_turn: bool = true

func _init() -> void:
	refresh_for_new_round()

func refresh_for_new_round() -> void:
	_turn_movement_points = movement_points
	_can_act_this_turn = true

func has_move_available() -> bool:
	return _turn_movement_points > 0

func has_action_available() -> bool:
	return _can_act_this_turn

func consume_move(cost: int = 1) -> void:
	_turn_movement_points = max(0, _turn_movement_points - cost)

func consume_action() -> void:
	_can_act_this_turn = false

func adjust_remaining_movement(delta: int) -> void:
	_turn_movement_points = max(0, _turn_movement_points + delta)

func block_movement_this_turn() -> void:
	_turn_movement_points = 0

func block_action_this_turn() -> void:
	_can_act_this_turn = false

func get_remaining_movement_points() -> int:
	return _turn_movement_points

func get_movement_points() -> int:
	return movement_points

func set_movement_points(value: int) -> void:
	movement_points = max(0, value)
	if _turn_movement_points > movement_points:
		_turn_movement_points = movement_points

func get_willpower() -> int:
	return willpower

func set_willpower(value: int) -> void:
	var old_willpower: int = willpower
	willpower = clamp(value, 0, max_willpower)
	if old_willpower != willpower:
		willpower_changed.emit()
func get_max_willpower() -> int:
	return max_willpower

func set_max_willpower(value: int) -> void:
	var clamped: int = max(0, value)
	if clamped == max_willpower:
		return
	max_willpower = clamped
	willpower = clamp(willpower, 0, max_willpower)
	willpower_changed.emit()

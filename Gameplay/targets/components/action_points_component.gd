class_name ActionPointsComponent
extends Resource

signal action_consumed

@export var movement_points: int = 6
@export var max_reactions: int = 1

var _turn_movement_points: int = 0
var _can_act_this_turn: bool = true
var _reactions_available: int = 1
var _owner_unit: Unit

func _init() -> void:
	pass

func set_owner_unit(unit: Unit) -> void:
	_owner_unit = unit

func refresh_for_new_round() -> void:
	_turn_movement_points = movement_points
	_can_act_this_turn = true
	_reactions_available = max_reactions

func has_move_available() -> bool:
	return _turn_movement_points > 0

func has_action_available() -> bool:
	return _can_act_this_turn

func has_reaction_available() -> bool:
	return _reactions_available > 0

func get_reactions_available() -> int:
	return _reactions_available

func get_max_reactions() -> int:
	return max_reactions

func set_max_reactions(value: int) -> void:
	var delta = value - max_reactions
	max_reactions = max(0, value)
	if delta > 0:
		_reactions_available += delta
	elif _reactions_available > max_reactions:
		_reactions_available = max_reactions

func consume_move(cost: int = 1) -> void:
	_turn_movement_points = max(0, _turn_movement_points - cost)

func consume_action() -> void:
	_can_act_this_turn = false
	action_consumed.emit()

func consume_reaction() -> void:
	_reactions_available = max(0, _reactions_available - 1)

func adjust_reactions_available(delta: int) -> void:
	_reactions_available = max(0, _reactions_available + delta)

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
	var delta = value - movement_points
	movement_points = max(0, value)
	if delta > 0:
		_turn_movement_points += delta
	elif _turn_movement_points > movement_points:
		_turn_movement_points = movement_points

class_name TurnSystem
extends RefCounted

enum Side {
	PLAYER,
	ENEMY,
	NEUTRAL
}

var _controller

func _init(controller) -> void:
	_controller = controller

func get_current_round() -> int:
	return _controller.get_round() if _controller else 1

func get_current_unit_index() -> int:
	return _controller.get_current_unit_index() if _controller else -1

func get_current_side() -> Side:
	if _controller:
		return _controller.get_current_side() as Side
	return Side.NEUTRAL as Side

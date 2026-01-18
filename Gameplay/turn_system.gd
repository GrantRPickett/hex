class_name TurnSystem
extends RefCounted

var _controller: TurnController

func _init(controller: TurnController) -> void:
	_controller = controller

func get_current_round() -> int:
	return _controller.get_round() if _controller else 1

func get_current_unit_index() -> int:
	return _controller.get_current_unit_index() if _controller else -1
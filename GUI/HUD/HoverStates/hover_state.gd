class_name HoverState
extends RefCounted

func can_enter(_controller: HUDController, _cell: Vector2i) -> bool:
	return false

func enter(controller: HUDController, cell: Vector2i) -> void:
	update(controller, cell)

func update(_controller: HUDController, _cell: Vector2i) -> void:
	pass

func exit(_controller: HUDController) -> void:
	pass

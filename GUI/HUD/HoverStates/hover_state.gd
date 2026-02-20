class_name HoverState
extends RefCounted

func can_enter(_controller: Node, _cell: Vector2i) -> bool:
	return false

func enter(controller: Node, cell: Vector2i) -> void:
	update(controller, cell)

func update(_controller: Node, _cell: Vector2i) -> void:
	pass

func exit(_controller: Node) -> void:
	pass

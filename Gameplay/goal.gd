class_name Goal
extends Target

enum Type {
	PRIMARY,
	SECONDARY
}

var visual: Node2D
var coord: Vector2i
var description: String
var type: Type

func _init(visual_node: Node2D, coordinate: Vector2i, desc: String = "", goal_type: Type = Type.PRIMARY) -> void:
	visual = visual_node
	coord = coordinate
	description = desc
	type = goal_type

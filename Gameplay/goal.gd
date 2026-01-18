class_name Goal
extends Node2D

@export var required_attribute: String = "grit"
@export var required_amount: int = 100

var _grid: TileMapLayer

## Returns the coordinate as a Vector2i (from the Node2D position)
var coord: Vector2i:
	get:
		if _grid:
			return _grid.local_to_map(position)
		var parent = get_parent()
		if parent is TileMapLayer:
			return parent.local_to_map(position)
		return Vector2i(position)

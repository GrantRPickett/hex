class_name Target
extends Node2D

@export var sprite: Sprite2D
@export var grid_map: TileMapLayer

func get_grid_location() -> Vector2i:
	if grid_map:
		return grid_map.local_to_map(position)

	var parent = get_parent()
	if parent is TileMapLayer:
		return parent.local_to_map(position)
	return Vector2i.ZERO

func snap_to_grid() -> void:
	var grid: TileMapLayer = grid_map
	if not grid and get_parent() is TileMapLayer:
		grid = get_parent()

	if grid:
		var coord := grid.local_to_map(position)
		position = grid.map_to_local(coord)

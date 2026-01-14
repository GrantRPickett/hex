class_name GoalManager
extends Node

var _goal_targets: Array[Vector2i] = []
var _sprites: Array[Sprite2D] = []
var _grid: TileMapLayer

func setup(goal_coords: Array[Vector2i], sprites: Array[Sprite2D], grid: TileMapLayer) -> void:
	_goal_targets = goal_coords.duplicate()
	_sprites = sprites
	_grid = grid
	_update_visuals()

func _update_visuals() -> void:
	if not is_instance_valid(_grid):
		return

	for i in range(_sprites.size()):
		var sprite = _sprites[i]
		if i < _goal_targets.size():
			sprite.visible = true
			sprite.position = _grid.map_to_local(_goal_targets[i])
		else:
			sprite.visible = false

func get_target(index: int) -> Vector2i:
	if index >= 0 and index < _goal_targets.size():
		return _goal_targets[index]
	return Vector2i(-999, -999)

func set_target(index: int, coord: Vector2i) -> void:
	if index >= 0 and index < _goal_targets.size():
		_goal_targets[index] = coord
		_update_visuals()
	elif index == 0 and _goal_targets.is_empty():
		_goal_targets.append(coord)
		_update_visuals()

func get_targets() -> Array[Vector2i]:
	return _goal_targets

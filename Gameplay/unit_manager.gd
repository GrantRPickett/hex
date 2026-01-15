class_name UnitManager
extends Node

signal selection_changed(index: int)
signal unit_moved(index: int, new_coord: Vector2i)

var _sprites: Array[Sprite2D] = []
var _coords: Array[Vector2i] = []
var _goals_reached: Array[bool] = []
var _is_player_controlled: Array[bool] = []
var _selected_index: int = 0

func reset() -> void:
	_sprites.clear()
	_coords.clear()
	_goals_reached.clear()
	_is_player_controlled.clear()
	_selected_index = 0

func add_unit(sprite: Sprite2D, coord: Vector2i, is_player: bool) -> void:
	_sprites.append(sprite)
	_coords.append(coord)
	_goals_reached.append(false)
	_is_player_controlled.append(is_player)

func get_unit_count() -> int:
	return _sprites.size()

func get_selected_index() -> int:
	return _selected_index

func get_selected_coord() -> Vector2i:
	if _coords.is_empty():
		return Vector2i.ZERO
	return _coords[_selected_index]

func get_selected_sprite() -> Sprite2D:
	if _selected_index >= 0 and _selected_index < _sprites.size():
		return _sprites[_selected_index]
	return null

func get_unit_sprite(index: int) -> Sprite2D:
	if index >= 0 and index < _sprites.size():
		return _sprites[index]
	return null

func get_coord(index: int) -> Vector2i:
	if index >= 0 and index < _coords.size():
		return _coords[index]
	return Vector2i.ZERO

func set_coord(index: int, coord: Vector2i) -> void:
	if index >= 0 and index < _coords.size():
		_coords[index] = coord
		unit_moved.emit(index, coord)

func is_occupied(coord: Vector2i, ignore_index: int = -1) -> bool:
	for i in range(_coords.size()):
		if i == ignore_index:
			continue
		if _coords[i] == coord:
			return true
	return false

func is_player_controlled(index: int) -> bool:
	if index >= 0 and index < _is_player_controlled.size():
		return _is_player_controlled[index]
	return false

func set_player_controlled(index: int, is_controlled: bool) -> void:
	if index >= 0 and index < _is_player_controlled.size():
		_is_player_controlled[index] = is_controlled

func set_goal_reached(index: int, reached: bool) -> void:
	if index >= 0 and index < _goals_reached.size():
		_goals_reached[index] = reached

func are_all_goals_reached() -> bool:
	var has_player := false
	for i in range(_goals_reached.size()):
		if i >= _is_player_controlled.size() or not _is_player_controlled[i]:
			continue
		has_player = true
		if not _goals_reached[i]:
			return false
	return has_player

func is_goal_reached(index: int) -> bool:
	if index >= 0 and index < _goals_reached.size():
		return _goals_reached[index]
	return false

func select_index(index: int) -> void:
	if index >= 0 and index < _sprites.size() and _is_player_controlled[index]:
		_selected_index = index
		selection_changed.emit(_selected_index)

func cycle_selection(direction: int) -> void:
	var count := _sprites.size()
	if count <= 1:
		return

	var start := _selected_index
	var current := _selected_index

	for i in range(count):
		current = int((current + direction) % count)
		if current < 0:
			current = count - 1

		if _is_player_controlled[current]:
			_selected_index = current
			selection_changed.emit(_selected_index)
			return

		if current == start:
			break

func index_of_unit_at(coord: Vector2i) -> int:
	for i in range(_coords.size()):
		if _coords[i] == coord:
			return i
	return -1

class_name UnitManager
extends Node

signal selection_changed(index: int)
signal unit_moved(index: int, new_coord: Vector2i)
signal unit_removed(unit: Unit)
signal unit_spawn_requested(unit: Unit)

var _units: Array[Unit]
var _coords: Array[Vector2i]
var _is_player_controlled: Array[bool]
var _selected_index: int

func _init() -> void:
	_units = []
	_coords = []
	_is_player_controlled = []
	_selected_index = 0

func reset() -> void:
	for unit in _units:
		if is_instance_valid(unit):
			unit.queue_free()
	_units.clear()
	_coords.clear()
	_is_player_controlled.clear()
	_selected_index = 0

func add_unit(unit: Unit, coord: Vector2i, is_player: bool) -> void:
	_units.append(unit)
	_coords.append(coord)
	_is_player_controlled.append(is_player)

func remove_unit(unit: Unit) -> void:
	var index = _units.find(unit)
	if index == -1:
		return

	_units.remove_at(index)
	_coords.remove_at(index)
	_is_player_controlled.remove_at(index)

	# Adjust selection if necessary
	if _selected_index >= _units.size():
		_selected_index = max(0, _units.size() - 1)
		selection_changed.emit(_selected_index)
	elif index < _selected_index:
		_selected_index -= 1

	unit_removed.emit(unit)
	unit.queue_free()

func get_unit_count() -> int:
	return _units.size()

func get_units() -> Array[Unit]:
	return _units

func get_selected_index() -> int:
	return _selected_index

func get_selected_coord() -> Vector2i:
	if _coords.is_empty():
		return Vector2i.ZERO
	return _coords[_selected_index]

func get_selected_unit() -> Unit:
	if _selected_index >= 0 and _selected_index < _units.size():
		return _units[_selected_index]
	return null

func get_selected_sprite() -> Unit:
	return get_selected_unit()

func get_unit(index: int) -> Unit:
	if index >= 0 and index < _units.size():
		return _units[index]
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

func select_index(index: int) -> void:
	if index >= 0 and index < _units.size() and _is_player_controlled[index]:
		_selected_index = index
		selection_changed.emit(_selected_index)

func cycle_selection(direction: int) -> void:
	var count := _units.size()
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

func get_unit_index(unit: Unit) -> int:
	return _units.find(unit)

func index_of_unit_at(coord: Vector2i) -> int:
	for i in range(_coords.size()):
		if _coords[i] == coord:
			return i
	return -1

func create_memento() -> Dictionary:
	var units_data: Array[Dictionary] = []
	for i in range(_units.size()):
		var unit = _units[i]
		if is_instance_valid(unit):
			units_data.append({
				"scene_path": unit.scene_file_path,
				"coord": _coords[i],
				"is_player": _is_player_controlled[i],
				"data": unit.create_memento()
			})

	return {
		"units": units_data,
		"selected_index": _selected_index
	}

func restore_from_memento(memento: Dictionary) -> void:
	reset()

	var units_data = memento.get("units", [])
	for entry in units_data:
		var scene_path = entry.get("scene_path", "")
		if scene_path != "" and ResourceLoader.exists(scene_path):
			var scene = load(scene_path)
			var unit = scene.instantiate() as Unit
			if unit:
				unit.restore_from_memento(entry.get("data", {}))
				add_unit(unit, entry.get("coord", Vector2i.ZERO), entry.get("is_player", false))
				unit_spawn_requested.emit(unit)

	_selected_index = memento.get("selected_index", 0)
	selection_changed.emit(_selected_index)

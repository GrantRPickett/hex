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
var _pos_to_unit: Dictionary
var _faction_leaders: Dictionary = {}
var _rosters: Dictionary = {}

func _init() -> void:
	_units = []
	_coords = []
	_is_player_controlled = []
	_pos_to_unit = {}
	_selected_index = -1

func reset() -> void:
	for unit in _units:
		if is_instance_valid(unit):
			unit.queue_free()
	_units.clear()
	_coords.clear()
	_is_player_controlled.clear()
	_pos_to_unit.clear()
	_faction_leaders.clear()
	_rosters.clear()
	_selected_index = -1

func add_unit(unit: Unit, coord: Vector2i, is_player: bool) -> void:
	if is_occupied(coord):
		push_warning("UnitManager: Cell %s is already occupied. Cannot add unit '%s'." % [coord, unit.name])
		return

	_units.append(unit)
	_coords.append(coord)
	_pos_to_unit[coord] = unit
	_is_player_controlled.append(is_player)
	if unit is Target:
		(unit as Target).set_external_grid_coord(coord)
	if unit is Unit and unit.faction == Unit.Faction.NEUTRAL and unit.has_method("reset_neutral_loyalty"):
		unit.loyalty.reset_neutral_loyalty()
	if unit is Unit and unit.is_faction_leader(unit.faction):
		set_faction_leader(unit, unit.faction, true)

	if _selected_index == -1 and is_player:
		_selected_index = _units.size() - 1
		selection_changed.emit(_selected_index)
	unit_spawn_requested.emit(unit)

func set_roster_for_faction(faction: Unit.Faction, roster: UnitRoster) -> void:
	if roster == null:
		_rosters.erase(faction)
		return
	_rosters[faction] = roster

func get_roster_for_faction(faction: Unit.Faction) -> UnitRoster:
	var roster = _rosters.get(faction)
	return roster if is_instance_valid(roster) else null

func remove_unit(unit: Unit) -> void:
	var index = _units.find(unit)
	if index == -1:
		return
	for faction in _faction_leaders.keys():
		if _faction_leaders[faction] == unit:
			_faction_leaders.erase(faction)

	var coord = _coords[index]
	_pos_to_unit.erase(coord)

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
	return _units.duplicate()

func get_units_by_faction(faction_to_find: Unit.Faction) -> Array[Unit]:
	var result: Array[Unit] = []
	for unit in _units:
		if is_instance_valid(unit) and unit.faction == faction_to_find:
			result.append(unit)
	return result

func get_player_units() -> Array[Unit]:
	return get_units_by_faction(Unit.Faction.PLAYER)

func get_enemy_units() -> Array[Unit]:
	return get_units_by_faction(Unit.Faction.ENEMY)

func get_neutral_units() -> Array[Unit]:
	return get_units_by_faction(Unit.Faction.NEUTRAL)

func reset_all_neutral_loyalties() -> void:
	var neutrals = get_neutral_units()
	for unit in neutrals:
		if is_instance_valid(unit) and unit.has_method("reset_neutral_loyalty"):
			unit.loyalty.reset_neutral_loyalty()

func set_faction_leader(unit: Unit, faction: Unit.Faction, enabled: bool = true) -> void:
	if unit == null:
		return
	var previous: Unit = _faction_leaders.get(faction)
	if not enabled:
		if previous == unit:
			_faction_leaders.erase(faction)
		if unit.has_method("set_faction_leader"):
			unit.set_faction_leader(faction, false)
		return
	if is_instance_valid(previous) and previous != unit and previous.has_method("set_faction_leader"):
		previous.set_faction_leader(faction, false)
	_faction_leaders[faction] = unit
	if unit.has_method("set_faction_leader"):
		unit.set_faction_leader(faction, true)

func get_faction_leader(faction: Unit.Faction) -> Unit:
	var leader = _faction_leaders.get(faction)
	return leader if is_instance_valid(leader) else null

func get_selected_index() -> int:
	return _selected_index

func get_selected_coord() -> Vector2i:
	return get_coord(_selected_index)

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
	return Vector2i(-1, -1)

func set_coord(index: int, coord: Vector2i) -> void:
	if index >= 0 and index < _coords.size():
		if is_occupied(coord, index):
			push_warning("UnitManager: Cell %s is already occupied. Cannot move unit %d." % [coord, index])
			return

		var old_coord = _coords[index]
		_pos_to_unit.erase(old_coord)
		_coords[index] = coord
		_pos_to_unit[coord] = _units[index]
		if _units[index] is Target:
			(_units[index] as Target).set_external_grid_coord(coord)
		unit_moved.emit(index, coord)

func is_occupied(coord: Vector2i, ignore_index: int = -1) -> bool:
	var unit = _pos_to_unit.get(coord)
	if unit == null:
		return false
	if ignore_index != -1 and ignore_index >= 0 and ignore_index < _units.size():
		if unit == _units[ignore_index]:
			return false
	return true

func get_unit_at_coord(coord: Vector2i) -> Unit:
	return _pos_to_unit.get(coord, null)

func is_player_controlled(index: int) -> bool:
	if index >= 0 and index < _is_player_controlled.size():
		return _is_player_controlled[index]
	return false

func set_player_controlled(index: int, is_controlled: bool) -> void:
	if index >= 0 and index < _is_player_controlled.size():
		_is_player_controlled[index] = is_controlled

func force_select_index(index: int) -> void:
	if index >= 0 and index < _units.size():
		_selected_index = index
		selection_changed.emit(_selected_index)

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

func can_player_act(index: int) -> bool:
	if index < 0 or index >= _units.size():
		return false
	return _is_player_controlled[index]

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
				add_unit(unit, entry.get("coord", Vector2i(-999, -999)), entry.get("is_player", false))
				unit_spawn_requested.emit(unit)

	_selected_index = memento.get("selected_index", 0)
	if _selected_index >= 0 and _selected_index < _units.size():
		selection_changed.emit(_selected_index)
	else:
		_selected_index = -1
		selection_changed.emit(_selected_index)

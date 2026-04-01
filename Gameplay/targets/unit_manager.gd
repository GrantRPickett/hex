class_name UnitManager
extends Node

signal unit_spawn_requested(unit: Unit)
signal unit_added(unit: Unit)
signal unit_moved(index: int, coord: Vector2i)
signal selection_changed(index: int)
signal unit_removed(unit: Unit)

var _units: Array[Unit] = []
var _coords: Array[Vector2i] = []
var _is_player_controlled: Array[bool] = []
var _pos_to_unit: Dictionary = {}
var _selected_index: int = GameConstants.INVALID_INDEX
var _is_batch_placement: bool = false
var _rosters: Dictionary = {}

var _active_faction_boosts: Dictionary = {} # faction_id -> boost_amount
var _neutral_spawn_count: int = 0
var grid_query_service: GridQueryService
var terrain_map: TerrainMap

func reset() -> void:
	_active_faction_boosts.clear()
	for unit in _units:
		if is_instance_valid(unit) and not unit.is_queued_for_deletion():
			unit.queue_free()
	_units.clear()
	_coords.clear()
	_is_player_controlled.clear()
	_pos_to_unit.clear()
	_selected_index = GameConstants.INVALID_INDEX

func begin_batch_placement() -> void:
	_is_batch_placement = true

func end_batch_placement() -> void:
	_is_batch_placement = false

func add_unit(unit: Unit, coord: Vector2i, player_controlled: bool = false) -> void:
	if unit == null:
		return

	var spawn_coord = coord
	if is_occupied(spawn_coord):
		GameLogger.debug(GameLogger.Category.COMBAT, "[UnitManager] Cell %s is already occupied. Finding nearest empty cell..." % spawn_coord)
		spawn_coord = get_nearest_empty_coord(spawn_coord)
		if spawn_coord == GameConstants.INVALID_COORD:
			GameLogger.error(GameLogger.Category.COMBAT, "[UnitManager] FAILED to find empty cell for unit %s spawn near %s!" % [unit.unit_name, coord])
			unit.queue_free()
			return
		GameLogger.debug(GameLogger.Category.COMBAT, "[UnitManager] Redirecting unit %s spawn to %s" % [unit.unit_name, spawn_coord])

	_units.append(unit)
	_coords.append(spawn_coord)
	_is_player_controlled.append(player_controlled)
	_pos_to_unit[spawn_coord] = unit
	
	if unit.faction == GameConstants.Faction.NEUTRAL:
		unit.spawn_index = _neutral_spawn_count
		_neutral_spawn_count += 1
	
	if unit is Target:
		(unit as Target).set_external_grid_coord(spawn_coord)
		unit.global_position = unit.grid_map.map_to_local(spawn_coord) if is_instance_valid(unit.grid_map) else unit.global_position

	# Apply any active faction boosts
	if _active_faction_boosts.has(unit.faction):
		_apply_unit_stat_boost(unit, _active_faction_boosts[unit.faction])

	GameLogger.debug(GameLogger.Category.MAP, "[UnitManager] Added unit %s at coord %s (Global: %s)" % [unit.unit_name, spawn_coord, unit.global_position])

	if player_controlled and _selected_index == GameConstants.INVALID_INDEX:
		_selected_index = _units.size() - 1
		selection_changed.emit(_selected_index)
	
	unit_added.emit(unit)

func get_nearest_empty_coord(requested_coord: Vector2i, max_radius: int = 5) -> Vector2i:
	if grid_query_service:
		return grid_query_service.get_nearest_empty_coord(requested_coord, max_radius)

	return GridUtility.find_nearest(requested_coord, max_radius, func(coord: Vector2i) -> bool:
		return not is_occupied(coord)
	)


func mark_retreat(unit: Unit) -> void:
	# Removes from combat but keeps the instance valid for roster sync
	var index: int = _units.find(unit)
	if index != GameConstants.INVALID_INDEX:
		var coord = _coords[index]
		if _pos_to_unit.get(coord) == _units[index]:
			_pos_to_unit.erase(coord)
			# Self-healing: if other units were stacked here, restore one to the hash
			for i in range(_coords.size()):
				if i != index and _coords[i] == coord:
					_pos_to_unit[coord] = _units[i]
					break

		# We don't queue_free here, we just remove from active combat tracking
		_units.remove_at(index)
		_coords.remove_at(index)
		_is_player_controlled.remove_at(index)

		if _selected_index == index:
			_selected_index = GameConstants.INVALID_INDEX
			for i in range(_units.size()):
				if _is_player_controlled[i]:
					_selected_index = i
					break
			selection_changed.emit(_selected_index)
		elif _selected_index > index:
			_selected_index -= 1
			selection_changed.emit(_selected_index)

		unit_removed.emit(unit)

		# Ensure the unit is removed from the scene tree so it doesn't block visuals/input
		if is_instance_valid(unit) and unit.get_parent():
			unit.get_parent().remove_child(unit)

func remove_unit(unit: Unit) -> void:
	var index: int = _units.find(unit)
	if index != GameConstants.INVALID_INDEX:
		var coord = _coords[index]
		if _pos_to_unit.get(coord) == _units[index]:
			_pos_to_unit.erase(coord)
			# Self-healing: if other units were stacked here, restore one to the hash
			for i in range(_coords.size()):
				if i != index and _coords[i] == coord:
					_pos_to_unit[coord] = _units[i]
					break
		_units.remove_at(index)
		_coords.remove_at(index)
		_is_player_controlled.remove_at(index)

		if _selected_index == index:
			_selected_index = GameConstants.INVALID_INDEX
			# Try to find another player unit
			for i in range(_units.size()):
				if _is_player_controlled[i]:
					_selected_index = i
					break
			selection_changed.emit(_selected_index)
		elif _selected_index > index:
			_selected_index -= 1
			selection_changed.emit(_selected_index)

		unit_removed.emit(unit)

		# Ensure the unit is removed from the scene tree
		if is_instance_valid(unit):
			if unit.get_parent():
				unit.get_parent().remove_child(unit)
			unit.queue_free()

func get_all_units() -> Array[Unit]:
	var result: Array[Unit] = []
	for unit in _units:
		if is_instance_valid(unit):
			result.append(unit)
	return result

func get_units() -> Array[Unit]:
	return get_all_units()

func get_unit_count() -> int:
	return _units.size()

func get_player_units() -> Array[Unit]:
	return get_units_by_faction(GameConstants.Faction.PLAYER)

func get_enemy_units() -> Array[Unit]:
	return get_units_by_faction(GameConstants.Faction.ENEMY)

func get_neutral_units() -> Array[Unit]:
	return get_units_by_faction(GameConstants.Faction.NEUTRAL)
func get_allied_units(unit: Unit) -> Array[Unit]:
	var result: Array[Unit] = []
	for u in _units:
		if is_instance_valid(u) and is_instance_valid(unit) and unit.is_friendly(u):
			result.append(u)
	return result
func get_faction_leader(faction: GameConstants.Faction) -> Unit:
	for unit in _units:
		if is_instance_valid(unit) and unit.faction == faction and unit.is_faction_leader(faction):
			return unit
	return null

func set_faction_leader(leader: Unit, faction: GameConstants.Faction) -> void:
	for unit in _units:
		if is_instance_valid(unit) and unit.faction == faction:
			unit.set_faction_leader(faction, unit == leader)

func set_roster_for_faction(faction: GameConstants.Faction, roster: Resource) -> void:
	_rosters[faction] = roster

func get_roster_for_faction(faction: GameConstants.Faction) -> Resource:
	return _rosters.get(faction, null)


func reset_all_neutral_loyalties() -> void:
	for unit in _units:
		if is_instance_valid(unit) and unit.faction == GameConstants.Faction.NEUTRAL and unit.loyalty:
			unit.loyalty.reset_neutral_loyalty()

func get_selected_unit() -> Unit:
	if _selected_index >= 0 and _selected_index < _units.size():
		var unit = _units[_selected_index]
		if is_instance_valid(unit):
			return unit
	return null

func get_selected_sprite() -> Unit:
	return get_selected_unit()

func get_units_by_faction(faction: GameConstants.Faction) -> Array[Unit]:
	var result: Array[Unit] = []
	for unit in _units:
		if is_instance_valid(unit) and unit.faction == faction:
			result.append(unit)
	return result

## Sums the max willpower for all units of a faction.
func get_fleet_willpower(faction: GameConstants.Faction) -> int:
	var total := 0
	var units: Array[Unit] = get_units_by_faction(faction)

	for unit in units:
		if is_instance_valid(unit):
			total += unit.max_willpower
	return total

func get_selected_index() -> int:
	return _selected_index

func get_selected_coord() -> Vector2i:
	if _selected_index >= 0 and _selected_index < _coords.size():
		return _coords[_selected_index]
	return GameConstants.INVALID_COORD

func get_coord_by_unit(unit: Unit) -> Vector2i:
	var index: int = _units.find(unit)
	if index != GameConstants.INVALID_INDEX:
		return _coords[index]
	return GameConstants.INVALID_COORD

func get_unit(index: int) -> Unit:
	if index >= 0 and index < _units.size():
		return _units[index]
	return null

func get_coord(index: int) -> Vector2i:
	if index >= 0 and index < _coords.size():
		return _coords[index]
	return GameConstants.INVALID_COORD

func set_coord(index: int, coord: Vector2i) -> void:
	if index >= 0 and index < _coords.size():
		var unit = _units[index]
		if not is_instance_valid(unit):
			return

		if is_occupied(coord, index):
			GameLogger.warning(GameLogger.Category.COMBAT, "UnitManager: Cell %s is already occupied. Cannot move unit %d." % [coord, index])
			return

		var old_coord = _coords[index]
		if _pos_to_unit.get(old_coord) == _units[index]:
			_pos_to_unit.erase(old_coord)
			# Self-healing: if other units were stacked here, restore one to the hash
			for i in range(_coords.size()):
				if i != index and _coords[i] == old_coord:
					_pos_to_unit[old_coord] = _units[i]
					break
		_coords[index] = coord
		_pos_to_unit[coord] = _units[index]
		if _units[index] is Target:
			(_units[index] as Target).set_external_grid_coord(coord)
		unit_moved.emit(index, coord)
		if EventBus: EventBus.unit_moved.emit(_units[index], coord)

func is_occupied(coord: Vector2i, ignore_index: int = GameConstants.INVALID_INDEX) -> bool:
	var unit = _pos_to_unit.get(coord)
	if unit == null:
		return false
	if ignore_index != GameConstants.INVALID_INDEX and ignore_index >= 0 and ignore_index < _units.size():
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

func get_terrain_map() -> TerrainMap:
	return terrain_map


func apply_faction_stat_boost(faction: GameConstants.Faction, amount: int) -> void:
	# amount can be negative to remove a boost
	if amount == 0: return

	# Track the total boost for this faction to apply to new units
	var current_boost = _active_faction_boosts.get(faction, 0)
	_active_faction_boosts[faction] = current_boost + amount
	if _active_faction_boosts[faction] == 0:
		_active_faction_boosts.erase(faction)

	for unit in _units:
		if is_instance_valid(unit) and unit.faction == faction:
			_apply_unit_stat_boost(unit, amount)

	# Emit selection changed to refresh HUD if the selected unit was boosted
	selection_changed.emit(_selected_index)


func _apply_unit_stat_boost(unit: Unit, amount: int) -> void:
	unit.grit += amount
	unit.flow += amount
	unit.gusto += amount
	unit.focus += amount
	unit.shine += amount
	unit.shade += amount

	if amount > 0:
		unit.max_willpower += amount
		unit.willpower += amount
	else:
		# Safe removal: don't let removal kill the unit
		var old_max = unit.max_willpower
		unit.max_willpower = max(1, old_max + amount)
		# If they took damage, willpower might be low.
		# We want to keep their current % or at least keep them alive.
		if unit.willpower > 0:
			unit.willpower = max(1, unit.willpower + amount)

	if unit.res:
		unit.res.set_movement_points(unit.res.get_movement_points() + amount)
		unit.res.set_max_reactions(unit.res.get_max_reactions() + amount)


func get_faction_max_willpower(faction: GameConstants.Faction, include_debug_boost: bool = true) -> int:
	var total := 0
	var units := get_units_by_faction(faction)
	for unit in units:
		if is_instance_valid(unit):
			var val = unit.max_willpower
			if not include_debug_boost:
				val -= _active_faction_boosts.get(faction, 0)
			total += max(0, val)
	return total


func index_of_unit_at(coord: Vector2i) -> int:
	for i in range(_coords.size()):
		if _coords[i] == coord:
			return i
	return GameConstants.INVALID_INDEX

func can_player_act(index: int) -> bool:
	if index == GameConstants.INVALID_INDEX or index >= _units.size():
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
				"data": UnitSerializer.create_memento(unit)
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
			var scene: Resource = load(scene_path)
			var unit: Unit = scene.instantiate() as Unit
			if unit:
				UnitSerializer.restore_from_memento(unit, entry.get("data", {}))
				add_unit(unit, entry.get("coord", GameConstants.INVALID_COORD), entry.get("is_player", false))
				unit_spawn_requested.emit(unit)

	_selected_index = memento.get("selected_index", 0)
	if _selected_index >= 0 and _selected_index < _units.size():
		selection_changed.emit(_selected_index)
	else:
		_selected_index = GameConstants.INVALID_INDEX
		selection_changed.emit(_selected_index)

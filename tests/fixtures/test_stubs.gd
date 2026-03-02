# Standard stubs for unit tests to avoid re-defining them in every file.
# These provide simplified versions of complex classes for isolated testing.

# --- Terrain & Grid ---

class FakeTerrainMap extends TerrainMap:
	var neighbor_map: Dictionary = {}
	var blocked := {}

	func _init(neighbors: Dictionary = {}, width: int = 10, height: int = 10):
		neighbor_map = neighbors.duplicate(true)
		grid_width = width
		grid_height = height

	func is_within_bounds(coord: Vector2i) -> bool:
		return coord.x >= 1 and coord.y >= 1 and coord.x <= grid_width and coord.y <= grid_height

	func is_passable(coord: Vector2i) -> bool:
		return not blocked.get(coord, false)

	func get_neighbors(coord: Vector2i) -> Array[Vector2i]:
		var neighbors: Array[Vector2i] = []
		for n in neighbor_map.get(coord, []):
			neighbors.append(Vector2i(n))
		return neighbors

	func get_offset_axis() -> int:
		return offset_axis

	func set_offset_axis(axis: int) -> void:
		offset_axis = axis

	func load_from_rows(p_rows: Array, p_width: int = -1, p_height: int = -1) -> void:
		pass

# --- Unit Management ---
class FakeUnitManager extends UnitManager:
	var _indices: Dictionary = {}
	var _occupied: Dictionary = {}
	var _mock_units: Array[Unit] = []
	var _mock_coords: Array[Vector2i] = []

	func add_unit(unit: Unit, coord: Vector2i, is_player: bool = false) -> void:
		_mock_units.append(unit)
		_mock_coords.append(coord)
		_indices[unit] = _mock_units.size() - 1
		_occupied[coord] = true

	func get_unit(index: int) -> Unit:
		if index >= 0 and index < _mock_units.size():
			return _mock_units[index]
		return null

	func get_coord(index: int) -> Vector2i:
		if index >= 0 and index < _mock_coords.size():
			return _mock_coords[index]
		return Vector2i(-1, -1)

	func get_unit_index(unit) -> int:
		if _indices.has(unit):
			return _indices[unit]
		return -1

	func is_occupied(coord: Vector2i, _ignore_index: int = -1) -> bool:
		return _occupied.get(coord, false)

# --- Task/Location Management ---
class FakeTaskManager extends TaskManager:
	var coords: Array[Vector2i] = []
	var required_attribute := "grit"
	var _mock_locations: Dictionary = {}
	var _mock_tasks: Dictionary = {}
	var _active_objective: Node = null # Using Node as a generic for Objective
	var last_coord: Vector2i = Vector2i(-999, -999)

	func set_coords(values: Array[Vector2i]) -> void:
		coords = values

	func set_location(coord: Vector2i, location: Node) -> void:
		_mock_locations[coord] = location

	func set_task_for_target(target: Node, task: Node) -> void:
		_mock_tasks[target] = task

	func clear_locations() -> void:
		_mock_locations.clear()
		_mock_tasks.clear()

	func get_location_at(coord: Vector2i) -> Node:
		last_coord = coord
		return _mock_locations.get(coord)

	func get_task_for_target(target: Node) -> Node:
		return _mock_tasks.get(target)

	func get_location_count() -> int:
		return max(coords.size(), _mock_locations.size())

	func get_target(index: int) -> Vector2i:
		if index >= 0 and index < coords.size():
			return coords[index]
		var keys := _mock_locations.keys()
		if index >= 0 and index < keys.size():
			return keys[index]
		return Vector2i.ZERO

	func get_active_objective() -> Node:
		return _active_objective

	func set_active_objective(obj: Node) -> void:
		_active_objective = obj

# --- Loot Management ---
class FakeLootManager extends LootManager:
	var _loot: Dictionary = {}
	func add_loot(loot: Node, coord: Vector2i) -> void:
		_loot[coord] = loot
	func has_loot_at(coord: Vector2i) -> bool:
		return _loot.has(coord)
	func get_loot_at(coord: Vector2i) -> Node:
		return _loot.get(coord)
	func reset() -> void:
		_loot.clear()

# --- Dialogue Service ---
class FakeDialogueActionService extends DialogueActionService:
	var actions_to_append: Array[Dictionary] = []
	var last_start_payload: Dictionary = {}

	func append_dialogue_actions(actions: Array[Dictionary], _unit: Unit, _unit_manager: UnitManager) -> void:
		for entry in actions_to_append:
			actions.append(entry.duplicate(true))

	func start_dialogue(dialogue_id: StringName, initiator_index: int, target_index: int) -> CommandResult:
		last_start_payload = {
			"dialogue_id": dialogue_id,
			"initiator_index": initiator_index,
			"target_index": target_index
		}
		# Using success if CommandResult is available
		return null

# --- Attributes & Stats ---
class FakeAttributes extends RefCounted:
	var _values: Dictionary
	func _init(values: Dictionary) -> void:
		_values = values.duplicate(true)
	func get_attribute(p_name: String) -> int:
		return int(_values.get(p_name, 0))

class FakeUnit extends Unit:
	var _attrs := FakeAttributes.new({})
	var _grid_location: Vector2i = Vector2i(1, 1) # Default to 1,1
	var _hostiles: Array = []
	var _friendly: Array = []
	var _paths: Dictionary = {}

	func _ready() -> void:
		# Minimal components if needed by base Unit calls we can't avoid
		pass

	func set_attribute_values(values: Dictionary) -> void:
		_attrs = FakeAttributes.new(values)

	func get_attributes():
		return _attrs

	func get_grid_location() -> Vector2i:
		return _grid_location

	func set_grid_location(coord: Vector2i) -> void:
		_grid_location = coord

	func get_hostile_units() -> Array:
		return _hostiles

	func get_friendly_units() -> Array:
		return _friendly

	func get_path_to_coord(target_coord: Vector2i, _terrain_map: Variant, _start_coord: Vector2i = Vector2i.MAX, _movement_budget: int = -1) -> Array[Vector2i]:
		var path: Array[Vector2i] = []
		for p in _paths.get(target_coord, []):
			path.append(Vector2i(p))
		return path

	# Mock for query_service if not overridden
	func get_closest_unit(units: Array) -> Unit:
		if units.is_empty():
			return null
		return units[0]

# --- Weather Management ---
class FakeWeatherManager extends RefCounted:
	var channeling_unit: Unit = null

	func get_channeling_unit() -> Unit:
		return channeling_unit

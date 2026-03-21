class_name TestStubs
extends RefCounted

# --- Terrain & Grid ---

class FakeTerrainMap extends TerrainMap:
	var neighbor_map: Dictionary = {}
	var blocked := {}

	func _init(p_neighbors: Dictionary = {}, width: int = 10, height: int = 10):
		neighbor_map = p_neighbors.duplicate(true)
		grid_width = width
		grid_height = height

	func is_within_bounds(coord: Vector2i) -> bool:
		return coord.x >= 0 and coord.y >= 0 and coord.x < grid_width and coord.y < grid_height

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

	func load_from_rows(_p_rows: Array, _p_width: int = -1, _p_height: int = -1) -> void:
		pass

# --- Unit Management ---
class FakeUnitManager extends UnitManager:
	var _indices: Dictionary = {}
	var _occupied: Dictionary = {}
	var _mock_units: Array[Unit] = []
	var _mock_coords: Array[Vector2i] = []
	var _player_controlled: Dictionary = {}

	func set_player_controlled(index: int, value: bool) -> void:
		_player_controlled[index] = value

	func is_player_controlled(index: int) -> bool:
		return _player_controlled.get(index, false)

	func index_of_unit_at(coord: Vector2i) -> int:
		for i in range(_mock_coords.size()):
			if _mock_coords[i] == coord:
				return i
		return -1


	func select_index(p_index: int) -> void:
		_selected_index = p_index
		selection_changed.emit(_selected_index)

	func get_selected_unit() -> Unit:
		return get_unit(_selected_index)

	func get_selected_index() -> int:
		return _selected_index

	func add_unit(unit: Unit, coord: Vector2i, _is_player: bool = false) -> void:
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

	func get_unit_at_coord(coord: Vector2i) -> Unit:
		for i in range(_mock_coords.size()):
			if _mock_coords[i] == coord:
				return _mock_units[i]
		return null

	func is_occupied(coord: Vector2i, _ignore_index: int = -1) -> bool:
		return _occupied.get(coord, false)

# --- Task/Location Management ---
class FakeTaskManager extends TaskManager:
	var coords: Array[Vector2i] = []
	var _mock_locations: Dictionary = {}
	var _mock_tasks: Dictionary = {}
	var last_coord: Vector2i = Vector2i(-999, -999)

	func set_coords(values: Array[Vector2i]) -> void:
		coords = values

	func set_location(coord: Vector2i, location: Location) -> void:
		_mock_locations[coord] = location
		register_location(location)

	func set_task_for_target(target: Target, task: Task) -> void:
		_mock_tasks[target] = task

	func clear_locations() -> void:
		_mock_locations.clear()
		_mock_tasks.clear()
		_locations.clear()

	# Match: get_location_at(Vector2i) -> Location
	func get_location_at(coord: Vector2i) -> Location:
		last_coord = coord
		return _mock_locations.get(coord)

	func get_all_locations() -> Array[Location]:
		return _locations.duplicate()

	# Match: get_task_for_target(Target, int) -> Task
	func get_task_for_target(target: Target, _faction: int = -1) -> Task:
		# For test simplicity, we ignore faction in the mock unless needed
		return _mock_tasks.get(target)

	func get_active_tasks_for_target(target: Target, _faction: int = -1) -> Array[Task]:
		var task = _mock_tasks.get(target)
		if task:
			return [task]
		return []

	func get_location_count() -> int:
		return max(coords.size(), _mock_locations.size())

	func get_target(index: int) -> Vector2i:
		if index >= 0 and index < coords.size():
			return coords[index]
		var keys := _mock_locations.keys()
		if index >= 0 and index < keys.size():
			return keys[index]
		return Vector2i.ZERO

	# Match: get_active_objective() -> Objective
	func get_active_objective() -> Objective:
		return _active_objective

	func set_active_objective(obj: Objective) -> void:
		_active_objective = obj

# --- Loot Management ---
class FakeLootManager extends LootManager:
	var _loot: Dictionary = {}
	func add_loot(loot: Loot, coord: Vector2i) -> void:
		_loot[coord] = loot
		_loot_items.append(loot)
		_coords.append(coord)
	func has_loot_at(coord: Vector2i) -> bool:
		return _loot.has(coord)
	# Match: get_loot_at(Vector2i) -> Loot
	func get_loot_at(coord: Vector2i) -> Loot:
		return _loot.get(coord)
	func get_loot_count() -> int:
		return _loot_items.size()
	func get_loot(index: int) -> Loot:
		if index >= 0 and index < _loot_items.size():
			return _loot_items[index]
		return null
	func get_coord(index: int) -> Vector2i:
		if index >= 0 and index < _coords.size():
			return _coords[index]
		return Vector2i(-1, -1)
	func get_all_loot() -> Array[Loot]:
		return _loot_items.duplicate()
	func reset() -> void:
		_loot.clear()
		_loot_items.clear()
		_coords.clear()

# --- Movement Management ---
class FakeMoveController extends MoveController:
	var request_move_to_coord_called := false
	var request_move_and_interact_called := false
	var last_target_coord: Vector2i = Vector2i(-1, -1)
	var last_interaction_target: Target = null
	
	func request_move_to_coord(coord: Vector2i) -> bool:
		request_move_to_coord_called = true
		last_target_coord = coord
		return true
		
	func request_move_and_interact(coord: Vector2i, target: Target) -> bool:
		request_move_and_interact_called = true
		last_target_coord = coord
		last_interaction_target = target
		return true

# --- Dialogue Service ---
class FakeDialogueActionService extends DialogueActionService:
	var actions_to_append: Array[UnitAction] = []
	var last_start_payload: Dictionary = {}

	func append_dialogue_actions(actions: Array[UnitAction], _unit: Unit, _p_unit_manager: UnitManager) -> void:
		for entry in actions_to_append:
			actions.append(entry)

	func start_dialogue(dialogue_id: StringName, initiator_index: int, target_index: int) -> CommandResult:
		last_start_payload = {
			"dialogue_id": dialogue_id,
			"initiator_index": initiator_index,
			"target_index": target_index
		}
		return CommandResult.success()

	func handle_dialogue_request(id_or_path: String, p2: Variant = null, p3: int = -1) -> void:
		last_start_payload = {
			"id_or_path": id_or_path,
			"p2": p2,
			"p3": p3
		}

# --- Attributes & Stats ---
class FakeInventory extends InventoryComponent:
	func _init():
		_inventory = UnitInventory.new()
	func get_inventory() -> UnitInventory:
		return _inventory
	func get_items() -> Array:
		return []

# --- Component Stubs ---
class FakeUnitQueryService extends UnitQueryService:
	func _init(u: Unit): super._init(u)
	func get_near_units(units: Array, _r: float = 1.5) -> Array[Unit]:
		var result: Array[Unit] = []
		result.assign(_unit.get_near_units(units, _r))
		return result

	func get_hostile_units() -> Array[Unit]:
		var result: Array[Unit] = []
		if _unit.has_method("get_hostile_units"):
			result.assign(_unit.get_hostile_units())
		return result

	func get_friendly_units() -> Array[Unit]:
		var result: Array[Unit] = []
		if _unit.has_method("get_friendly_units"):
			result.assign(_unit.get_friendly_units())
		return result

	func get_neutral_units() -> Array[Unit]:
		var result: Array[Unit] = []
		if _unit.has_method("get_neutral_units"):
			result.assign(_unit.get_neutral_units())
		return result

class FakeUnitCombatBehavior extends UnitCombatBehavior:
	func _init(u: Unit): super._init(u)
	func attack(target: Unit, pair_idx: int = 0) -> bool:
		_unit.attack(target, pair_idx)
		return true

	func aid_ally(target: Unit, _attr_idx: int = 0) -> bool:
		if _unit.has_method("aid_ally"):
			_unit.aid_ally(target)
		return true

class FakeUnitMovementBehavior extends UnitMovementBehavior:
	func _init(u: Unit): super._init(u)
	func get_remaining_movement_points() -> int:
		return _unit.get_remaining_movement_points()

	func get_path_to_coord(target_coord: Vector2i, terrain_map, start_coord: Vector2i = Vector2i.MAX, movement_budget: int = -1) -> Array[Vector2i]:
		if _unit.has_method("get_path_to_coord"):
			return _unit.get_path_to_coord(target_coord, terrain_map, start_coord, movement_budget)
		return []

# --- Fake Unit ---
class FakeUnit extends Unit:
	var _grid_location: Vector2i = Vector2i(0, 0)
	var _hostiles: Array = []
	var _friendly: Array = []
	var _neutrals: Array = []
	var _paths: Dictionary = {}
	var _actions := 1

	func _init():
		super._init()
		# Use typed component proxies
		query = FakeUnitQueryService.new(self )
		combat = FakeUnitCombatBehavior.new(self )
		movement = FakeUnitMovementBehavior.new(self )
		loyalty = UnitLoyaltyComponent.new(self )
		interaction = TargetInteractionHandler.new(self )
		death = UnitDeathHandler.new(self )
		if res == null:
			res = ActionPointsComponent.new()
		set_attribute_values({})

	func _ready() -> void:
		super._ready()

	func has_action_available() -> bool:
		return _actions > 0

	func consume_action() -> void:
		_actions -= 1

	func set_attribute_values(values: Dictionary) -> void:
		for idx in GameConstants.ALL_ATTRIBUTE_INDICES:
			var attr_name: String = GameConstants.get_attribute_name(idx)
			if values.has(attr_name):
				set(attr_name, values[attr_name])
		if values.has("willpower"):
			base_willpower = values["willpower"]
		inv = FakeInventory.new()

	func get_grid_location() -> Vector2i:
		return _grid_location

	func set_grid_location(coord: Vector2i) -> void:
		_grid_location = coord

	func get_hostile_units() -> Array:
		return _hostiles

	func get_friendly_units() -> Array:
		return _friendly

	func get_neutral_units() -> Array:
		return _neutrals

	func get_near_units(units: Array, _adjacency_range: float = 1.5) -> Array:
		# Simple intersection by default; tests can override or populate a mock
		var result := []
		for u in units:
			if u in _hostiles or u in _friendly:
				result.append(u)
		return result

	func get_units_in_range(units: Array, _detection_range: float) -> Array:
		return units # Default to all candidates in range for simple stubs

	func get_path_to_coord(target_coord: Vector2i, _terrain_map: Variant, _start_coord: Vector2i = Vector2i.MAX, _movement_budget: int = -1) -> Array[Vector2i]:
		var path: Array[Vector2i] = []
		for p in _paths.get(target_coord, []):
			path.append(Vector2i(p))
		return path

	func get_closest_unit(units: Array) -> Unit:
		if units.is_empty():
			return null
		return units[0]

	func attack(target: Unit, _pair_idx: int = 0) -> void:
		if target.has_method("damage"):
			target.damage(10)

	func die() -> void:
		is_dead = true
		if _unit_manager:
			_unit_manager.remove_unit(self )
		queue_free()

	func damage(amount: int) -> void:
		willpower -= amount
		if willpower <= 0:
			is_dead = true

	func get_remaining_movement_points() -> int:
		return movement_points

# --- Weather Management ---
class FakeWeatherManager extends RefCounted:
	var channeling_unit: Unit = null

	func get_channeling_unit() -> Unit:
		return channeling_unit

# --- Persistence & Settings ---
class FakeGameConfig extends Node:
	var values: Dictionary = {}
	func get_value(key: String, default = null):
		return values.get(key, default)
	func set_value(key: String, value) -> void:
		values[key] = value
	func save_config() -> void:
		pass

class FakeDisplaySettings extends Node:
	var landscape: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(1280, 720)]
	var portrait: Array[Vector2i] = [Vector2i(1080, 1920), Vector2i(720, 1280)]
	var orientation: int = 0 # LANDSCAPE (matches DisplayOrientation.Orientation.LANDSCAPE)
	var index: int = 0
	func get_standard_resolutions(requested_orientation: int) -> Array[Vector2i]:
		return landscape.duplicate() if requested_orientation == 0 else portrait.duplicate()
	func get_current_orientation() -> int:
		return orientation
	func get_current_resolution_index() -> int:
		return index
	func get_current_resolution() -> Vector2i:
		var pool: Array = get_standard_resolutions(orientation)
		if pool.is_empty(): return Vector2i.ZERO
		return pool[clamp(index, 0, pool.size() - 1)]
	func set_orientation(new_orientation: int) -> void:
		orientation = new_orientation
	func set_resolution_index(new_index: int) -> void:
		index = new_index

# --- UI & Audio ---
class FakeHud extends Hud:
	pass

class FakeAudioBusController extends Node:
	var volume_db: Dictionary = {}
	var muted: Dictionary = {}
	func get_bus_volume_db(bus: String) -> float:
		return volume_db.get(bus, 0.0)
	func set_bus_volume_db(bus: String, db: float) -> void:
		volume_db[bus] = db
	func is_bus_muted(bus: String) -> bool:
		return muted.get(bus, false)
	func mute_bus(bus: String, enable: bool) -> void:
		muted[bus] = enable

class FakeAutoAdvance extends RefCounted:
	var enabled_forced := false
	var enabled_until_user_input := false

class FakeControlSettings extends Node:
	var move_actions: Array = []
	var camera_actions: Array = []
	var selection_actions: Array = []
	var pause_actions: Array = []
	var interaction_actions: Array = []
	func reset_inputs_to_defaults(): pass

class FakeInputMapper extends Node:
	func apply_configs(_configs, _defaults = null): pass

# --- Turn & AI ---
class FakeTurnController extends TurnController:
	var mock_round := 1
	var mock_side := 0 # PLAYER
	var mock_unit_index := 0

	func get_round() -> int: return mock_round
	func get_current_side() -> int: return mock_side
	func get_current_unit_index() -> int: return mock_unit_index
	func complete_turn() -> void: pass
	func can_act_on_index(_idx: int) -> bool: return true
	func is_enabled() -> bool: return true
	func lock_active_player_unit(_idx: int) -> void: pass
	func rebuild_turn_roster(_p_force: bool = false) -> void: pass

class FakeAIController extends Node:
	var executed_units: Array = []
	func execute_turn(unit) -> bool:
		executed_units.append(unit)
		return true

# --- External Libraries ---
class FakeDialogic extends Node:
	signal text_signal(p)
	signal signal_event(p)
	signal timeline_ended()
	signal timeline_started()
	
	var last_timeline: String = ""
	
	func start(timeline: String) -> void:
		last_timeline = timeline
		timeline_started.emit()
	
	func handle_next_input() -> void:
		pass

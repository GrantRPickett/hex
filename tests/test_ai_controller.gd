extends GdUnitTestSuite

const AIController := preload("res://Gameplay/ai_controller.gd")
const TurnSystem := preload("res://Gameplay/turn_system.gd")

class FakeGoalManager extends RefCounted:
	var coords: Array
	func _init(goal_coords: Array = []):
		coords = goal_coords
	func get_goal_count() -> int:
		return coords.size()
	func get_target(index: int) -> Vector2i:
		return coords[index]

class FakeUnitManager extends RefCounted:
	func is_occupied(_coord: Vector2i) -> bool:
		return false

class FakeTerrainMap extends RefCounted:
	var neighbor_map := {}
	var grid_width := 4
	var grid_height := 4
	var offset_axis := TileSet.TILE_OFFSET_AXIS_VERTICAL
	func _init(neighbors: Dictionary = {}, width: int = 4, height: int = 4):
		neighbor_map = neighbors.duplicate(true)
		grid_width = width
		grid_height = height
	func get_neighbors(coord: Vector2i) -> Array:
		return neighbor_map.get(coord, [])
	func get_offset_axis() -> int:
		return offset_axis

class FakeHostile extends RefCounted:
	var coord: Vector2i
	var unit_name := "Target"
	func _init(p_coord: Vector2i):
		coord = p_coord
	func get_grid_location() -> Vector2i:
		return coord

class FakeUnit extends RefCounted:
	var paths: Dictionary
	var hostiles: Array
	var faction := TurnSystem.Side.PLAYER
	var unit_name := "Unit"
	var willpower := 2
	func _init(p_paths: Dictionary = {}, p_hostiles: Array = []):
		paths = p_paths.duplicate(true)
		hostiles = p_hostiles.duplicate(true)
	func get_path_to_coord(coord: Vector2i, _terrain_map) -> Array:
		return paths.get(coord, [])
	func get_hostile_units() -> Array:
		return hostiles.duplicate(true)
	func get_grid_location() -> Vector2i:
		return Vector2i.ZERO
	func has_method(name: StringName) -> bool:
		return String(name) == "faction"

func test_fallback_goal_action_returns_best_path() -> void:
	var controller := auto_free(AIController.new())
	controller._goal_manager = FakeGoalManager.new([
		Vector2i(4, 4)
	])
	var unit := FakeUnit.new({Vector2i(4, 4): [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)]})
	var action = controller._fallback_goal_action(unit, FakeTerrainMap.new())
	assert_object(action).is_not_null()
	assert_str(action.type).is_equal("move_to_goal")
	assert_array(action.path).has_size(4)

func test_fallback_enemy_action_moves_toward_hostile() -> void:
	var controller := auto_free(AIController.new())
	controller._unit_manager = FakeUnitManager.new()
	var hostile := FakeHostile.new(Vector2i(2, 0))
	var terrain := FakeTerrainMap.new({Vector2i(2, 0): [Vector2i(1, 0)]})
	var unit := FakeUnit.new({Vector2i(1, 0): [Vector2i(1, 0)]}, [hostile])
	var action = controller._fallback_enemy_action(unit, terrain)
	assert_object(action).is_not_null()
	assert_str(action.type).is_equal("move_to_enemy")
	assert_array(action.path).has_size(1)

func test_fallback_enemy_action_skips_neutral_units() -> void:
	var controller := auto_free(AIController.new())
	controller._unit_manager = FakeUnitManager.new()
	var hostile := FakeHostile.new(Vector2i(2, 0))
	var terrain := FakeTerrainMap.new({Vector2i(2, 0): [Vector2i(1, 0)]})
	var unit := FakeUnit.new({Vector2i(1, 0): [Vector2i(1, 0)]}, [hostile])
	unit.faction = TurnSystem.Side.NEUTRAL
	var action = controller._fallback_enemy_action(unit, terrain, {}, true)
	assert_object(action).is_null()

func test_fallback_center_action_moves_toward_middle() -> void:
	var controller := auto_free(AIController.new())
	controller._unit_manager = FakeUnitManager.new()
	var terrain := FakeTerrainMap.new({}, 4, 4)
	var center_coord := Vector2i(2, 2)
	var unit := FakeUnit.new({center_coord: [Vector2i(1, 0), center_coord]}, [])
	var action = controller._fallback_center_action(unit, terrain)
	assert_object(action).is_not_null()
	assert_str(action.type).is_equal(AIController.ACTION_MOVE_TO_CENTER)
	assert_array(action.path).is_not_empty()

class FakeGoalLookupManager extends RefCounted:
	var _goal
	func _init(goal_instance):
		_goal = goal_instance
	func get_goal_at_cell(cell: Vector2i):
		if _goal and _goal.coord == cell:
			return _goal
		return null

class FakeGoal extends RefCounted:
	var coord: Vector2i
	func _init(p_coord: Vector2i):
		coord = p_coord
	func can_be_worked_on_by(_unit: Unit) -> bool:
		return true

class FakeLootPresence extends RefCounted:
	var loot_coord: Vector2i
	func _init(coord: Vector2i):
		loot_coord = coord
	func has_loot_at(coord: Vector2i) -> bool:
		return coord == loot_coord

class FakeSimpleUnit extends RefCounted:
	var coord: Vector2i
	func _init(p_coord: Vector2i = Vector2i.ZERO):
		coord = p_coord
	func get_grid_location() -> Vector2i:
		return coord

class FakeCombatUnit extends Unit:
	var _hostiles: Array
	var _adjacent: Array
	func _init(hostiles: Array = [], adjacent: Array = []):
		_hostiles = hostiles.duplicate(true)
		_adjacent = adjacent.duplicate(true)
	func get_hostile_units() -> Array[Unit]:
		return _hostiles.duplicate(true)
	func get_adjacent_units(units: Array, adjacency_range: float = 1.5) -> Array:
		var result: Array = []
		for unit in units:
			if _adjacent.has(unit):
				result.append(unit)
		return result
	func get_units_in_range(units: Array, detection_range: float) -> Array:
		return units.duplicate(true)
func test_promote_move_to_loot_sets_loot_action() -> void:
	var controller := auto_free(AIController.new())
	controller._loot_manager = FakeLootPresence.new(Vector2i(2, 1))
	var unit := FakeSimpleUnit.new(Vector2i(2, 1))
	var action := AIController.AIAction.new(AIController.ACTION_MOVE_TO_LOOT, null, [], 0.0)
	controller._promote_move_action_followup(unit, action)
	assert_str(action.type).is_equal(AIController.ACTION_LOOT)
	assert_vector2i(action.target).is_equal(Vector2i(2, 1))

func test_promote_move_to_goal_sets_goal_target() -> void:
	var controller := auto_free(AIController.new())
	var goal := FakeGoal.new(Vector2i(3, 0))
	controller._goal_manager = FakeGoalLookupManager.new(goal)
	var unit := FakeSimpleUnit.new(Vector2i(3, 0))
	var action := AIController.AIAction.new(AIController.ACTION_MOVE_TO_GOAL, Vector2i(3, 0), [], 0.0)
	controller._promote_move_action_followup(unit, action)
	assert_str(action.type).is_equal(AIController.ACTION_WORK_ON_GOAL)
	assert_object(action.target).is_equal(goal)

func test_promote_move_to_enemy_sets_attack_action() -> void:
	var controller := auto_free(AIController.new())
	var enemy := FakeHostile.new(Vector2i(1, 0))
	var unit := FakeSimpleUnit.new(Vector2i.ZERO)
	var action := AIController.AIAction.new(AIController.ACTION_MOVE_TO_ENEMY, enemy, [], 0.0)
	controller._promote_move_action_followup(unit, action)
	assert_str(action.type).is_equal(AIController.ACTION_ATTACK)
	assert_object(action.target).is_equal(enemy)

func test_find_enemy_actions_only_attacks_adjacent_targets() -> void:
	var controller := auto_free(AIController.new())
	controller._unit_manager = FakeUnitManager.new()
	var adjacent := auto_free(Unit.new())
	adjacent.unit_name = "Adjacent"
	var distant := auto_free(Unit.new())
	distant.unit_name = "Distant"
	var unit := auto_free(FakeCombatUnit.new([adjacent, distant], [adjacent]))
	var actions: Array[AIController.AIAction] = []
	controller._find_enemy_actions(unit, Vector2i.ZERO, FakeTerrainMap.new(), actions)
	var attack_targets: Array = []
	for action in actions:
		if action.type == AIController.ACTION_ATTACK:
			attack_targets.append(action.target)
	assert_array(attack_targets).has_size(1)
	assert_object(attack_targets[0]).is_equal(adjacent)


extends GdUnitTestSuite

var _unit_manager: UnitManager
var _ai_controller: AIController
var _unit: Unit
var _terrain_map: TerrainMap

func before_test() -> void:
	_unit_manager = auto_free(UnitManager.new())
	_ai_controller = auto_free(AIController.new())
	_unit = auto_free(Unit.new())
	_unit.unit_name = "TestUnit"
	_unit.max_willpower = 10
	_unit.willpower = 10
	
	# Setup unit movement points
	_unit.movement_points = 5
	
	_unit_manager.add_unit(_unit, Vector2i(0, 0), true)
	
	# Mock or create a real terrain map if needed
	# AIController uses context.terrain_map
	_terrain_map = auto_free(TerrainMap.new())

func test_execute_movement_with_empty_reachable_path_returns_false() -> void:
	# Setup: unit has 0 movement points remaining
	_unit.movement.consume_move(5)
	assert_int(_unit.movement.get_remaining_movement_points()).is_equal(0)
	
	# Path that doesn't include current position and is unreachable
	var path: Array[Vector2i] = [Vector2i(1, 1), Vector2i(2, 2)]
	
	# AIController needs a setup usually, but we can try to call the internal method
	# or call execute_turn if we can trigger movement.
	# _execute_movement is private-ish (starts with _) but accessible in GDScript.
	
	# We need to make sure _unit._movement_cache is initialized
	# Usually done by UnitManager or during Unit setup
	# In Unit.gd: 
	# @export var movement_range_cache_template: Resource = MovementRangeCache.new()
	# var _movement_cache: MovementRangeCache
	
	# Let's ensure it's there
	if _unit._movement_cache == null:
		_unit._movement_cache = MovementRangeCache.new()
		_unit._movement_cache.setup(_unit)

	var performed = await _ai_controller._execute_movement(_unit, path, _terrain_map)
	
	assert_bool(performed).is_false()
	# If it didn't crash, the test passes the "no crash" part

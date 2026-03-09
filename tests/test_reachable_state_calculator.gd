extends GdUnitTestSuite

const ReachableStateCalculator = preload("res://Gameplay/map/reachable_state_calculator.gd")
const TerrainMap = preload("res://Gameplay/map/terrain_map.gd")

func _create_unit_setup(coord: Vector2i) -> Dictionary:
	var unit: Unit = auto_free(Unit.new())
	unit._ready()
	var manager: UnitManager = auto_free(UnitManager.new())
	manager.add_unit(unit, coord, true)
	return {
		"unit": unit,
		"manager": manager
	}

func _create_plain_terrain() -> TerrainMap:
	var terrain: TerrainMap = TerrainMap.new()
	terrain.load_from_rows(["GGGG", "GGGG"])
	return terrain

func test_calculate_reports_move_spaces() -> void:
	var setup = _create_unit_setup(Vector2i(1, 1))
	var terrain: TerrainMap = _create_plain_terrain()
	var state: Dictionary = ReachableStateCalculator.calculate(setup.unit, terrain, setup.manager)
	assert_int(state.move_spaces).is_greater(0)
	assert_array(state.coords).contains(Vector2i(1, 1))

func test_calculate_uses_tentative_action_origin() -> void:
	var setup = _create_unit_setup(Vector2i(1, 1))
	setup.unit.movement.set_tentative_move(Vector2i(3, 1), [] as Array[Vector2i], 1)
	var state: Dictionary = ReachableStateCalculator.calculate(setup.unit, null, setup.manager)
	assert_int(state.action_origin.x).is_equal(3)
	assert_int(state.action_origin.y).is_equal(1)
func test_tentative_action_origin_cost_is_zero() -> void:
	var setup = _create_unit_setup(Vector2i(0, 0))
	setup.unit.movement_points = 3
	setup.unit.movement.set_tentative_move(Vector2i(1, 0), [Vector2i(1, 0)] as Array[Vector2i], 1)
	var terrain: TerrainMap = _create_plain_terrain()
	var state: Dictionary = ReachableStateCalculator.calculate(setup.unit, terrain, setup.manager)
	var entry = state.lookup.get(Vector2i(1, 0))
	assert_dict(entry).is_not_null()
	assert_int(int(entry.get("cost", -1))).is_equal(0)

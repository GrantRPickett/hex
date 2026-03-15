extends GdUnitTestSuite

const UnitManagerScript = preload("res://Gameplay/targets/unit_manager.gd")
const UnitScript = preload("res://Gameplay/targets/unit.gd")

func _make_manager() -> Node:
	var mgr: UnitManagerScript = UnitManagerScript.new()
	add_child(mgr)
	return mgr

func test_get_coord_by_unit() -> void:
	var mgr = _make_manager()
	var unit: UnitScript = UnitScript.new()
	var pos: Vector2i = Vector2i(5, 5)

	# Try before adding
	assert_object(mgr.get_coord_by_unit(unit)).is_equal(GameConstants.INVALID_COORD)

	mgr.add_unit(unit, pos, true)
	assert_object(mgr.get_coord_by_unit(unit)).is_equal(pos)

	# Move and verify
	var new_pos: Vector2i = Vector2i(6, 6)
	mgr.move_unit(mgr.get_unit_index(unit), new_pos)
	assert_object(mgr.get_coord_by_unit(unit)).is_equal(new_pos)

func test_get_nearest_empty_coord() -> void:
	var mgr = _make_manager()
	var start_coord: Vector2i = Vector2i(0, 0)

	# With nothing there, the start coord itself is empty
	assert_object(mgr.get_nearest_empty_coord(start_coord)).is_equal(start_coord)

	# Add a unit at 0,0
	var u1: UnitScript = UnitScript.new()
	mgr.add_unit(u1, start_coord, true)

	# The nearest should now be one of the neighbors (e.g., 1,0 or 0,1)
	var next_coord = mgr.get_nearest_empty_coord(start_coord)
	assert_bool(next_coord != start_coord).is_true()
	assert_bool(mgr.is_occupied(next_coord)).is_false()

	# Fill that one too
	var u2: UnitScript = UnitScript.new()
	mgr.add_unit(u2, next_coord, false)

	var third_coord = mgr.get_nearest_empty_coord(start_coord)
	assert_bool(third_coord != start_coord).is_true()
	assert_bool(third_coord != next_coord).is_true()
	assert_bool(mgr.is_occupied(third_coord)).is_false()

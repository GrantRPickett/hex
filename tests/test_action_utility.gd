extends GdUnitTestSuite

const Stubs = preload("res://tests/fixtures/test_stubs.gd")

func test_set_reachable_info_uses_coord_lookup() -> void:
	var target := auto_free(Stubs.FakeUnit.new())
	target.set_grid_location(Vector2i(4, 4))
	var action: UnitAction = UnitAction.new(UnitAction.Type.CONVINCE)
	var lookup := {
		target.get_grid_location(): {"cost": 3}
	}

	ActionUtility.set_reachable_info(action, [target], lookup)

	assert_bool(action.target_move_data.has(target)).is_true()
	var info: Dictionary = action.target_move_data[target]
	assert_vector2i(info.get("coord", GameConstants.INVALID_COORD)).is_equal(target.get_grid_location())
	assert_int(info.get("cost", -1)).is_equal(3)

func test_set_reachable_info_accepts_target_keyed_lookup() -> void:
	var target := auto_free(Stubs.FakeUnit.new())
	target.set_grid_location(Vector2i(7, 2))
	var action: UnitAction = UnitAction.new(UnitAction.Type.CONVINCE)
	var lookup := {
		target: {"coord": Vector2i(6, 2), "cost": 1}
	}

	ActionUtility.set_reachable_info(action, [target], lookup)

	assert_bool(action.target_move_data.has(target)).is_true()
	var info: Dictionary = action.target_move_data[target]
	assert_vector2i(info.get("coord", GameConstants.INVALID_COORD)).is_equal(Vector2i(6, 2))
	assert_int(info.get("cost", -1)).is_equal(1)

func test__is_coord_keyed_lookup_detects_vector_keys() -> void:
	var lookup := {Vector2i(1, 2): {"cost": 5}}
	assert_bool(ActionUtility._is_coord_keyed_lookup(lookup)).is_true()
	assert_bool(ActionUtility._is_coord_keyed_lookup({})).is_false()

func test__clone_move_info_normalizes_inputs() -> void:
	var target := auto_free(Stubs.FakeUnit.new())
	target.set_grid_location(Vector2i(2, 2))
	var info := ActionUtility._clone_move_info({"cost": 4}, target)
	assert_vector2i(info.get("coord", GameConstants.INVALID_COORD)).is_equal(Vector2i(2, 2))
	assert_int(info.get("cost", -1)).is_equal(4)

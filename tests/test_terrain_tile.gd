extends GdUnitTestSuite

func test_get_movement_adjustment_combines_bonus_and_penalty() -> void:
	var tile: TerrainTile = auto_free(TerrainTile.new())
	tile.movement_bonus = 3
	tile.movement_penalty = 1
	assert_int(tile.get_movement_adjustment()).is_equal(2)

func test_apply_to_unit_enforces_effects() -> void:
	var unit := Unit.new()
	unit._ready()
	unit.refresh_for_new_round()
	var tile: TerrainTile = auto_free(TerrainTile.new())
	tile.movement_penalty = 1
	tile.status_effect = StringName("slowed")
	tile.blocks_action_after_move = true
	tile.apply_to_unit(unit)
	assert_int(unit.get_remaining_movement_points()).is_equal(unit.movement_points - 1)
	assert_bool(unit.has_action_available()).is_false()
	assert_bool(unit.has_status_effect("slowed")).is_true()
	unit.clear_status_effect("slowed")
	unit.refresh_for_new_round()
	tile.passable = false
	tile.apply_to_unit(unit)
	assert_bool(unit.has_move_available()).is_false()

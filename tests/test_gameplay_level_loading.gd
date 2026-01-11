extends "res://tests/test_utils.gd"
const GAMEPLAY_SCENE := "res://Gameplay/gameplay.tscn"
const LEVEL1_PATH := "res://Resources/levels/level1.tres"
const LEVEL2_PATH := "res://Resources/levels/level2.tres"

func _setup_levels(target_path: String) -> void:
	if not Engine.has_singleton("LevelManager"):
		return
	LevelManager.set_levels([LEVEL1_PATH, LEVEL2_PATH])
	LevelManager.set_current_level_path(target_path)

func _reset_levels() -> void:
	if not Engine.has_singleton("LevelManager"):
		return
	LevelManager.set_levels([])
	LevelManager.set_current_level_path("")

func test_gameplay_applies_level_manager_selection() -> void:
	if not Engine.has_singleton("LevelManager"):
		return

	_setup_levels(LEVEL2_PATH)

	var runner := _create_scene_runner(GAMEPLAY_SCENE)
	var scene := runner.scene()
	_simulate_frames(runner, 1)

	var level := load(LEVEL2_PATH)

	assert_that(scene.level_resource).is_not_null()
	assert_that(scene.player_coord).is_equal(level.player1_start)
	assert_that(scene.player2_coord).is_equal(level.player2_start)
	assert_that(scene.goal_coord).is_equal(level.goal_coord)
	assert_that(scene.goal2_coord).is_equal(level.goal2_coord)
	assert_that(scene._grid_width).is_equal(level.grid_width)

	assert_that(scene._grid.tile_set.tile_offset_axis).is_equal(level.hex_offset_axis)
	assert_that(scene._use_dual_goals).is_equal(level.require_units_match_goals)

	_reset_levels()

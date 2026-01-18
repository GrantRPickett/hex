extends "res://tests/test_utils.gd"
const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"
const LEVEL1_PATH := "res://Resources/levels/level_1.tres"
const LEVEL2_PATH := "res://Resources/levels/level_2.tres"

# Preload level resources directly
const LEVEL1 = preload("res://Resources/levels/level_1.tres")
const LEVEL2 = preload("res://Resources/levels/level_2.tres")

var _require_all_backup := false
var _control_settings: Node = null
var _input_mapper: Node = null

const AUTOLOADS = {
	"ControlSettings": "res://Autoloads/control_settings.gd",
	"InputMapper": "res://Autoloads/input_mapper.gd",
}

func before_test() -> void:
	var instances = await setup_autoloads(AUTOLOADS)
	_control_settings = instances["ControlSettings"]
	_input_mapper = instances["InputMapper"]
	_require_all_backup = _control_settings.require_all_units_to_goal

func after_test() -> void:
	await teardown_autoloads()

func _action_event(action: String) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	return ev

func test_apply_level_if_available_uses_existing_resource() -> void:
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	var scene = runner.scene()
	_simulate_frames(runner, 1)

	var level := LEVEL1
	assert_that(level).is_not_null()
	scene.level_resource = level
	scene._apply_level_if_available()
	assert_that(scene.level_resource).is_equal(level)

func test_apply_level_dimensions_and_options_from_resource() -> void:
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	var scene = runner.scene()
	_simulate_frames(runner, 1)

	var level := LEVEL2
	# _apply_level_dimensions_and_positions and _setup_units_and_goals are internal methods
	# Use public API instead
	scene.level_resource = level
	scene._apply_level_if_available()
	_simulate_frames(runner, 1)

	assert_that(scene.goal2_coord).is_equal(Vector2i(4, 2))
	assert_that(scene.player_coord).is_equal(Vector2i(1, 1))
	# Grid width should be greater than 0
	assert_bool(scene._grid_width > 0).is_true()

func test_update_goal_progress_for_selected_handles_completion() -> void:
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	var scene = runner.scene()
	_simulate_frames(runner, 1)

	# Initialize with LEVEL2 which has 2 goals/units.
	# Duplicate and force require_all_units=true for this test scenario.
	var level = LEVEL2.duplicate()
	level.require_all_units = true
	scene.set_level_and_rebuild(level)
	_simulate_frames(runner, 1)

	# LEVEL2 sets require_all_units to true, so this should be the default
	assert_that(scene._require_all_units).is_true()
	assert_that(_control_settings.require_all_units_to_goal).is_true()

	var goal0_coord = scene._goal_manager.get_target(0)
	var goal1_coord = scene._goal_manager.get_target(1)

	# --- Test with require_all_units = true ---
	scene._goal_reached = false
	scene._unit_manager.set_goal_reached(0, false)
	scene._unit_manager.set_goal_reached(1, false)

	# Move unit 0 to its goal
	scene._unit_manager.set_coord(0, goal0_coord)
	scene._unit_manager.select_index(0)
	scene._update_goal_progress_for_selected()
	# Not all units are at goals, so goal should not be reached
	assert_that(scene._goal_reached).is_false()
	assert_that(scene._unit_manager.is_goal_reached(0)).is_true()
	assert_that(scene._unit_manager.is_goal_reached(1)).is_false()

	# Move unit 1 to its goal
	scene._unit_manager.set_coord(1, goal1_coord)
	scene._unit_manager.select_index(1)
	scene._update_goal_progress_for_selected()
	# All units are at goals, so goal should be reached
	assert_that(scene._goal_reached).is_true()
	assert_that(scene._unit_manager.are_all_goals_reached()).is_true()

	# --- Test with require_all_units = false ---
	# Manually set require_all_units to false for this part of the test
	scene._require_all_units = false
	scene._goal_reached = false
	scene._unit_manager.set_goal_reached(0, false)
	scene._unit_manager.set_goal_reached(1, false)

	# Move unit 0 to its goal, this should be enough to complete the level
	scene._unit_manager.set_coord(0, goal0_coord)
	scene._unit_manager.select_index(0)
	scene._update_goal_progress_for_selected()
	assert_that(scene._goal_reached).is_true()
	assert_that(scene._unit_manager.is_goal_reached(0)).is_true()
	assert_that(scene._unit_manager.is_goal_reached(1)).is_false()

	# Reset require_all_units state
	scene._require_all_units = true

func test_set_goal_coord() -> void:
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	var scene = runner.scene()
	_simulate_frames(runner, 1)

	# Initialize with LEVEL1 to ensure GoalManager is setup
	scene.set_level_and_rebuild(LEVEL1)
	_simulate_frames(runner, 1)

	var new_goal := Vector2i(2, 2)
	scene.set_goal_coord(new_goal)
	assert_that(scene.goal_coord).is_equal(new_goal)
	var goal_node = scene.get_node("Goal")
	assert_that(goal_node.position).is_equal(scene._axial_to_pixel(new_goal))

func test_set_level_and_rebuild() -> void:
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	var scene = runner.scene()
	_simulate_frames(runner, 1)

	var level := LEVEL2
	scene.set_level_and_rebuild(level)

	assert_that(scene.level_resource).is_equal(level)
	assert_that(scene.player_coord).is_equal(level.player_starts[0])
	assert_that(scene.goal_coord).is_equal(level.goal_coords[0])

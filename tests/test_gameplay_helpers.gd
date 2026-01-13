extends "res://tests/test_utils.gd"
const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"
const LEVEL1_PATH := "res://Resources/levels/level1.tres"
const LEVEL2_PATH := "res://Resources/levels/level2.tres"

# Preload level resources directly
const LEVEL1 = preload("res://Resources/levels/level1.tres")
const LEVEL2 = preload("res://Resources/levels/level2.tres")

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

func test_ensure_level_resource_reuses_existing_value() -> void:
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	var scene = runner.scene()
	_simulate_frames(runner, 1)

	var level := LEVEL1
	#print_debug("DBG test: level1 = ", level)
	assert_that(level).is_not_null()
	scene.level_resource = level
	assert_that(scene._ensure_level_resource()).is_true()
	assert_that(scene.level_resource).is_equal(level)

func test_apply_level_dimensions_and_options_from_resource() -> void:
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	var scene = runner.scene()
	_simulate_frames(runner, 1)

	var level := LEVEL2
	scene._apply_level_dimensions_and_positions(level)
	assert_that(scene.goal2_coord).is_equal(Vector2i(1, 4))
	assert_that(scene.player_coord).is_equal(Vector2i(0, 0))
	assert_that(scene._grid_width).is_equal(7)

	scene._apply_level_options(level)
	assert_that(scene._goal_targets[0]).is_equal(scene.goal_coord)
	assert_that(scene._goal_targets[1]).is_equal(scene.goal2_coord)
	assert_that(_control_settings.require_all_units_to_goal).is_true()
	var axis := int(level.get("hex_offset_axis"))
	var tile_set: TileSet = scene.get_node("Grid").tile_set
	assert_that(tile_set.tile_offset_axis).is_equal(axis)

func test_update_goal_progress_for_selected_handles_completion() -> void:
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	var scene = runner.scene()
	_simulate_frames(runner, 1)

	var p2 = scene.get_node("Player").duplicate()
	scene.add_child(p2)
	scene.add_unit(p2, Vector2i(1, 0), true)

	scene.goal_coord = scene.player_coord
	scene._players_goal_reached = [false, false] as Array[bool]
	scene._selected_index = 0
	scene._goal_reached = false
	scene._update_goal_progress_for_selected()
	assert_that(scene._goal_reached).is_true()

	scene._goal_reached = false
	_control_settings.require_all_units_to_goal = true
	scene._players_goal_reached = [false, false] as Array[bool]
	scene.goal_coord = scene.player_coord
	scene._selected_index = 0
	scene._update_goal_progress_for_selected()
	assert_that(scene._goal_reached).is_false()
	scene._selected_index = 1
	scene._player_coords[1] = scene.goal_coord
	scene._update_goal_progress_for_selected()
	assert_that(scene._goal_reached).is_true()

	scene._goal_reached = false
	scene._goal_targets = [scene.player_coord, scene.player_coord + Vector2i(1, 0)] as Array[Vector2i]
	scene._players_goal_reached = [false, false] as Array[bool]
	scene._player_coords[0] = scene.player_coord
	scene._player_coords[1] = scene.player_coord + Vector2i(1, 0)
	scene._selected_index = 0
	scene._update_goal_progress_for_selected()
	assert_that(scene._goal_reached).is_false()
	scene._selected_index = 1
	scene._update_goal_progress_for_selected()
	assert_that(scene._goal_reached).is_true()

func test_set_goal_coord() -> void:
	var runner := _create_scene_runner(GAMEPLAY_SCENE_PATH)
	var scene = runner.scene()
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
	assert_that(scene.player_coord).is_equal(level.player1_start)
	assert_that(scene.goal_coord).is_equal(level.goal_coord)

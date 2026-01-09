extends GdUnitTestSuite

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"
const LEVEL1_PATH := "res://Resources/levels/level1.tres"
const LEVEL2_PATH := "res://Resources/levels/level2.tres"

# Preload level resources directly
const LEVEL1 = preload("res://Resources/levels/level1.tres")
const LEVEL2 = preload("res://Resources/levels/level2.tres")

var _require_all_backup := false

func before_test() -> void:
	_require_all_backup = ControlSettings.require_all_units_to_goal

func after_test() -> void:
	ControlSettings.require_all_units_to_goal = _require_all_backup

func _action_event(action: String) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	return ev

func test_handle_pause_input_toggles_state() -> void:
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	await runner.simulate_frames(1)

	var pause_event := _action_event("pause_game")
	assert_that(scene._handle_pause_input(pause_event)).is_true()
	assert_that(scene._paused).is_true()
	assert_that(scene._handle_pause_input(pause_event)).is_true()
	assert_that(scene._paused).is_false()

func test_handle_mouse_button_handles_zoom_and_free_cam() -> void:
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	await runner.simulate_frames(1)

	var cam: Camera2D = scene.get_node("Camera2D")
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	var start_zoom := cam.zoom.x
	assert_that(scene._handle_mouse_button(wheel)).is_true()
	await runner.simulate_frames(1)
	assert_that(cam.zoom.x).is_not_equal(start_zoom)

	var middle := InputEventMouseButton.new()
	middle.button_index = MOUSE_BUTTON_MIDDLE
	middle.pressed = true
	assert_that(scene._handle_mouse_button(middle)).is_true()
	assert_that(scene._free_cam).is_true()

func test_handle_selection_actions_switches_units_and_free_cam() -> void:
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	await runner.simulate_frames(1)

	var select_two := _action_event("select_unit_2")
	assert_that(scene._handle_selection_actions(select_two)).is_true()
	assert_that(scene._selected_index).is_equal(1)

	var select_next := _action_event("select_next")
	assert_that(scene._handle_selection_actions(select_next)).is_true()
	assert_that(scene._selected_index).is_equal(0)

	var toggle := _action_event("toggle_free_cam")
	assert_that(scene._handle_selection_actions(toggle)).is_true()
	assert_that(scene._free_cam).is_true()

func test_handle_camera_actions_rotates_and_zooms() -> void:
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	await runner.simulate_frames(1)

	var cam: Camera2D = scene.get_node("Camera2D")
	var rotate := _action_event("camera_rotate_left")
	var start_rot := cam.rotation
	assert_that(scene._handle_camera_actions(rotate)).is_true()
	assert_that(cam.rotation).is_not_equal(start_rot)

	var zoom := _action_event("camera_zoom_in")
	var before_zoom := cam.zoom.x
	assert_that(scene._handle_camera_actions(zoom)).is_true()
	assert_that(cam.zoom.x).is_not_equal(before_zoom)

func test_handle_move_actions_moves_player() -> void:
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	await runner.simulate_frames(1)

	var start_coord = scene.player_coord
	var move := _action_event("move_s")
	assert_that(scene._handle_move_actions(move)).is_true()
	assert_that(scene.player_coord).is_not_equal(start_coord)

func test_ensure_level_resource_reuses_existing_value() -> void:
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	await runner.simulate_frames(1)

	var level := LEVEL1
	print_debug("DBG test: level1 = ", level)
	assert_that(level).is_not_null()
	scene.level_resource = level
	assert_that(scene._ensure_level_resource()).is_true()
	assert_that(scene.level_resource).is_equal(level)

func test_apply_level_dimensions_and_options_from_resource() -> void:
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	await runner.simulate_frames(1)

	var level := LEVEL2
	scene._apply_level_dimensions_and_positions(level)
	assert_that(scene.goal2_coord).is_equal(Vector2i(1, 4))
	assert_that(scene.player_coord).is_equal(Vector2i(0, 0))
	assert_that(scene._grid_width).is_equal(7)

	scene._apply_level_options(level)
	assert_that(scene._use_dual_goals).is_true()
	assert_that(scene._goal_targets[0]).is_equal(scene.goal_coord)
	assert_that(scene._goal_targets[1]).is_equal(scene.goal2_coord)
	assert_that(ControlSettings.require_all_units_to_goal).is_true()
	var axis := int(level.get("hex_offset_axis"))
	var tile_set: TileSet = scene.get_node("Grid").tile_set
	assert_that(tile_set.tile_offset_axis).is_equal(axis)

func test_update_goal_progress_for_selected_handles_completion() -> void:
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	await runner.simulate_frames(1)

	scene.goal_coord = scene.player_coord
	scene._players_goal_reached = [false, false] as Array[bool]
	scene._selected_index = 0
	scene._goal_reached = false
	scene._update_goal_progress_for_selected()
	assert_that(scene._goal_reached).is_true()

	scene._goal_reached = false
	ControlSettings.require_all_units_to_goal = true
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
	scene._use_dual_goals = true
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

extends "res://tests/test_utils.gd"

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"
const GoalManager := preload("res://Gameplay/goal_manager.gd")
const Goal := preload("res://Gameplay/goal.gd")

class UnitTestLevel extends Resource:
	var player_starts: Array[Vector2i] = []
	var goal_coords: Array[Vector2i] = []
	var hex_offset_axis: int = TileSet.TILE_OFFSET_AXIS_VERTICAL
	var require_all_units: bool = false
	var initial_rotation: float = 0.0
	var grid_width: int = 7
	var grid_height: int = 7

var _control_settings: Node
var _input_mapper: Node

func before_test() -> void:
	var instances = await setup_autoloads({
		"ControlSettings": "res://Autoloads/control_settings.gd",
		"InputMapper": "res://Autoloads/input_mapper.gd",
	})
	_control_settings = instances["ControlSettings"]
	_input_mapper = instances["InputMapper"]

func after_test() -> void:
	await teardown_autoloads()

func _create_goal_manager_instance(goal_coords_array: Array[Vector2i] = [], goals_array: Array = []) -> GoalManager:
	var goal_manager_instance = GoalManager.new()
	var grid_node = Node2D.new()
	auto_free(grid_node)

	var final_goals_array: Array[Goal] = []
	for i in range(goal_coords_array.size()):
		if i < goals_array.size() and goals_array[i] is Goal:
			final_goals_array.append(goals_array[i])
		else:
			final_goals_array.append(auto_free(Goal.new()))

	goal_manager_instance.setup(goal_coords_array, final_goals_array, grid_node)
	return auto_free(goal_manager_instance)

func test_goal_reached_prevents_subsequent_moves() -> void:
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	assert_that(scene).is_not_null()
	await runner.simulate_frames(1)

	var level = UnitTestLevel.new()
	level.player_starts = [Vector2i(0, 0)] as Array[Vector2i]
	level.goal_coords = [Vector2i(2, 2)] as Array[Vector2i]
	scene.set_level_and_rebuild(level)
	await runner.simulate_frames(1)

	# Manually place the player at the goal to trigger completion
	scene.set_player_coord(scene.goal_coord)
	scene.update_goal_progress_for_selected()
	await runner.simulate_frames(1)

	# Verify goal is marked as reached
	assert_bool(scene._goal_reached).is_true()

	var coord_at_goal = scene.player_coord

	# Attempt to move after goal is reached
	scene.request_move("move_s")
	await runner.simulate_frames(1)

	# Assert that the player's coordinate has not changed
	assert_that(scene.player_coord).is_equal(coord_at_goal)

func test_gameplay_set_goal_coord_updates_goal_manager():
	# Given
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	assert_that(scene).is_not_null()
	await runner.simulate_frames(1)

	var initial_goal_coord = Vector2i(0, 0)
	var new_goal_coord = Vector2i(5, 5)

	var level = UnitTestLevel.new()
	var goal_array: Array[Vector2i] = [initial_goal_coord]
	level.goal_coords = goal_array
	scene.set_level_and_rebuild(level)
	await runner.simulate_frames(1)

	# When
	scene.set_goal_coord(new_goal_coord)
	await runner.simulate_frames(1) # Allow for any deferred updates

	# Then
	assert_that(scene._game_state.goal_manager.get_target(0)).is_equal(new_goal_coord)

# ============================================================================
# Gameplay/goal_manager.gd: set_target
# ============================================================================
func test_goal_manager_set_target_updates_coordinate() -> void:
	# Given
	var initial_goal_coord = Vector2i(0, 0)
	var new_goal_coord = Vector2i(5, 5)
	var goals: Array[Goal] = [auto_free(Goal.new())]
	var goal_manager = _create_goal_manager_instance([initial_goal_coord], goals)

	# When
	goal_manager.set_target(0, new_goal_coord)

	# Then
	assert_that(goal_manager.get_target(0)).is_equal(new_goal_coord)
	# Test for out of bounds index
	goal_manager.set_target(99, Vector2i(1,1)) # Should not crash
	assert_that(goal_manager.get_target(99)).is_equal(Vector2i(-999, -999)) # Should return default error coord

# ============================================================================
# Gameplay/goal_manager.gd: get_targets
# ============================================================================
func test_goal_manager_get_targets_returns_all_goal_coordinates() -> void:
	# Given
	var goal_coords = [Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 2)]
	var goals: Array[Goal] = [auto_free(Goal.new()), auto_free(Goal.new()), auto_free(Goal.new())]
	var goal_manager = _create_goal_manager_instance(goal_coords, goals)

	# When
	var targets = goal_manager.get_targets()

	# Then
	assert_array(targets).is_equal(goal_coords)

# ============================================================================
# Gameplay/goal_manager.gd: get_goal_node
# ============================================================================
func test_goal_manager_get_goal_node_returns_correct_node() -> void:
	# Given
	var goal_node_0 = Goal.new()
	var goal_node_1 = Goal.new()
	auto_free(goal_node_0)
	auto_free(goal_node_1)
	var goal_coords = [Vector2i(0, 0), Vector2i(1, 1)]
	var goals: Array[Goal] = [goal_node_0, goal_node_1]
	var goal_manager = _create_goal_manager_instance(goal_coords, goals)

	# When
	var node_0 = goal_manager.get_goal_node(0)
	var node_1 = goal_manager.get_goal_node(1)
	var node_invalid = goal_manager.get_goal_node(99)

	# Then
	assert_object(node_0).is_equal(goal_node_0)
	assert_object(node_1).is_equal(goal_node_1)
	assert_object(node_invalid).is_null()

extends "res://tests/test_utils.gd"

const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"
const LocationManager := preload("res://Gameplay/location_manager.gd")
const TargetTask := preload("res://Gameplay/target_task.gd")
const LevelScript := preload("res://Resources/Level.gd")
const Unit := preload("res://Gameplay/unit.gd")

var _control_settings: Node
var _input_mapper: Node

class FakeLocationAttributes extends RefCounted:
	var value := 0
	func set_value(v: int) -> void:
		value = v
	func get_attribute(_attr: String) -> int:
		return value

class FakeLocationUnit extends Unit:
	var attributes := FakelocationAttributes.new()
	func _ready() -> void:
		pass
	func set_attribute_value(v: int) -> void:
		attributes.set_value(v)
	func get_attributes():
		return attributes


func before_test() -> void:
	var instances = await setup_autoloads({
		"ControlSettings": "res://Autoloads/control_settings.gd",
		"InputMapper": "res://Autoloads/input_mapper.gd",
	})
	_control_settings = instances["ControlSettings"]
	_input_mapper = instances["InputMapper"]

func after_test() -> void:
	await teardown_autoloads()

func _make_level(player_starts: Array[Vector2i], location_coords: Array[Vector2i]) -> Level:
	var level := LevelScript.new()
	var starts: Array[Vector2i] = []
	starts.assign(player_starts)
	level.player_starts = starts
	var locations: Array[Vector2i] = []
	locations.assign(location_coords)
	level.location_coords = locations
	return level


func _create_location_manager_instance(location_coords_array: Array = [], locations_array: Array = []) -> LocationManager:
	var location_manager_instance = LocationManager.new()
	var grid_node = Node2D.new()
	auto_free(grid_node)

	var coords: Array[Vector2i] = []
	for coord in location_coords_array:
		coords.append(coord)
	var final_locations_array: Array[TargetTask] = []
	for i in range(location_coords_array.size()):
		if i < locations_array.size() and locations_array[i] is TargetTask:
			final_locations_array.append(locations_array[i])
		else:
			final_locations_array.append(auto_free(TargetTask.new()))

	location_manager_instance.setup(coords, final_locations_array, grid_node)
	return auto_free(location_manager_instance)

func test_location_reached_prevents_subsequent_moves() -> void:
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	assert_that(scene).is_not_null()
	await runner.simulate_frames(1)

	var level = _make_level([Vector2i(0, 0)], [Vector2i(2, 2)])
	scene.set_level_and_rebuild(level)
	await runner.simulate_frames(1)

	# Manually place the player at the location to trigger completion
	scene.set_player_coord(scene.location_coord)
	scene.update_location_progress_for_selected()
	await runner.simulate_frames(1)

	# Verify location is marked as reached
	assert_bool(scene._location_reached).is_true()

	var coord_at_location = scene.player_coord

	# Attempt to move after location is reached
	scene.request_move("move_s")
	await runner.simulate_frames(1)

	# Assert that the player's coordinate has not changed
	assert_that(scene.player_coord).is_equal(coord_at_location)

func test_gameplay_set_location_coord_updates_location_manager():
	# Given
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	assert_that(scene).is_not_null()
	await runner.simulate_frames(1)

	var initial_location_coord = Vector2i(0, 0)
	var new_location_coord = Vector2i(5, 5)

	var level = _make_level([], [initial_location_coord])
	scene.set_level_and_rebuild(level)
	await runner.simulate_frames(1)

	# When
	scene.set_location_coord(new_location_coord)
	await runner.simulate_frames(1) # Allow for any deferred updates

	# Then
	assert_that(scene._game_state.location_manager.get_target(0)).is_equal(new_location_coord)

# ============================================================================
# Gameplay/location_manager.gd: set_target
# ============================================================================
func test_location_manager_set_target_updates_coordinate() -> void:
	# Given
	var initial_location_coord = Vector2i(0, 0)
	var new_location_coord = Vector2i(5, 5)
	var locations: Array[TargetTask] = [auto_free(TargetTask.new())]
	var location_manager = _create_location_manager_instance([initial_location_coord], locations)

	# When
	location_manager.set_target(0, new_location_coord)

	# Then
	assert_that(location_manager.get_target(0)).is_equal(new_location_coord)
	# Test for out of bounds index
	location_manager.set_target(99, Vector2i(1,1)) # Should not crash
	assert_that(location_manager.get_target(99)).is_equal(Vector2i(-999, -999)) # Should return default error coord

# ============================================================================
# Gameplay/location_manager.gd: get_targets
# ============================================================================
func test_location_manager_get_targets_returns_all_location_coordinates() -> void:
	# Given
	var location_coords = [Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 2)]
	var locations: Array[TargetTask] = [auto_free(TargetTask.new()), auto_free(TargetTask.new()), auto_free(TargetTask.new())]
	var location_manager = _create_location_manager_instance(location_coords, locations)

	# When
	var targets = location_manager.get_targets()

	# Then
	assert_array(targets).is_equal(location_coords)

# ============================================================================
# Gameplay/location_manager.gd: get_location_node
# ============================================================================
func test_location_manager_get_location_node_returns_correct_node() -> void:
	# Given
	var location_node_0: TargetTask = TargetTask.new()
	var location_node_1: TargetTask = TargetTask.new()
	auto_free(location_node_0)
	auto_free(location_node_1)
	var location_coords = [Vector2i(0, 0), Vector2i(1, 1)]
	var locations: Array[TargetTask] = [location_node_0, location_node_1]
	var location_manager = _create_location_manager_instance(location_coords, locations)

	# When
	var node_0 = location_manager.get_location_node(0)
	var node_1 = location_manager.get_location_node(1)
	var node_invalid = location_manager.get_location_node(99)

	# Then
	assert_object(node_0).is_equal(location_node_0)
	assert_object(node_1).is_equal(location_node_1)
	assert_object(node_invalid).is_null()

func test_location_action_available_immediately_after_move() -> void:
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	assert_that(scene).is_not_null()
	await runner.simulate_frames(1)

	var level = _make_level([Vector2i(1, 1)], [Vector2i(2, 1)])
	scene.set_level_and_rebuild(level)
	await runner.simulate_frames(2)

	var move_controller: MoveController = scene._game_state.move_controller
	move_controller.request_move_to_coord(Vector2i(2, 1))
	await runner.simulate_frames(1)
	move_controller.confirm_move()
	await runner.simulate_frames(2)

	var hud_components: HUDComponentFactory.Components = scene._game_state.hud_controller._components
	var labels: Array = []
	for child in hud_components.actions_panel.get_children():
		if child is Button:
			labels.append(child.text)

	assert_array(labels).contains("Work on task")



func test_location_manager_get_location_index_at_returns_expected_index() -> void:
	var location_coords = [Vector2i(2, 2), Vector2i(4, 1)]
	var locations: Array[TargetTask] = [auto_free(TargetTask.new()), auto_free(TargetTask.new())]
	var location_manager = _create_location_manager_instance(location_coords, locations)
	assert_int(location_manager.get_location_index_at(Vector2i(2, 2))).is_equal(0)
	assert_int(location_manager.get_location_index_at(Vector2i(4, 1))).is_equal(1)
	assert_int(location_manager.get_location_index_at(Vector2i(9, 9))).is_equal(-1)

func test_location_manager_location_info_reports_progress() -> void:
	var location_coords = [Vector2i(1, 1)]
	var locations: Array[TargetTask] = [auto_free(TargetTask.new())]
	var location_manager = _create_location_manager_instance(location_coords, locations)
	var worker: FakelocationUnit = auto_free(FakelocationUnit.new())
	worker.set_attribute_value(3)
	location_manager.apply_progress(0, worker)
	var info = location_manager.get_location_info(0)
	assert_str(info.get("title", "")).contains("task")
	assert_int(info.get("player_progress", 0)).is_equal(3)
	assert_str(info.get("required_attribute", "")).is_equal("grit")

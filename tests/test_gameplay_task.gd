extends GdUnitTestSuite

const HexTestUtils = preload("res://tests/base_test_suite.gd")
const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"
const TaskManager := preload("res://Gameplay/narrative/task/task_manager.gd")
const LevelScript := preload("res://level/Level.gd")
const LevelTaskEntry := preload("res://level/level_task_entry.gd")
const Objective := preload("res://Gameplay/narrative/task/objective.gd")
const Stage := preload("res://Gameplay/narrative/task/stage.gd")
const Task := preload("res://Gameplay/narrative/task/task.gd")
const Unit := preload("res://Gameplay/targets/unit.gd")

var _control_settings: Node
var _input_mapper: Node

func before_test() -> void:
	var instances = await HexTestUtils.setup_autoloads(get_tree(), {
		"ControlSettings": "res://Autoloads/control_settings.gd",
		"InputMapper": "res://Autoloads/input_mapper.gd",
	})
	_control_settings = instances["ControlSettings"]
	_input_mapper = instances["InputMapper"]

func after_test() -> void:
	await HexTestUtils.teardown_autoloads(get_tree())

func _make_level(player_starts: Array[Vector2i], location_coords: Array[Vector2i]) -> Level:
	var level := LevelScript.new()
	var starts: Array[Vector2i] = []
	starts.assign(player_starts)
	level.player_starts = starts

	var locations: Array[LevelTaskEntry] = []
	for coord in location_coords:
		var entry = LevelTaskEntry.new()
		entry.coord = coord
		var scene = PackedScene.new()
		var node = Node2D.new()
		node.name = "Location"
		# Needs a loc_name for matching
		var script = GDScript.new()
		script.source_code = "extends Node2D\nvar loc_name := 'test_loc'\nvar coord: Vector2i\nsignal interacted"
		script.reload()
		node.set_script(script)

		scene.pack(node)
		entry.location_scene = scene
		locations.append(entry)
	level.locations = locations

	var obj = Objective.new()
	var stage = Stage.new()
	var task = auto_free(func():
		var sc = GDScript.new()
		sc.source_code = "extends Node\nvar status = 1\nvar target_coord: Vector2i\nvar target_id := 'test_loc'\nfunc get_status() -> int: return status"
		sc.reload()
		return sc.new()
	).call()
	if location_coords.size() > 0:
		task.target_coord = location_coords[0]
	stage.active_tasks = [task]
	obj.current_stage = stage
	level.objective = obj

	return level

func test_gameplay_scene_builds_locations() -> void:
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	assert_that(scene).is_not_null()
	await runner.simulate_frames(1)

	var level = _make_level([Vector2i(0, 0)], [Vector2i(2, 2)])
	scene.set_level_and_rebuild(level)
	await runner.simulate_frames(1)

	var task_manager: TaskManager = scene._game_state.task_manager
	assert_that(task_manager).is_not_null()

	var loc = task_manager.get_location_at(Vector2i(2, 2))
	assert_that(loc).is_not_null()

	var task = task_manager.get_task_for_target(loc)
	assert_that(task).is_not_null()

func test_interact_location_triggers_task_manager() -> void:
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	assert_that(scene).is_not_null()
	await runner.simulate_frames(1)

	var level = _make_level([Vector2i(0, 0)], [Vector2i(2, 2)])
	scene.set_level_and_rebuild(level)
	await runner.simulate_frames(1)

	var task_manager: TaskManager = scene._game_state.task_manager
	var loc = task_manager.get_location_at(Vector2i(2, 2))

	# Simulate unit interact
	var unit = Unit.new()
	loc.coord = Vector2i(2, 2)
	loc.interacted.emit(unit)
	await runner.simulate_frames(1)

	# With the mock task, we just verify no crash happened and tasks are properly bound.
	auto_free(unit)

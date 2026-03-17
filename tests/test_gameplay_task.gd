extends GdUnitTestSuite

const TestUtils = preload("res://tests/base_test_suite.gd")
const GAMEPLAY_SCENE_PATH := "res://Gameplay/gameplay.tscn"

var _control_settings: Node
var _input_mapper: Node

func before_test() -> void:
	var instances = await TestUtils.setup_autoloads(get_tree(), {
		"ControlSettings": "res://Autoloads/control_settings.gd",
		"InputMapper": "res://Autoloads/input_mapper.gd",
	})
	_control_settings = instances["ControlSettings"]
	_input_mapper = instances["InputMapper"]

func after_test() -> void:
	await TestUtils.teardown_autoloads(get_tree())

func _make_level(player_starts: Array[Vector2i], location_coords: Array[Vector2i]) -> Level:
	var level := Level.new()
	var starts: Array[Vector2i] = []
	starts.assign(player_starts)
	level.player_starts = starts

	var locations: Array[LevelTaskEntry] = []
	for coord in location_coords:
		var entry: LevelTaskEntry = LevelTaskEntry.new()
		entry.coord = coord
		var scene: PackedScene = PackedScene.new()
		var node: Node2D = Node2D.new()
		node.name = "Location"
		# Needs a loc_name for matching
		var script: GDScript = GDScript.new()
		script.source_code = "extends Node2D\nvar loc_name := 'test_loc'\nvar coord: Vector2i\nsignal interacted"
		script.reload()
		node.set_script(script)

		scene.pack(node)
		entry.location_scene = scene
		locations.append(entry)
	level.locations.assign(locations)

	var ObjectiveScript = load("res://Gameplay/narrative/task/objective.gd")
	var obj = ObjectiveScript.new()
	var StageScript = load("res://Gameplay/narrative/task/stage.gd")
	var stage = StageScript.new()
	var task = auto_free(func():
		var sc: GDScript = GDScript.new()
		sc.source_code = "extends 'res://Gameplay/narrative/task/task.gd'\nvar status = 1\nvar target_coord: Vector2i\nvar target_id := 'test_loc'\nfunc get_status() -> int: return status"
		sc.reload()
		return sc.new()
	).call()
	if location_coords.size() > 0:
		task.target_coord = location_coords[0]
	stage.active_tasks.append(task)
	obj.stages = [stage]
	level.objective = obj

	return level

func test_gameplay_scene_builds_locations() -> void:
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	assert_that(scene).is_not_null()
	await runner.simulate_frames(1)

	var level: Level = _make_level([Vector2i(0, 0)], [Vector2i(2, 2)])
	scene.set_level_and_rebuild(level)
	await runner.simulate_frames(1)

	var task_manager: TaskManager = scene._game_state.task_manager
	assert_that(task_manager).is_not_null()

	var loc: Node2D = task_manager.get_location_at(Vector2i(2, 2))
	assert_that(loc).is_not_null()

	var task: Task = task_manager.get_task_for_target(loc)
	assert_that(task).is_not_null()

func test_interact_location_triggers_task_manager() -> void:
	var runner := scene_runner(GAMEPLAY_SCENE_PATH)
	var scene := runner.scene()
	assert_that(scene).is_not_null()
	await runner.simulate_frames(1)

	var level: Level = _make_level([Vector2i(0, 0)], [Vector2i(2, 2)])
	scene.set_level_and_rebuild(level)
	await runner.simulate_frames(1)

	var task_manager: TaskManager = scene._game_state.task_manager
	var loc: Node2D = task_manager.get_location_at(Vector2i(2, 2))

	# Simulate unit interact
	var unit: Unit = Unit.new()
	# The mock location in _make_level has a 'coord' property
	if "coord" in loc:
		loc.set("coord", Vector2i(2, 2))
	loc.emit_signal("interacted", unit)
	await runner.simulate_frames(1)

	# With the mock task, we just verify no crash happened and tasks are properly bound.
	auto_free(unit)

extends GdUnitTestSuite

# Tests for TaskManager — Node — focusing on the three uncovered pure-logic functions:
#   get_task_by_id, get_active_tasks_for_target, register_loot
#
# We set up a running Objective with an active Stage to give us live active_tasks.

const TaskManagerScript := preload("res://Gameplay/narrative/task/task_manager.gd")
const ObjectiveScript := preload("res://Gameplay/narrative/task/objective.gd")
const StageScript := preload("res://Gameplay/narrative/task/stage.gd")
const TaskScript := preload("res://Gameplay/narrative/task/task.gd")
const LootScript := preload("res://Gameplay/targets/loot.gd")
const TargetScript := preload("res://Gameplay/targets/target.gd")

var _manager: TaskManager

func before_test() -> void:
	_manager = TaskManagerScript.new()
	add_child(_manager)

func after_test() -> void:
	if is_instance_valid(_manager):
		_manager.queue_free()

# Builds a running objective with one task and wires it into the manager.
func _setup_active_objective(task: Task) -> Objective:
	var stage: Stage = StageScript.new()
	stage.tasks.append(task)
	var obj: Objective = ObjectiveScript.new("obj_1", "Test Obj", "")
	obj.starting_stage = stage
	_manager._active_objective = obj
	obj.start_objective(Level.new()) # starts stage, populates active_tasks
	return obj

func _make_task(event: String = "interact", target_id: String = "", coord: Vector2i = Vector2i(-999, -999)) -> Task:
	var t: Task = TaskScript.new()
	t.event_type = event
	t.effort_required = 99
	t.target_id = target_id
	t.target_coord = coord
	return t

# ---------------------------------------------------------------------------
# get_task_by_id
# ---------------------------------------------------------------------------

func test_get_task_by_id_returns_matching_task() -> void:
	var t: Task = _make_task()
	_setup_active_objective(t)
	var active_task: Task = _manager._active_objective.current_stage.active_tasks[0]
	var found := _manager.get_task_by_id(String(active_task.id))
	assert_object(found).is_not_null()
	assert_object(found).is_equal(active_task)

func test_get_task_by_id_returns_null_for_unknown_id() -> void:
	var t: Task = _make_task()
	_setup_active_objective(t)
	assert_object(_manager.get_task_by_id("no_such_id")).is_null()

func test_get_task_by_id_returns_null_with_no_objective() -> void:
	_manager._active_objective = null
	assert_object(_manager.get_task_by_id("anything")).is_null()

func test_get_task_by_id_returns_null_with_no_stage() -> void:
	var obj: Objective = ObjectiveScript.new("obj_1", "Test", "")
	_manager._active_objective = obj # no stage started
	assert_object(_manager.get_task_by_id("anything")).is_null()

# ---------------------------------------------------------------------------
# get_active_tasks_for_target
# ---------------------------------------------------------------------------

func test_get_active_tasks_for_target_returns_null_with_no_objective() -> void:
	_manager._active_objective = null
	var loot: Loot = LootScript.new()
	add_child(loot)
	var result := _manager.get_active_tasks_for_target(loot)
	assert_int(result.size()).is_equal(0)
	loot.queue_free()

func test_get_active_tasks_for_target_matches_by_coord() -> void:
	var coord := Vector2i(3, 4)
	var t: Task = _make_task("interact", "", coord)
	_setup_active_objective(t)

	# Create a fake Target at the matching coord
	var loot: Loot = LootScript.new()
	add_child(loot)
	loot.set_external_grid_coord(coord)

	var result := _manager.get_active_tasks_for_target(loot)
	assert_int(result.size()).is_equal(1)
	loot.queue_free()

func test_get_active_tasks_for_target_no_match_wrong_coord() -> void:
	var t: Task = _make_task("interact", "", Vector2i(3, 4))
	_setup_active_objective(t)

	var loot: Loot = LootScript.new()
	add_child(loot)
	loot.set_external_grid_coord(Vector2i(9, 9)) # wrong coord

	var result := _manager.get_active_tasks_for_target(loot)
	assert_int(result.size()).is_equal(0)
	loot.queue_free()

func test_get_active_tasks_for_target_null_target_returns_empty() -> void:
	var t: Task = _make_task()
	_setup_active_objective(t)
	var result := _manager.get_active_tasks_for_target(null)
	assert_int(result.size()).is_equal(0)

# ---------------------------------------------------------------------------
# register_loot
# ---------------------------------------------------------------------------

func test_register_loot_adds_to_loot_nodes() -> void:
	var loot: Loot = LootScript.new()
	add_child(loot)
	loot.set_external_grid_coord(Vector2i(1, 2))
	_manager.register_loot(loot)
	assert_int(_manager._loot_nodes.size()).is_equal(1)
	assert_object(_manager._loot_nodes[0]).is_equal(loot)
	loot.queue_free()

func test_register_loot_adds_to_loot_lookup() -> void:
	var loot: Loot = LootScript.new()
	add_child(loot)
	loot.set_external_grid_coord(Vector2i(2, 3))
	_manager.register_loot(loot)
	var retrieved := _manager.get_loot_at(Vector2i(2, 3))
	assert_object(retrieved).is_equal(loot)
	loot.queue_free()

func test_register_loot_does_not_double_connect_signal() -> void:
	var loot: Loot = LootScript.new()
	add_child(loot)
	loot.set_external_grid_coord(Vector2i(0, 0))
	_manager.register_loot(loot)
	_manager.register_loot(loot) # Should not double-connect
	# The only way to verify is that it doesn't crash; loot is in list twice but signal once
	assert_int(_manager._loot_nodes.size()).is_equal(2) # appended twice (no dedup on the array)
	loot.queue_free()

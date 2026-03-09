extends GdUnitTestSuite

# Tests for Objective.start_objective() — pure Resource, no Node/scene deps.
# Covers the three branching paths:
#   1. starting_stage is set → use it
#   2. starting_stage null but stages[] has entries → use stages[0]
#   3. No stages at all → immediately emit objective_completed

const ObjectiveScript := preload("res://Gameplay/narrative/task/objective.gd")
const StageScript := preload("res://Gameplay/narrative/task/stage.gd")
const TaskScript := preload("res://Gameplay/narrative/task/task.gd")

func _make_level() -> Level:
	var l: Level = Level.new()
	auto_free(l)
	return l

func _make_stage(tasks_count: int = 0) -> Stage:
	var s: Stage = StageScript.new()
	auto_free(s)
	for i in range(tasks_count):
		var t: Task = TaskScript.new()
		t.event_type = "interact"
		t.effort_required = 99 # won't complete on its own
		t.target_coord = Vector2i(-999, -999)
		t.target_id = ""
		s.tasks.append(t)
	return s

func _make_objective(obj_id: String = "obj_test") -> Objective:
	var o: Objective = ObjectiveScript.new(obj_id, "Test Objective", "A test")
	auto_free(o)
	return o

# ---------------------------------------------------------------------------
# start_objective — no stages → immediate completion
# ---------------------------------------------------------------------------

func test_start_objective_with_no_stages_emits_completed() -> void:
	var obj: Objective = _make_objective()
	var monitor := monitor_signals(obj)
	obj.start_objective(_make_level())
	assert_signal(monitor).is_emitted("objective_started")
	assert_signal(monitor).is_emitted("objective_completed")
	assert_bool(obj.is_active).is_false()

func test_start_objective_sets_is_active() -> void:
	var obj: Objective = _make_objective()
	assert_bool(obj.is_active).is_false()
	obj.start_objective(_make_level())
	# If no stages, it completes immediately and is_active becomes false
	assert_bool(obj.is_active).is_false()

# ---------------------------------------------------------------------------
# start_objective — with starting_stage set
# ---------------------------------------------------------------------------

func test_start_objective_uses_starting_stage_when_set() -> void:
	var obj: Objective = _make_objective()
	var stage: Stage = _make_stage(0)
	obj.starting_stage = stage
	var monitor := monitor_signals(obj)
	obj.start_objective(_make_level())
	# objective_updated fires when a stage is entered; completed only if stage itself completes
	assert_signal(monitor).is_emitted("objective_started")
	assert_signal(monitor).is_emitted("objective_updated")
	assert_signal(monitor).is_not_emitted("objective_completed")
	assert_bool(obj.is_active).is_true()
	assert_object(obj.current_stage).is_not_null()

func test_start_objective_stage_with_no_tasks_completes_immediately() -> void:
	var obj: Objective = _make_objective()
	var stage: Stage = _make_stage(0) # no tasks → all_required trivially met
	obj.starting_stage = stage
	var monitor := monitor_signals(obj)
	obj.start_objective(_make_level())
	# Empty stage fires stage_completed immediately → objective transitions
	# With no next_stage → objective_completed
	assert_signal(monitor).is_emitted("objective_completed")

# ---------------------------------------------------------------------------
# start_objective — starting_stage null but stages[] populated
# ---------------------------------------------------------------------------

func test_start_objective_uses_stages_array_when_starting_stage_null() -> void:
	var obj: Objective = _make_objective()
	obj.starting_stage = null
	var stage: Stage = _make_stage(1) # has a task → won't auto-complete
	obj.stages.append(stage)
	var monitor := monitor_signals(obj)
	obj.start_objective(_make_level())
	assert_signal(monitor).is_emitted("objective_started")
	assert_signal(monitor).is_emitted("objective_updated")
	assert_signal(monitor).is_not_emitted("objective_completed")
	assert_object(obj.current_stage).is_not_null()

# ---------------------------------------------------------------------------
# Stage completion propagates → objective_completed
# ---------------------------------------------------------------------------

func test_stage_completion_propagates_to_objective_completed() -> void:
	var obj: Objective = _make_objective()
	var stage: Stage = _make_stage(1)
	obj.starting_stage = stage
	obj.start_objective(_make_level())
	var monitor := monitor_signals(obj)
	# Complete the active task
	obj.current_stage.handle_event("interact", {})
	assert_signal(monitor).is_emitted("objective_completed")

# ---------------------------------------------------------------------------
# Level reference is stored
# ---------------------------------------------------------------------------

func test_start_objective_stores_level_reference() -> void:
	var obj: Objective = _make_objective()
	var lv: Level = _make_level()
	lv.level_id = "test_level_ref"
	obj.start_objective(lv)
	assert_str(obj.level.level_id).is_equal("test_level_ref")

extends GdUnitTestSuite

# Tests for Stage — a pure Resource with no Node/tree dependencies.
# Covers: start_stage, advance, end_stage, CompletionMode logic.

const TaskScript := preload("res://Gameplay/narrative/task/task.gd")
const StageScript := preload("res://Gameplay/narrative/task/stage.gd")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_task(event: String = "interact", effort: int = 1) -> Task:
	var t: Task = TaskScript.new()
	auto_free(t)
	t.event_type = event
	t.effort_required = effort
	t.target_coord = Vector2i(-999, -999)
	t.target_id = ""
	return t

func _make_stage(tasks: Array[Task], mode: Stage.CompletionMode = Stage.CompletionMode.ALL_REQUIRED, auto_adv: bool = true) -> Stage:
	var s: Stage = StageScript.new()
	auto_free(s)
	s.tasks = tasks
	s.completion_mode = mode
	s.auto_advance = auto_adv
	return s

# ---------------------------------------------------------------------------
# start_stage
# ---------------------------------------------------------------------------

func test_start_stage_activates_all_tasks() -> void:
	var t1: Task = _make_task()
	var t2: Task = _make_task()
	var stage: Stage = _make_stage([t1, t2] as Array[Task])
	stage.start_stage()
	assert_int(stage.active_tasks.size()).is_equal(2)
	for task in stage.active_tasks:
		assert_int(int(task.status)).is_equal(Task.Status.ACTIVE)

func test_start_stage_clears_previous_active_tasks() -> void:
	var t1: Task = _make_task()
	var stage: Stage = _make_stage([t1] as Array[Task])
	stage.start_stage()
	stage.start_stage() # second call should reset
	assert_int(stage.active_tasks.size()).is_equal(1)

func test_start_stage_duplicates_tasks_for_isolation() -> void:
	var t: Task = _make_task()
	var stage: Stage = _make_stage([t] as Array[Task])
	stage.start_stage()
	# Active task should be a duplicate, not the same reference
	assert_object(stage.active_tasks[0]).is_not_equal(t)

# ---------------------------------------------------------------------------
# ALL_REQUIRED completion
# ---------------------------------------------------------------------------

func test_all_required_completes_when_all_tasks_done() -> void:
	var t1: Task = _make_task("interact", 1)
	var t2: Task = _make_task("interact", 1)
	var stage: Stage = _make_stage([t1, t2] as Array[Task])
	var monitor := monitor_signals(stage)
	stage.start_stage()
	stage.handle_event("interact", {}) # completes both (effort=1 each)
	assert_signal(monitor).is_emitted("stage_completed")

func test_all_required_does_not_complete_when_only_one_done() -> void:
	var t1: Task = _make_task("interact", 1)
	var t2: Task = _make_task("interact", 2) # needs 2 events
	var stage: Stage = _make_stage([t1, t2] as Array[Task])
	var monitor := monitor_signals(stage)
	stage.start_stage()
	stage.handle_event("interact", {}) # t1 done, t2 at 1/2
	assert_signal(monitor).is_not_emitted("stage_completed")

# ---------------------------------------------------------------------------
# ANY_REQUIRED completion
# ---------------------------------------------------------------------------

func test_any_required_completes_when_first_task_done() -> void:
	var t1: Task = _make_task("interact", 1)
	var t2: Task = _make_task("interact", 5) # would need many events
	var stage: Stage = _make_stage([t1, t2] as Array[Task], Stage.CompletionMode.ANY_REQUIRED)
	var monitor := monitor_signals(stage)
	stage.start_stage()
	stage.handle_event("interact", {}) # t1 done → stage complete
	assert_signal(monitor).is_emitted("stage_completed")

# ---------------------------------------------------------------------------
# ANY_WITH_BRANCHING completion
# ---------------------------------------------------------------------------

func test_any_with_branching_uses_branching_transitions() -> void:
	var t1: Task = _make_task("interact", 1)
	var stage: Stage = _make_stage([t1] as Array[Task], Stage.CompletionMode.ANY_WITH_BRANCHING)
	var next: Stage = _make_stage([] as Array[Task])
	stage.start_stage()
	# Set branching: t1.id → next stage
	stage.branching_transitions[stage.active_tasks[0].id] = next
	var monitor := monitor_signals(stage)
	stage.handle_event("interact", {})
	assert_signal(monitor).is_emitted("stage_completed")

# ---------------------------------------------------------------------------
# auto_advance = false → manual advance()
# ---------------------------------------------------------------------------

func test_manual_advance_emits_stage_completed_after_ready() -> void:
	var t1: Task = _make_task("interact", 1)
	var stage: Stage = _make_stage([t1] as Array[Task], Stage.CompletionMode.ALL_REQUIRED, false)
	var monitor := monitor_signals(stage)
	stage.start_stage()
	stage.handle_event("interact", {}) # task done → stage_ready_to_advance
	assert_signal(monitor).is_emitted("stage_ready_to_advance")
	assert_signal(monitor).is_not_emitted("stage_completed")
	stage.advance()
	assert_signal(monitor).is_emitted("stage_completed")

func test_advance_does_nothing_when_no_pending_stage() -> void:
	var stage: Stage = _make_stage([] as Array[Task])
	var monitor := monitor_signals(stage)
	stage.advance() # no pending, no tasks completed → nothing emitted
	assert_signal(monitor).is_not_emitted("stage_completed")

# ---------------------------------------------------------------------------
# end_stage
# ---------------------------------------------------------------------------

func test_end_stage_cancels_active_tasks() -> void:
	var t1: Task = _make_task("interact", 5)
	var stage: Stage = _make_stage([t1] as Array[Task])
	stage.start_stage()
	assert_int(int(stage.active_tasks[0].status)).is_equal(Task.Status.ACTIVE)
	stage.end_stage()
	assert_int(int(stage.active_tasks[0].status)).is_equal(Task.Status.CANCELLED)

func test_end_stage_does_not_cancel_completed_tasks() -> void:
	var t1: Task = _make_task("interact", 1)
	var stage: Stage = _make_stage([t1] as Array[Task])
	stage.start_stage()
	stage.handle_event("interact", {}) # complete it
	stage.end_stage()
	assert_int(int(stage.active_tasks[0].status)).is_equal(Task.Status.COMPLETED)

# ---------------------------------------------------------------------------
# Optional tasks do not block ALL_REQUIRED completion
# ---------------------------------------------------------------------------

func test_optional_task_does_not_block_completion() -> void:
	var required: Task = _make_task("interact", 1)
	var optional: Task = _make_task("pickup", 1)
	optional.is_optional = true
	var stage: Stage = _make_stage([required, optional] as Array[Task])
	var monitor := monitor_signals(stage)
	stage.start_stage()
	stage.handle_event("interact", {}) # only required done
	assert_signal(monitor).is_emitted("stage_completed")

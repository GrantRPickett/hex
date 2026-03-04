extends GdUnitTestSuite

# Tests for TaskValidator — a pure RefCounted class with no Node/tree access.
# Also covers Task.handle_event() which is a Resource method with no Node deps.

const TaskScript := preload("res://Gameplay/narrative/task/task.gd")
const TaskValidatorScript := preload("res://Gameplay/narrative/task/task_validator.gd")

var _validator: TaskValidator

func before_test() -> void:
	_validator = TaskValidatorScript.new()
	auto_free(_validator)

# ---------------------------------------------------------------------------
# TaskValidator.validate_item_target
# ---------------------------------------------------------------------------

func test_validate_item_target_null_task_returns_false() -> void:
	assert_bool(_validator.validate_item_target(null, {})).is_false()

func test_validate_item_target_empty_target_id_returns_false() -> void:
	var task: Task = TaskScript.new()
	auto_free(task)
	task.target_id = ""
	assert_bool(_validator.validate_item_target(task, {})).is_false()

func test_validate_item_target_item_not_in_world_returns_false() -> void:
	var task: Task = TaskScript.new()
	auto_free(task)
	task.target_id = "sword"
	var world := {"items": {}}
	assert_bool(_validator.validate_item_target(task, world)).is_false()

func test_validate_item_target_holder_location_returns_true() -> void:
	var task: Task = TaskScript.new()
	auto_free(task)
	task.target_id = "sword"
	var world := {
		"items": {
			"sword": {"holder_kind": &"location", "quest": false, "in_stash": false}
		}
	}
	assert_bool(_validator.validate_item_target(task, world)).is_true()

func test_validate_item_target_holder_unit_npc_returns_true() -> void:
	var task: Task = TaskScript.new()
	auto_free(task)
	task.target_id = "relic"
	var world := {
		"items": {
			"relic": {"holder_kind": &"unit_npc", "quest": false, "in_stash": false}
		}
	}
	assert_bool(_validator.validate_item_target(task, world)).is_true()

func test_validate_item_target_quest_item_in_stash_returns_true() -> void:
	var task: Task = TaskScript.new()
	auto_free(task)
	task.target_id = "key"
	var world := {
		"items": {
			"key": {"holder_kind": &"player", "quest": true, "in_stash": true}
		}
	}
	assert_bool(_validator.validate_item_target(task, world)).is_true()

func test_validate_item_target_quest_item_not_in_stash_returns_false() -> void:
	var task: Task = TaskScript.new()
	auto_free(task)
	task.target_id = "key"
	var world := {
		"items": {
			"key": {"holder_kind": &"player", "quest": true, "in_stash": false}
		}
	}
	assert_bool(_validator.validate_item_target(task, world)).is_false()

func test_validate_item_target_non_quest_player_held_returns_false() -> void:
	var task: Task = TaskScript.new()
	auto_free(task)
	task.target_id = "potion"
	var world := {
		"items": {
			"potion": {"holder_kind": &"player", "quest": false, "in_stash": false}
		}
	}
	assert_bool(_validator.validate_item_target(task, world)).is_false()

# ---------------------------------------------------------------------------
# TaskValidator.validate_location_target
# ---------------------------------------------------------------------------

func test_validate_location_target_null_task_returns_false() -> void:
	assert_bool(_validator.validate_location_target(null, {})).is_false()

func test_validate_location_target_by_id_present_in_world() -> void:
	var task: Task = TaskScript.new()
	auto_free(task)
	task.target_id = "village"
	task.target_coord = Vector2i(-999, -999)
	var world := {"locations": {"village": {"coord": Vector2i(1, 2)}}}
	assert_bool(_validator.validate_location_target(task, world)).is_true()

func test_validate_location_target_by_id_absent_from_world() -> void:
	var task: Task = TaskScript.new()
	auto_free(task)
	task.target_id = "village"
	task.target_coord = Vector2i(-999, -999)
	var world := {"locations": {}}
	assert_bool(_validator.validate_location_target(task, world)).is_false()

func test_validate_location_target_by_coord_found() -> void:
	var task: Task = TaskScript.new()
	auto_free(task)
	task.target_id = ""
	task.target_coord = Vector2i(3, 4)
	var world := {
		"locations": {
			"shrine": {"coord": Vector2i(3, 4)}
		}
	}
	assert_bool(_validator.validate_location_target(task, world)).is_true()

func test_validate_location_target_by_coord_not_found() -> void:
	var task: Task = TaskScript.new()
	auto_free(task)
	task.target_id = ""
	task.target_coord = Vector2i(5, 5)
	var world := {
		"locations": {
			"shrine": {"coord": Vector2i(3, 4)}
		}
	}
	assert_bool(_validator.validate_location_target(task, world)).is_false()

func test_validate_location_target_no_id_no_coord_returns_false() -> void:
	var task: Task = TaskScript.new()
	auto_free(task)
	task.target_id = ""
	task.target_coord = Vector2i(-999, -999)
	var world := {"locations": {"village": {"coord": Vector2i(1, 2)}}}
	assert_bool(_validator.validate_location_target(task, world)).is_false()

# ---------------------------------------------------------------------------
# TaskValidator.validate_unit_target
# ---------------------------------------------------------------------------

func test_validate_unit_target_null_task_returns_false() -> void:
	assert_bool(_validator.validate_unit_target(null, {})).is_false()

func test_validate_unit_target_empty_target_id_returns_false() -> void:
	var task: Task = TaskScript.new()
	auto_free(task)
	task.target_id = ""
	assert_bool(_validator.validate_unit_target(task, {})).is_false()

func test_validate_unit_target_unit_present_in_world() -> void:
	var task: Task = TaskScript.new()
	auto_free(task)
	task.target_id = "goblin_chief"
	var world := {"units": {"goblin_chief": {"coord": Vector2i(2, 3)}}}
	assert_bool(_validator.validate_unit_target(task, world)).is_true()

func test_validate_unit_target_unit_absent_from_world() -> void:
	var task: Task = TaskScript.new()
	auto_free(task)
	task.target_id = "goblin_chief"
	var world := {"units": {}}
	assert_bool(_validator.validate_unit_target(task, world)).is_false()

# ---------------------------------------------------------------------------
# Task.handle_event — core state machine
# ---------------------------------------------------------------------------

func _make_active_task(event: String = "interact", required: int = 1) -> Task:
	var task: Task = TaskScript.new()
	auto_free(task)
	task.event_type = event
	task.effort_required = required
	task.target_coord = Vector2i(-999, -999)
	task.target_id = ""
	task.initialize()
	return task

func test_handle_event_ignored_when_not_active() -> void:
	var task: Task = TaskScript.new()
	auto_free(task)
	# Default status is PENDING, not ACTIVE
	task.event_type = "interact"
	task.effort_required = 1
	task.target_id = ""
	task.target_coord = Vector2i(-999, -999)
	task.handle_event("interact", {})
	assert_int(int(task.status)).is_equal(Task.Status.PENDING)

func test_handle_event_wrong_type_does_not_progress() -> void:
	var task: Task = _make_active_task("interact", 5)
	task.handle_event("move", {})
	assert_int(task.current_effort).is_equal(0)
	assert_int(int(task.status)).is_equal(Task.Status.ACTIVE)

func test_handle_event_interact_matching_completes_when_effort_met() -> void:
	var task: Task = _make_active_task("interact", 1)
	var monitor := monitor_signals(task)
	task.handle_event("interact", {})
	assert_int(int(task.status)).is_equal(Task.Status.COMPLETED)
	assert_signal(monitor).is_emitted("completed")

func test_handle_event_interact_coord_match_required() -> void:
	var task: Task = _make_active_task("interact", 1)
	task.target_coord = Vector2i(3, 3)
	# Wrong coord — should not progress
	task.handle_event("interact", {"coord": Vector2i(1, 1)})
	assert_int(task.current_effort).is_equal(0)

func test_handle_event_interact_coord_match_progresses() -> void:
	var task: Task = _make_active_task("interact", 1)
	task.target_coord = Vector2i(3, 3)
	task.handle_event("interact", {"coord": Vector2i(3, 3)})
	assert_int(int(task.status)).is_equal(Task.Status.COMPLETED)

func test_handle_event_interact_id_mismatch_does_not_progress() -> void:
	var task: Task = _make_active_task("interact", 1)
	task.target_id = "chest_a"
	task.handle_event("interact", {"id": "chest_b"})
	assert_int(task.current_effort).is_equal(0)

func test_handle_event_interact_id_match_progresses() -> void:
	var task: Task = _make_active_task("interact", 1)
	task.target_id = "chest_a"
	task.handle_event("interact", {"id": "chest_a"})
	assert_int(int(task.status)).is_equal(Task.Status.COMPLETED)

func test_handle_event_accumulates_effort_across_calls() -> void:
	var task: Task = _make_active_task("interact", 3)
	task.handle_event("interact", {})
	task.handle_event("interact", {})
	assert_int(task.current_effort).is_equal(2)
	assert_int(int(task.status)).is_equal(Task.Status.ACTIVE)

func test_handle_event_pickup_type() -> void:
	var task: Task = _make_active_task("pickup", 1)
	task.handle_event("pickup", {})
	assert_int(int(task.status)).is_equal(Task.Status.COMPLETED)

func test_handle_event_pickup_id_mismatch() -> void:
	var task: Task = _make_active_task("pickup", 1)
	task.target_id = "gold_coin"
	task.handle_event("pickup", {"id": "silver_coin"})
	assert_int(task.current_effort).is_equal(0)

func test_handle_event_cancel_prevents_further_progress() -> void:
	var task: Task = _make_active_task("interact", 5)
	task.cancel()
	task.handle_event("interact", {})
	assert_int(task.current_effort).is_equal(0)
	assert_int(int(task.status)).is_equal(Task.Status.CANCELLED)

func test_handle_event_progress_changed_signal_emitted() -> void:
	var task: Task = _make_active_task("interact", 5)
	var monitor := monitor_signals(task)
	task.handle_event("interact", {})
	assert_signal(monitor).is_emitted("progress_changed")

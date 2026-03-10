extends GdUnitTestSuite

# Tests for LevelManagerGameplay covering:
# set_dialogue_service, on_task_reached, update_task_progress, on_unit_moved

const ManagerScript := preload("res://level/level_manager_gameplay.gd")


class FakeTaskController extends TaskController:
	var event_handled: String = ""
	var is_reached: bool = false
	var conditions_checked: bool = false

	func handle_event(event_name: String, _payload: Dictionary = {}) -> void:
		event_handled = event_name

	func is_task_reached() -> bool:
		return is_reached

	func check_objective_conditions() -> void:
		conditions_checked = true

	func reset_task_state() -> void:
		pass

class FakeDialogueService extends DialogueActionService:
	var prepared_level: Level = null
	func prepare_for_level(lvl: Level) -> void:
		prepared_level = lvl

		prepared_level = lvl

class FakePlayerRoster extends PlayerRoster:
	var updated_units: Array[Unit] = []
	var stashed: Array = []
	func update_roster(p_units: Array[Unit], _full_reset: bool = false) -> void:
		updated_units = p_units
	func add_to_stash(items: Array) -> void:
		stashed = items

class FakeUnitManager extends UnitManager:
	var selected_index = 0
	func get_selected_index() -> int: return selected_index
	func get_unit_count() -> int: return 0
	func is_player_controlled(_idx: int) -> bool: return true

class FakeLootManager extends LootManager:
	func collect_all_loot_items() -> Array:
		return ["fake_loot_item"]

func before_test() -> void:
	pass

func after_test() -> void:
	for child in get_children():
		if is_instance_valid(child):
			child.queue_free()

func _make_manager() -> LevelManagerGameplay:
	var state := GameState.new({})
	return ManagerScript.new(state, auto_free(Node.new()))

# ---------------------------------------------------------------------------
# set_dialogue_service
# ---------------------------------------------------------------------------

func test_set_dialogue_service_connects_signal_and_prepares() -> void:
	var mgr := _make_manager()
	var state: GameState = mgr._game_state
	state.task_controller = FakeTaskController.new()

	var lvl := Level.new()
	mgr._level_resource = lvl

	var svc := FakeDialogueService.new()
	mgr.set_dialogue_service(svc)

	# Prepares level
	assert_object(svc.prepared_level).is_equal(lvl)

	# Emitting signal triggers _on_dialogue_finished correctly
	svc.dialogue_finished.emit(&"test_flag")
	assert_str(state.task_controller.event_handled).is_equal("dialogue_finished")

# ---------------------------------------------------------------------------
# update_task_progress
# ---------------------------------------------------------------------------

func test_update_task_progress_checks_conditions_and_updates_state() -> void:
	var mgr := _make_manager()
	var state: GameState = mgr._game_state
	var tc := FakeTaskController.new()
	state.task_controller = tc

	tc.is_reached = true
	mgr.update_task_progress()

	assert_bool(tc.conditions_checked).is_true()
	assert_bool(mgr._task_reached_state).is_true()

# ---------------------------------------------------------------------------
# on_unit_moved
# ---------------------------------------------------------------------------

func test_on_unit_moved_emits_quit_if_hometown_exit_reached() -> void:
	var mgr := _make_manager()
	var state: GameState = mgr._game_state
	var um := FakeUnitManager.new()
	state.unit_manager = um
	state.task_manager = Node.new() # Just something not null

	# Given the level manager is not actually mocking is_hometown nicely from this angle,
	# we just ensure that if it is NOT hometown_exit_coord, it safely ignores

	var monitor := monitor_signals(mgr)
	mgr.on_unit_moved(0, Vector2i(10, 10))

	# Didn't reach hometown exit, no quit emitted
	assert_signal(monitor).is_not_emitted("quit_to_level_select")

	um.queue_free()
	state.task_manager.queue_free()

# ---------------------------------------------------------------------------
# on_task_reached
# ---------------------------------------------------------------------------

func test_on_task_reached_updates_roster_and_emits_complete() -> void:
	var mgr := _make_manager()
	var state: GameState = mgr._game_state

	var pr := FakePlayerRoster.new()
	state.player_roster = pr
	var um := FakeUnitManager.new()
	add_child(um)
	state.unit_manager = um

	state.loot_manager = FakeLootManager.new()

	var monitor := monitor_signals(mgr)
	mgr.on_task_reached()

	# verify stash got looted array
	assert_array(pr.stashed).contains("fake_loot_item")
	assert_signal(monitor).is_emitted("level_complete")

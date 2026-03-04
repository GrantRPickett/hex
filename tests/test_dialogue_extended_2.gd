extends GdUnitTestSuite

# Test trigger_at_coord and handle_dialogue_request

const DialogueActionScript = preload("res://Gameplay/narrative/dialogue/dialogue_action_service.gd")

class FakeUnitManager extends Node:
	var returned = null
	var selected_idx = 0
	func get_unit_count() -> int: return 1
	func get_unit(_idx) -> Unit: return returned
	func get_selected_unit() -> Unit: return returned
	func get_unit_index(_u) -> int: return 0
	func get_coord(_u) -> Vector2i: return Vector2i(1, 1)

class NullDialogueManager extends Node:
	pass
func _add_and_free(node: Node) -> Node:
	add_child(node)
	return auto_free(node)

func test_dialogue_action_trigger_at_coord() -> void:
	var dm = NullDialogueManager.new()
	dm.name = "DialogueManager"
	# We simulate having DialogueManager auto load
	# by placing it at root or adjusting the internal path
	get_tree().root.add_child(dm)
	auto_free(dm)

	var dm_path = dm.get_path()
	var d_svc = DialogueActionScript.new()
	d_svc._dialog_path = dm_path

	var um = auto_free(FakeUnitManager.new())
	d_svc._unit_manager = um

	var trigger = DialogueTrigger.new()
	trigger.dialogue_id = "test_1"
	trigger._grid_cell = Vector2i(1, 1)
	trigger.initiation_mode = 0 # CLICK

	d_svc._dialogue_triggers["test_1"] = trigger
	d_svc._active_flag = ""

	var result = d_svc.trigger_at_coord(Vector2i(99, 99))
	assert_bool(result.is_failure()).is_true()
	assert_str(result.get_error_message()).contains("No dialogue")

	# Missing unit
	var no_unit = d_svc.trigger_at_coord(Vector2i(1, 1))
	assert_bool(no_unit.is_failure()).is_true()
	assert_str(no_unit.get_error_message()).contains("No initiator")

	# With correct unit
	um.returned = auto_free(Unit.new())
	var success_run = d_svc.trigger_at_coord(Vector2i(1, 1), um.returned)
	assert_bool(success_run.is_failure()).is_false()

	trigger.queue_free()

func test_dialogue_action_handle_dialogue_request() -> void:
	var d_svc = DialogueActionScript.new()

	# Pass an invalid string
	# This shouldn't crash
	d_svc.handle_dialogue_request("res://invalid_path.tres")

	# With a valid path it should try to call DialogueManager,
	# We'll just verify no crash
	d_svc.handle_dialogue_request("res://Dialogue/Missing.dialogue")

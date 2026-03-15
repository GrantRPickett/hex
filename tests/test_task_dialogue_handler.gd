extends GdUnitTestSuite

const TaskDialogueHandlerScript = preload("res://Gameplay/narrative/task/task_dialogue_handler.gd")

func test_queue_stage_dialogues() -> void:
	var handler: TaskDialogueHandlerScript = TaskDialogueHandlerScript.new()
	handler.setup(null)

	# Mock stage with direct resource field
	var mock_stage_resource: GDScript = GDScript.new()
	mock_stage_resource.source_code = "extends Resource\nvar start_dialogue_resource = 'res://mock_start.dialogue'\nvar exit_dialogue_resource = ''"
	mock_stage_resource.reload()
	var stage: mock_stage_resource = mock_stage_resource.new()

	handler.queue_stage_dialogues(stage, "on_enter")
	assert_bool(handler._dialogue_queue.has("res://mock_start.dialogue")).is_true()

	# Clean up
	handler.free()

func test_process_queue() -> void:
	var handler: TaskDialogueHandlerScript = TaskDialogueHandlerScript.new()
	var monitor = monitor_signals(handler)
	handler.setup(null)

	handler._dialogue_queue.append("res://test1.dialogue")
	handler._dialogue_queue.append("res://test2.dialogue")

	assert_bool(handler.is_processing()).is_false()

	handler.process_queue()

	assert_bool(handler.is_processing()).is_true()
	assert_str(handler._current_dialogue).is_equal("res://test1.dialogue")
	assert_signal(monitor).is_emitted("dialogue_requested", ["res://test1.dialogue"])

	# Finish and process next
	handler.on_dialogue_finished()

	assert_bool(handler.is_processing()).is_true()
	assert_str(handler._current_dialogue).is_equal("res://test2.dialogue")
	assert_signal(monitor).is_emitted("dialogue_requested", ["res://test2.dialogue"])

	handler.free()

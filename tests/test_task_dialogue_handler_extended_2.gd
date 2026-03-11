extends GdUnitTestSuite

const TaskDialogueHandlerClass = preload("res://Gameplay/narrative/task/task_dialogue_handler.gd")
const StageClass = preload("res://Gameplay/narrative/task/stage.gd")
const TaskClass = preload("res://Gameplay/narrative/task/task.gd")

func test_task_dialogue_handler_queue_task_dialogues() -> void:
	var handler = auto_free(TaskDialogueHandlerClass.new())
	var stage = auto_free(StageClass.new())
	var task = auto_free(TaskClass.new())

	# Using the properties that test queue_task_dialogues
	stage.active_tasks = [task]

	task.start_dialogue_resource = "res://dialogue1.dialogue"

	handler.queue_task_dialogues(stage, "on_enter")
	assert_int(handler._dialogue_queue.size()).is_equal(1)
	assert_str(handler._dialogue_queue[0]).is_equal("res://dialogue1.dialogue")

	# Try on_exit
	task.exit_dialogue_resource = "res://dialogue2.dialogue"
	handler.queue_task_dialogues(stage, "on_exit")
	assert_int(handler._dialogue_queue.size()).is_equal(2)
	assert_str(handler._dialogue_queue[1]).is_equal("res://dialogue2.dialogue")

func test_task_dialogue_handler_get_queue_contents() -> void:
	var handler = auto_free(TaskDialogueHandlerClass.new())
	var arr: Array[String] = ["res://first.dialogue", "res://second.dialogue"]
	handler._dialogue_queue = arr

	var contents = handler.get_queue_contents()
	assert_str(contents).contains("first.dialogue")
	assert_str(contents).contains("second.dialogue")

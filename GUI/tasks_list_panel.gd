class_name TasksListPanel
extends CustomResizablePanel

@onready var _vbox: VBoxContainer = %TasksVBox

func _init() -> void:
	name = "TasksListPanel"

func update_tasks(tasks_data: Array) -> void:
	if not is_node_ready():
		return
	for child in _vbox.get_children():
		child.queue_free()

	if tasks_data.is_empty():
		return

	# Example for now: just add a label for each task
	for task_data in tasks_data:
		var label = Label.new()
		label.text = "Task: " + str(task_data)
		_vbox.add_child(label)

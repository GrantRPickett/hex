class_name TasksListPanel
extends PanelContainer

const TaskListItemScene := preload("res://GUI/task_list_item.tscn")

@onready var tasks_container: VBoxContainer = $MarginContainer/VBoxContainer

func _ready() -> void:
	hide()

func update_tasks(tasks_data: Array) -> void:
	for child in tasks_container.get_children():
		child.queue_free()

	if tasks_data.is_empty():
		hide()
		return

	show()
	for task_data in tasks_data:
		var task_item = TaskListItemScene.instantiate()
		tasks_container.add_child(task_item)
		if task_item.has_method("update_task"):
			task_item.update_task(task_data)
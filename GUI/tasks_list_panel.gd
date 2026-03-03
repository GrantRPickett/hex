class_name TasksListPanel
extends PanelContainer

const TaskListItemScene := preload("res://GUI/task_list_item.tscn")

signal task_hovered(task_data: Dictionary)
signal task_unhovered()

@onready var tasks_container: VBoxContainer = $MarginContainer/VBoxContainer

var _pending_tasks_data = null

func _ready() -> void:
	hide()
	if _pending_tasks_data != null:
		update_tasks(_pending_tasks_data)
		_pending_tasks_data = null

func update_tasks(tasks_data: Array) -> void:
	print_debug("[TasksListPanel] update_tasks called with ", tasks_data.size(), " tasks")
	if not is_node_ready():
		_pending_tasks_data = tasks_data
		return

	if not is_instance_valid(tasks_container):
		return
	for child in tasks_container.get_children():
		child.queue_free()

	if tasks_data.is_empty():
		return

	show()
	for task_data in tasks_data:
		var task_item = TaskListItemScene.instantiate()
		tasks_container.add_child(task_item)
		if task_item.has_method("update_task"):
			task_item.update_task(task_data)
			task_item.hovered.connect(func(data): task_hovered.emit(data))
			task_item.unhovered.connect(func(): task_unhovered.emit())

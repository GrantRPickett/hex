class_name TasksListPanel
extends PanelContainer

const TaskListItemScene := preload(FilePaths.Scenes.TASK_LIST_ITEM)

signal task_hovered(task_data: Dictionary)
signal task_unhovered()
signal task_completion_requested(task_id: String)

@onready var tasks_container: VBoxContainer = $MarginContainer/VBoxContainer

var _pending_tasks_data = null

func _ready() -> void:
	hide()
	if _pending_tasks_data != null:
		update_tasks(_pending_tasks_data)
		_pending_tasks_data = null

func update_tasks(grouped_tasks: Array) -> void:
	if not grouped_tasks.is_empty():
		print_debug("[TasksListPanel] update_tasks called with ", grouped_tasks.size(), " factions")
	
	if not is_node_ready():
		_pending_tasks_data = grouped_tasks
		return

	if not is_instance_valid(tasks_container):
		return
	for child in tasks_container.get_children():
		child.queue_free()

	if grouped_tasks.is_empty():
		hide()
		return

	show()
	for faction_group in grouped_tasks:
		var faction_name = faction_group.get("faction_name", "UNKNOWN")
		var tasks = faction_group.get("tasks", [])
		
		if tasks.is_empty():
			continue
			
		# Add faction header
		var header = Label.new()
		header.text = faction_name
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		# Add some styling to the header
		header.add_theme_color_override("font_color", Color(0.8, 0.8, 0.2)) # Yellowish for faction headers
		tasks_container.add_child(header)
		
		for task_data in tasks:
			var task_item = TaskListItemScene.instantiate()
			tasks_container.add_child(task_item)
			if task_item.has_method("update_task"):
				task_item.update_task(task_data)
				task_item.hovered.connect(func(data): task_hovered.emit(data))
				task_item.unhovered.connect(func(): task_unhovered.emit())
				if task_item.has_signal("completion_requested"):
					task_item.completion_requested.connect(func(id): task_completion_requested.emit(id))

class_name TaskDetailsPanel
extends CustomResizablePanel

@onready var _task_name_label: Label = %TaskNameLabel
@onready var _task_description_label: Label = %TaskDescriptionLabel
@onready var _task_status_label: Label = %TaskStatusLabel

func setup(_state: GameState, _config: GameSessionBuilder.Config) -> void:
	pass # No specific setup for now

func update_details(task_data) -> void:
	if not is_node_ready():
		return
	if task_data == null or (task_data is Dictionary and task_data.is_empty()):
		hide()
		return

	show()
	var title = task_data.get("title", "Task")
	_task_name_label.text = "Task Name: " + title
	var description_text = task_data.get("description", "N/A")
	if String(description_text).is_empty():
		description_text = "N/A"
	_task_description_label.text = "Task Description: " + description_text

	var is_completed = bool(task_data.get("completed", false))
	var current = int(task_data.get("current", 0))
	var max_val = int(task_data.get("required", 0))
	var progress_text = ""
	if max_val > 0:
		progress_text = " (%d/%d)" % [current, max_val]

	_task_status_label.text = "Status: " + ("Completed" if is_completed else "In Progress") + progress_text
	force_fit_content()

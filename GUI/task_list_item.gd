class_name TaskListItem
extends PanelContainer

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var progress_bar: ProgressBar = $MarginContainer/VBoxContainer/ProgressBar
@onready var progress_label: Label = $MarginContainer/VBoxContainer/ProgressBar/ProgressLabel

func update_task(task_data: Dictionary) -> void:
	title_label.text = task_data.get("title", "Unknown Task")

	var current = task_data.get("current", 0)
	var required = task_data.get("required", 0)

	if required > 0:
		progress_bar.max_value = required
		progress_bar.value = current
		progress_label.text = "%d / %d" % [current, required]
		progress_bar.visible = true
	else:
		progress_bar.visible = false

	if task_data.get("completed", false):
		title_label.modulate = Color(0.5, 0.5, 0.5) # Grey out completed tasks
		if required > 0:
			progress_bar.value = progress_bar.max_value
	else:
		title_label.modulate = Color(1, 1, 1)
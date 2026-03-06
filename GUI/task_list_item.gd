class_name TaskListItem
extends PanelContainer

const LocalizationStrings := preload(FilePaths.Resources.LOCALIZATION_STRINGS)

signal hovered(task_data: Dictionary)
signal unhovered()

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var progress_bar: ProgressBar = $MarginContainer/VBoxContainer/ProgressBar
@onready var progress_label: Label = $MarginContainer/VBoxContainer/ProgressBar/ProgressLabel

var _task_data: Dictionary = {}

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	hovered.emit(_task_data)

func _on_mouse_exited() -> void:
	unhovered.emit()

func update_task(task_data: Dictionary) -> void:
	_task_data = task_data
	title_label.text = task_data.get("title", LocalizationStrings.get_text(LocalizationStrings.HUD_TASK_UNKNOWN))

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
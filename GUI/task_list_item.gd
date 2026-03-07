class_name TaskListItem
extends PanelContainer

const LocalizationStrings := preload(FilePaths.Resources.LOCALIZATION_STRINGS)

signal hovered(task_data: Dictionary)
signal unhovered()
signal completion_requested(task_id: String)

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var progress_bar: ProgressBar = $MarginContainer/VBoxContainer/ProgressBar
@onready var progress_label: Label = $MarginContainer/VBoxContainer/ProgressBar/ProgressLabel

var _task_data: Dictionary = {}
var _debug_button: Button

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_setup_debug_button()

func _setup_debug_button() -> void:
	if not OS.is_debug_build():
		return
		
	_debug_button = Button.new()
	_debug_button.text = "DEBUG: Complete"
	_debug_button.custom_minimum_size = Vector2(100, 24)
	_debug_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_debug_button.focus_mode = Control.FOCUS_NONE
	_debug_button.pressed.connect(_on_debug_button_pressed)
	
	$MarginContainer/VBoxContainer.add_child(_debug_button)

func _on_debug_button_pressed() -> void:
	var task_id = _task_data.get("id", "")
	if not task_id.is_empty():
		completion_requested.emit(task_id)

func _on_mouse_entered() -> void:
	hovered.emit(_task_data)

func _on_mouse_exited() -> void:
	unhovered.emit()

func update_task(task_data: Dictionary) -> void:
	_task_data = task_data
	var title = tr(task_data.get("title", LocalizationStrings.get_text(LocalizationStrings.HUD_TASK_UNKNOWN)))
	var desc = tr(task_data.get("description", ""))
	
	title_label.text = title
	tooltip_text = desc

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
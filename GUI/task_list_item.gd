class_name TaskListItem
extends PanelContainer

const LocalizationStrings := preload(FilePaths.Resources.LOCALIZATION_STRINGS)

signal hovered(task_data: Dictionary)
signal unhovered()
signal completion_requested(task_id: String)
signal selected(task_data: Dictionary)

@onready var title_row: HBoxContainer = $MarginContainer/VBoxContainer/TitleRow
@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleRow/TitleLabel
@onready var progress_bar: ProgressBar = $MarginContainer/VBoxContainer/ProgressBar
@onready var progress_label: Label = $MarginContainer/VBoxContainer/ProgressBar/ProgressLabel

var _task_data: Dictionary = {}
var _debug_button: Button

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_setup_debug_button()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected.emit(_task_data)

func _setup_debug_button() -> void:
	if not OS.is_debug_build():
		return
		
	_debug_button = Button.new()
	_debug_button.text = LocalizationStrings.get_text(LocalizationStrings.HUD_DEBUG_COMPLETE)
	_debug_button.custom_minimum_size = Vector2(80, 24)
	_debug_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_debug_button.focus_mode = Control.FOCUS_NONE
	_debug_button.pressed.connect(_on_debug_button_pressed)
	
	title_row.add_child(_debug_button)

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
	
	var current: float = float(task_data.get("current", 0.0))
	var required: float = float(task_data.get("required", 0.0))
	var status: String = str(task_data.get("status", ""))
	var is_completed: bool = task_data.get("completed", false) or status == "COMPLETED"

	if required > 0:
		GameLogger.debug(GameLogger.Category.UI, "Updating task progress: %s (%f/%f)" % [task_data.get("title", "Unknown"), current, required])
		progress_bar.max_value = required
		progress_bar.value = current
		progress_label.text = LocalizationStrings.get_text("hud.task.progress").format({
			"current": int(current),
			"required": int(required)
		})
		progress_bar.visible = true
	else:
		progress_bar.visible = false

	var title: String = tr(task_data.get("title", LocalizationStrings.get_text(LocalizationStrings.HUD_TASK_UNKNOWN)))
	var desc: String = tr(task_data.get("description", ""))
	
	title_label.text = title
	tooltip_text = desc
	
	if _debug_button:
		_debug_button.text = LocalizationStrings.get_text(LocalizationStrings.HUD_DEBUG_COMPLETE)
	
	if is_completed:
		title_label.modulate = GameColors.TASK_COMPLETED_TEXT # Grey out completed tasks
		if required > 0:
			progress_bar.value = progress_bar.max_value
	else:
		title_label.modulate = GameColors.WHITE

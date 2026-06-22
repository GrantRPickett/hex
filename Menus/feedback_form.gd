extends CanvasLayer

signal close_requested

@onready var _title_label: Label = $Control/Panel/VBox/Title
@onready var _text_edit: TextEdit = $Control/Panel/VBox/TextEdit
@onready var _submit_button: Button = $Control/Panel/VBox/HBox/Submit
@onready var _cancel_button: Button = $Control/Panel/VBox/HBox/Cancel
@onready var _status_label: Label = $Control/Panel/VBox/Status

func _ready() -> void:
	_translate_ui()
	_submit_button.pressed.connect(_on_submit_pressed)
	_cancel_button.pressed.connect(_on_cancel_pressed)
	_status_label.text = ""
	_text_edit.grab_focus()

func _translate_ui() -> void:
	_title_label.text = tr("menu.feedback.title")
	_submit_button.text = tr("menu.feedback.submit")
	_cancel_button.text = tr("menu.feedback.cancel")
	_text_edit.placeholder_text = tr("menu.feedback.placeholder")

func _on_submit_pressed() -> void:
	var feedback_text = _text_edit.text.strip_edges()
	if feedback_text.is_empty():
		return

	# ANALYTICS CAPTURE (Placeholder for actual transmission)
	var analytics_data := {
		"feedback": feedback_text,
		"timestamp": Time.get_datetime_dict_from_system(),
		"os": OS.get_name(),
		"version": "v0.1.0-alpha", # Hardcoded or from config
		"save_analytics": _get_save_analytics()
	}

	GameLogger.info(GameLogger.Category.UI, "[FeedbackForm] Feedback submitted: ", analytics_data)

	_status_label.text = tr("menu.feedback.success")
	_submit_button.disabled = true
	_text_edit.editable = false

	await get_tree().create_timer(1.5).timeout
	close_requested.emit()

func _get_save_analytics() -> Dictionary:
	if not is_instance_valid(SaveManager):
		return {}
	
	# Extract history and current state summary without sending full binary data
	var completion_history = SaveManager.get_value(GameConstants.Save.KEY_COMPLETION_HISTORY, [])
	var last_completed = SaveManager.get_value("last_completed_level_id", "None")

	return {
		"completion_count": completion_history.size(),
		"completion_order": completion_history.map(func(entry): return entry.get("level_id", "unknown")),
		"last_completed": last_completed
	}

func _on_cancel_pressed() -> void:
	close_requested.emit()

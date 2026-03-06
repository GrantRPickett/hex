class_name TaskDisplayItem
extends HBoxContainer

const LocalizationStrings := preload(FilePaths.Resources.LOCALIZATION_STRINGS)


var _name_label: Label
var _status_label: Label

func _ready() -> void:
	_name_label = get_node("NameLabel")
	_status_label = get_node("StatusLabel")

func set_task_data(task_data: Dictionary) -> void:
	if not is_instance_valid(_name_label) or not is_instance_valid(_status_label):
		push_error("Labels not initialized in TaskDisplayItem when trying to set data.")
		return

	_name_label.text = task_data.get("title", LocalizationStrings.get_text(LocalizationStrings.HUD_TASK_UNKNOWN))

	var status_text = LocalizationStrings.get_text(LocalizationStrings.HUD_TASK_COMPLETED) if task_data.get("completed", false) else LocalizationStrings.get_text(LocalizationStrings.HUD_TASK_IN_PROGRESS)
	_status_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_TASK_STATUS_LABEL).format({"status": status_text})

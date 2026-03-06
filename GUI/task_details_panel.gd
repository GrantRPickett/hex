class_name TaskDetailsPanel
extends CustomResizablePanel

const LocalizationStrings := preload(FilePaths.Resources.LOCALIZATION_STRINGS)


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
	var title = task_data.get("title", LocalizationStrings.get_text(LocalizationStrings.HUD_TASK_UNKNOWN))
	_task_name_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_TASK_NAME_LABEL).format({"title": title})
	var description_text = task_data.get("description", LocalizationStrings.get_text(LocalizationStrings.HUD_TARGET_NA))
	if String(description_text).is_empty():
		description_text = LocalizationStrings.get_text(LocalizationStrings.HUD_TARGET_NA)
	_task_description_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_TASK_DESCRIPTION_LABEL).format({"description": description_text})


	var is_completed = bool(task_data.get("completed", false))
	var current = int(task_data.get("current", 0))
	var max_val = int(task_data.get("required", 0))
	var progress_text = ""
	if max_val > 0:
		progress_text = " (%d/%d)" % [current, max_val]

	var status_word = LocalizationStrings.get_text(LocalizationStrings.HUD_TASK_COMPLETED) if is_completed else LocalizationStrings.get_text(LocalizationStrings.HUD_TASK_IN_PROGRESS)
	_task_status_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_TASK_STATUS_LABEL).format({"status": status_word}) + progress_text
	force_fit_content()

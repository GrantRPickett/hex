class_name TaskDetailsPanel
extends CustomResizablePanel

@onready var _task_name_label: Label = %TaskNameLabel
@onready var _task_description_label: Label = %TaskDescriptionLabel
@onready var _task_status_label: Label = %TaskStatusLabel

var _location_manager: LocationManager

func setup(_unit_manager, _turn_controller, _input_controller, location_manager: LocationManager) -> void:
	_location_manager = location_manager

func update_details(location_data) -> void:
	if not is_node_ready():
		return
	if location_data == null:
		hide()
		return

	var payload: Dictionary = {}
	if location_data is Dictionary:
		payload = location_data
	elif location_data is TargetTask and _location_manager:
		var task_idx = _location_manager.get_target_task_node_index(location_data)
		if task_idx != -1:
			payload = _location_manager.get_task_info(task_idx)
		if not payload.has("title"):
			payload["title"] = location_data.name
		if not payload.has("description"):
			payload["description"] = location_data.definition.steps[0].description if location_data.definition and not location_data.definition.steps.is_empty() else ""
	if payload.is_empty():
		hide()
		return

	show()
	var title = payload.get("title", "Task")
	_location_name_label.text = "Task Name: " + title
	var description_text = payload.get("description", "N/A")
	if String(description_text).is_empty():
		description_text = "N/A"
	_location_description_label.text = "Task Description: " + description_text

	var is_completed = bool(payload.get("completed", false))
	var current = int(payload.get("player_progress", 0))
	var max_val = int(payload.get("required_amount", 0))
	var progress_text = ""
	if max_val > 0:
		progress_text = " (%d/%d)" % [current, max_val]

	_location_status_label.text = "Status: " + ("Completed" if is_completed else "In Progress") + progress_text
	force_fit_content()

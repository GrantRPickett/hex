class_name GoalDetailsPanel
extends CustomResizablePanel

@onready var _goal_name_label: Label = %GoalNameLabel
@onready var _goal_description_label: Label = %GoalDescriptionLabel
@onready var _goal_status_label: Label = %GoalStatusLabel

var _goal_manager: GoalManager

func setup(_unit_manager, _turn_controller, _input_controller, goal_manager: GoalManager) -> void:
	_goal_manager = goal_manager

func update_details(goal_data) -> void:
	if not is_node_ready():
		return
	if goal_data == null:
		hide()
		return

	var payload: Dictionary = {}
	if goal_data is Dictionary:
		payload = goal_data
	elif goal_data is Goal and _goal_manager:
		var goal_idx = _goal_manager.get_goal_node_index(goal_data)
		if goal_idx != -1:
			payload = _goal_manager.get_goal_info(goal_idx)
		if not payload.has("title"):
			payload["title"] = goal_data.name
		if not payload.has("description"):
			payload["description"] = goal_data.definition.steps[0].description if goal_data.definition and not goal_data.definition.steps.is_empty() else ""
	if payload.is_empty():
		hide()
		return

	show()
	var title = payload.get("title", "Goal")
	_goal_name_label.text = "Goal Name: " + title
	var description_text = payload.get("description", "N/A")
	if String(description_text).is_empty():
		description_text = "N/A"
	_goal_description_label.text = "Goal Description: " + description_text

	var is_completed = bool(payload.get("completed", false))
	var current = int(payload.get("player_progress", 0))
	var max_val = int(payload.get("required_amount", 0))
	var progress_text = ""
	if max_val > 0:
		progress_text = " (%d/%d)" % [current, max_val]

	_goal_status_label.text = "Status: " + ("Completed" if is_completed else "In Progress") + progress_text
	force_fit_content()

# GoalDisplayItem.gd
extends HBoxContainer

var _type_label: Label
var _progress_label: Label

func _ready() -> void:
	_type_label = get_node("TypeLabel")
	_progress_label = get_node("ProgressLabel")

func set_goal_data(goal_data: Dictionary) -> void:
	if not goal_data.has_all(["type", "player_progress", "max"]):
		push_error("Invalid goal_data provided to GoalDisplayItem.")
		return

	if _type_label and _progress_label: # Ensure labels are initialized
		_type_label.text = goal_data.type
		_progress_label.text = "%d/%d" % [goal_data.player_progress, goal_data.max]
	else:
		push_error("Labels not initialized in GoalDisplayItem when trying to set data.")

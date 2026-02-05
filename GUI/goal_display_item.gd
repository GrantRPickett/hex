# GoalDisplayItem.gd
extends HBoxContainer

var _type_label: Label
var _progress_label: Label

func _ready() -> void:
	_type_label = get_node("TypeLabel")
	_progress_label = get_node("ProgressLabel")

func set_goal_data(goal_data: Dictionary) -> void:
	var required_keys = ["type", "player_progress", "enemy_progress", "neutral_progress", "max"]
	if not goal_data.has_all(required_keys):
		push_error("Invalid goal_data provided to GoalDisplayItem.")
		return

	if _type_label and _progress_label:
		_type_label.text = goal_data.type
		_progress_label.text = "P:%d/%d  E:%d  N:%d" % [
			goal_data.player_progress,
			goal_data.max,
			goal_data.enemy_progress,
			goal_data.neutral_progress
		]
	else:
		push_error("Labels not initialized in GoalDisplayItem when trying to set data.")

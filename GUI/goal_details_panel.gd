class_name GoalDetailsPanel
extends ResizablePanel

@onready var _goal_name_label: Label = %GoalNameLabel
@onready var _goal_description_label: Label = %GoalDescriptionLabel
@onready var _goal_status_label: Label = %GoalStatusLabel

func update_details(goal: Goal) -> void:
	if goal == null:
		hide()
		return

	show()
	_goal_name_label.text = "Goal Name: " + goal.name
	_goal_description_label.text = "Goal Description: " + goal.description
	_goal_status_label.text = "Status: " + ("Completed" if goal.is_completed else "In Progress")
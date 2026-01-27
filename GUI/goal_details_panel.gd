class_name GoalDetailsPanel
extends CustomResizablePanel

@onready var _goal_name_label: Label = %GoalNameLabel
@onready var _goal_description_label: Label = %GoalDescriptionLabel
@onready var _goal_status_label: Label = %GoalStatusLabel

var _goal_manager: GoalManager

func setup(_unit_manager, _turn_controller, _input_controller, goal_manager: GoalManager) -> void:
	_goal_manager = goal_manager

func update_details(goal: Goal) -> void:
	if goal == null:
		hide()
		return

	show()
	_goal_name_label.text = "Goal Name: " + goal.name
	var description_text = "N/A"
	if goal.definition and not goal.definition.steps.is_empty():
		description_text = goal.definition.steps[0].description
	_goal_description_label.text = "Goal Description: " + description_text

	var is_completed = false
	if _goal_manager and goal:
		is_completed = _goal_manager.is_goal_completed(goal)

	_goal_status_label.text = "Status: " + ("Completed" if is_completed else "In Progress")

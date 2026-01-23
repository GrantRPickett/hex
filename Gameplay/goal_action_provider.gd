class_name GoalActionProvider
extends RefCounted

func append_goal_action(actions: Array[Dictionary], unit: Unit, action_origin: Vector2i) -> void:
	var goal := _find_goal_at_position(unit, action_origin)
	_add_goal_action(actions, goal)

func _find_goal_at_position(unit: Unit, action_origin: Vector2i) -> Node:
	var goal_manager = unit.get_goal_manager()
	if not goal_manager:
		return null
	var goal = goal_manager.get_goal_at_cell(action_origin)
	if goal != null and goal.can_be_worked_on_by(unit):
		return goal
	return null

func _add_goal_action(actions: Array[Dictionary], goal: Node) -> void:
	if goal:
		actions.append({
			"type": "work_on_goal",
			"label": "Work on Goal",
			"available": true,
			"target": goal
		})

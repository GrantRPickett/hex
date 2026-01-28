class_name GoalActionProvider
extends RefCounted

func append_goal_action(actions: Array[Dictionary], unit: Unit, action_origin: Vector2i) -> void:
	var goal := _find_goal_at_position(unit, action_origin)
	_add_goal_action(actions, goal, unit)

func _find_goal_at_position(unit: Unit, action_origin: Vector2i) -> Node:
	var goal_manager = unit.get_goal_manager()
	if not goal_manager:
		return null
	var goal = goal_manager.get_goal_at_cell(action_origin)
	if goal != null and goal.can_be_worked_on_by(unit):
		return goal
	return null

func _add_goal_action(actions: Array[Dictionary], goal: Node, unit: Unit = null) -> void:
	if not goal:
		return

	var label = "Work on Goal"
	var hint = ""

	if unit:
		var goal_manager = unit.get_goal_manager()
		if goal_manager:
			var goal_index = goal_manager.get_goal_node_index(goal)
			if goal_index != -1:
				var attr_type = goal_manager.get_required_type(goal_index, unit.faction)
				if not attr_type.is_empty():
					var attrs = unit.get_attributes()
					var val = 0
					if attrs:
						val = attrs.get_attribute(attr_type)

					# Ensure a minimum of 1 contribution
					if val <= 0: val = 1

					label = "Use %s (%d)" % [attr_type.capitalize(), val]
					hint = "Contributes %d points to %s requirement" % [val, attr_type]

	actions.append({
		"type": "work_on_goal",
		"label": label,
		"available": true,
		"target": goal,
		"hint": hint
	})

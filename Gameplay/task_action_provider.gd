class_name TaskActionProvider
extends RefCounted

func append_task_action(actions: Array[Dictionary], unit: Unit, action_origin: Vector2i) -> void:
	var task := _find_task_at_position(unit, action_origin)
	_add_task_action(actions, task, unit)

func _find_task_at_position(unit: Unit, action_origin: Vector2i) -> TargetTask:
	var task_manager = unit.get_task_manager()
	if not task_manager:
		return null
	var task := task_manager.get_target_task_at_cell(action_origin)
	if task != null and task.can_be_worked_on_by(unit):
		return task
	return null

func _add_task_action(actions: Array[Dictionary], task: TargetTask, unit: Unit = null) -> void:
	if not task:
		return

	var label = "Work on Task"
	var hint = ""

	if unit:
		var task_manager = unit.get_task_manager()
		if task_manager:
			var task_index = task_manager.get_target_task_node_index(task)
			if task_index != -1:
				var attr_type = task_manager.get_required_type(task_index, unit.faction)
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
		"type": "work_on_task",
		"label": label,
		"available": true,
		"target": task,
		"hint": hint
	})

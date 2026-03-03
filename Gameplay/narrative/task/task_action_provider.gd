class_name TaskActionProvider
extends RefCounted

func append_task_action(actions: Array[Dictionary], unit: Unit, action_origin: Vector2i) -> void:
	var task_manager = unit.get_task_manager()
	if not task_manager:
		return

	var objective = task_manager.get_active_objective()
	if not objective or not objective.is_active or not objective.current_stage:
		return

	var loc = task_manager.get_location_at(action_origin)
	if not loc:
		return

	for task in objective.current_stage.active_tasks:
		if task.event_type == "interact" or task.event_type == "explore":
			if task.target_coord != Vector2i(-999, -999) and task.target_coord != action_origin:
				continue
			if not task.target_id.is_empty() and task.target_id != loc.loc_name:
				continue
			_add_task_action(actions, task, loc, unit)

func _add_task_action(actions: Array[Dictionary], task: Task, location: Location, unit: Unit = null) -> void:
	if not unit:
		return

	var attrs = unit.inv.get_attributes() if "inv" in unit and unit.inv else null
	for attr_name in Target.COMBAT_ATTRIBUTE_NAMES:
		var val = 1
		if attrs:
			val = attrs.get_attribute(attr_name)
		if val <= 0: val = 1

		var label = "%s: Use %s (%d)" % [task.title, attr_name.capitalize(), val]
		var hint = "Contributes towards task using %s" % attr_name

		actions.append({
			"type": "work_on_task",
			"label": label,
			"available": true,
			"interact_target_coord": location.coord,
			"task_id": String(task.id),
			"attribute": attr_name,
			"hint": hint
		})

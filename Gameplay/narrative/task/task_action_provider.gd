class_name TaskActionProvider
extends RefCounted

const TaskDiscovery = preload("res://Gameplay/targets/discovery/task_discovery.gd")

func append_task_action(actions: Array[Dictionary], unit: Unit, action_origin: Vector2i) -> void:
	var task_manager = unit.get_task_manager()
	if not task_manager:
		return

	var immediate_tasks = TaskDiscovery.get_immediate_tasks(unit, action_origin, task_manager)
	for task in immediate_tasks:
		_add_task_action(actions, task, action_origin, unit)

func _add_task_action(actions: Array[Dictionary], task: Task, action_origin: Vector2i, unit: Unit = null) -> void:
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
			"interact_target_coord": action_origin,
			"task_id": String(task.id),
			"attribute": attr_name,
			"hint": hint
		})

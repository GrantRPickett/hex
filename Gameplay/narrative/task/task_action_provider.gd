class_name TaskActionProvider
extends RefCounted

const _TaskDiscovery = preload("res://Gameplay/targets/discovery/task_discovery.gd")

func append_task_action(actions: Array[UnitAction], unit: Unit, action_origin: Vector2i) -> void:
	var task_manager: TaskManager = unit.get_task_manager()
	if not task_manager:
		return

	var immediate_tasks: Array = _TaskDiscovery.get_immediate_tasks(unit, action_origin, task_manager)
	for task in immediate_tasks:
		# Specialized action providers (LocationActionProvider, LootActionProvider)
		# handle their targets with direct labels.
		if task.target_kind == &"location" or task.target_kind == &"item":
			continue
		_add_task_action(actions, task, action_origin, unit)

func _add_task_action(actions: Array[UnitAction], task: Task, action_origin: Vector2i, unit: Unit = null) -> void:
	if not unit:
		return

	var action = UnitAction.create(UnitAction.Type.EXPLORE, GameConstants.ActionIds.LOCATION_OPPOSED)
	action.label_params = {"task": task.title}
	action.interact_target_coord = action_origin
	action.task_id = String(task.id)
	action.needs_attribute = true
	actions.append(action)

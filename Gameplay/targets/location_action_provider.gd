class_name LocationActionProvider
extends RefCounted

const _TaskDiscovery = preload("res://Gameplay/targets/discovery/task_discovery.gd")

func append_location_action(actions: Array[UnitAction], unit: Unit, action_origin: Vector2i, reachable_coords: Array[Vector2i], reachable_lookup: Dictionary) -> void:
	var task_manager = unit.get_task_manager()
	if not task_manager:
		return

	var active_tasks = _TaskDiscovery.get_active_tasks(task_manager)

	var immediate_explore: Array[Task] = []
	var immediate_visit: Array[Task] = []
	var reachable_explore: Array[Task] = []
	var reachable_visit: Array[Task] = []

	for task in active_tasks:
	# Only handle tasks targeted at locations
		if task.target_kind != GameConstants.Tasks.KIND_LOCATION:
			continue

		var target_coord = task.target_coord
		if target_coord == GameConstants.INVALID_COORD:
			continue

		# Verify there is actually a location here
		var loc = task_manager.get_location_at(target_coord)
		if loc == null:
			continue

		var is_opposed = (task.event_type == GameConstants.TaskEvents.EXPLORE or task.event_type == GameConstants.TaskEvents.INTERACT or task.is_opposed)

		if target_coord == action_origin:
			if is_opposed:
				immediate_explore.append(task)
			else:
				immediate_visit.append(task)
		elif reachable_lookup.has(target_coord):
			if is_opposed:
				reachable_explore.append(task)
			else:
				reachable_visit.append(task)

	_add_task_summary_action(actions, task_manager, immediate_explore, reachable_explore, reachable_lookup, UnitAction.Type.EXPLORE, GameConstants.ActionIds.LOCATION_OPPOSED)
	_add_task_summary_action(actions, task_manager, immediate_visit, reachable_visit, reachable_lookup, UnitAction.Type.VISIT, GameConstants.ActionIds.LOCATION_UNOPPOSED)

func _add_task_summary_action(actions: Array[UnitAction], task_manager: TaskManager, immediate: Array[Task], reachable: Array[Task], reachable_lookup: Dictionary, action_type: UnitAction.Type, action_id: String) -> void:
	var imm_count = immediate.size()
	var reach_count = reachable.size()

	if imm_count > 0 or reach_count > 0:
		var action = UnitAction.create(action_type, action_id)
		action.label_params = {"near": imm_count, "far": reach_count, "imm_label": "near"}
		action.available = imm_count > 0 or reach_count > 0
		action.needs_attribute = true # Both Visit and Explore need targets/submenus

		var all_targets: Array[Target] = []
		var target_to_task: Dictionary = {}
		for task in immediate:
			var loc = task_manager.get_location_at(task.target_coord)
			if loc:
				all_targets.append(loc)
				target_to_task[loc] = task.id

		var reachable_targets: Array[Target] = []
		for task in reachable:
			var loc = task_manager.get_location_at(task.target_coord)
			if loc:
				all_targets.append(loc)
				reachable_targets.append(loc)
				target_to_task[loc] = task.id

		if not all_targets.is_empty():
			action.targets = all_targets
			action.target = all_targets[0]
			action.reachable_targets = reachable_targets
			action.target_move_data = reachable_lookup
			action.target_to_task = target_to_task

		actions.append(action)

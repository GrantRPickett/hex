class_name HUDTaskPresenter
extends RefCounted

## Presenter for transforming Narrative/Task data into UI-friendly structures.
## Extracted from HUDController to reduce complexity.

static func transform_objective_to_data(objective: Objective, task_manager: TaskManager) -> Array:
	if not task_manager: return []
	
	var backend_data = task_manager.get_processed_tasks_data()
	var grouped_data: Array = []

	for item in backend_data:
		var faction = item.faction
		var raw_tasks = item.tasks
		var faction_tasks = []
		
		for task in raw_tasks:
			var item_data: Dictionary
			if task is Dictionary:
				item_data = task
			else:
				var stage_id = ""
				if objective and objective.current_stage:
					stage_id = objective.current_stage.id
				item_data = _transform_task(task, stage_id, task_manager)
			faction_tasks.append(item_data)

		var faction_name: String = TranslationServer.translate("hud.faction_player_upper")
		if faction == GameConstants.Faction.ENEMY: faction_name = TranslationServer.translate("hud.faction_enemy_upper")
		elif faction == GameConstants.Faction.NEUTRAL: faction_name = TranslationServer.translate("hud.faction_neutral_upper")

		grouped_data.append({
			"faction": faction,
			"faction_name": faction_name,
			"tasks": faction_tasks
		})

	return grouped_data

static func _transform_task(task: Task, stage_id: String, task_manager: TaskManager = null) -> Dictionary:
	var status_str: String = TranslationServer.translate("hud.task.status_unknown")
	if task.status >= 0 and task.status < Task.Status.size():
		status_str = Task.Status.keys()[task.status]
		if status_str == "ACTIVE": status_str = TranslationServer.translate("hud.task.status_active")
		elif status_str == "COMPLETED": status_str = TranslationServer.translate("hud.task.completed")
		elif status_str == "IN_PROGRESS": status_str = TranslationServer.translate("hud.task.in_progress")

	var current = task.current_effort
	var required = task.effort_required

	if task.duration_turns > 0:
		current = task.elapsed_turns
		required = task.duration_turns
	
	# Priority: Use task's own effort tracking if it's active (e.g. convince tasks)
	# Otherwise, fallback to target's willpower for world-driven tasks.
	if task.has_effort_tracking:
		required = task.effort_required
		current = task.current_effort
	elif task_manager and not task.target_id.is_empty():
		var target = task_manager.get_target_by_id(task.target_id)
		if target and target.has_method("get_max_willpower") and target.has_method("get_current_willpower"):
			var max_wp = target.get_max_willpower()
			required = max_wp
			if task.event_type == GameConstants.Activity.CONVINCE:
				required = max_wp >> 1 # Half willpower for convince
			current = max(0, max_wp - target.get_current_willpower())

	return {
		"id": task.id,
		"title": task.title,
		"description": task.description,
		"event_type": task.event_type,
		"target_coord": task.target_coord,
		"target_id": task.target_id,
		"effort_required": task.effort_required,
		"is_optional": task.is_optional,
		"is_opposed": task.is_opposed,
		"journal_entry_id": task.journal_entry_id,
		"reward_id": task.reward_id,
		"dialogue_id": task.dialogue_id,
		"zone_coords": task.zone_coords,
		"current": current,
		"required": required,
		"completed": task.status == Task.Status.COMPLETED,
		"icon": task.icon,
		"stage_id": stage_id,
		"status": status_str,
		"duration_turns": task.duration_turns
	}

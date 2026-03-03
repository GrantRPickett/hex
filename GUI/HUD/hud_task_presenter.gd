class_name HUDTaskPresenter
extends RefCounted

## Presenter for transforming Narrative/Task data into UI-friendly structures.
## Extracted from HUDController to reduce complexity.

static func transform_objective_to_data(objective: Objective) -> Array:
	var tasks_data: Array = []
	if not objective or not objective.is_active or not objective.current_stage:
		return tasks_data

	var stage = objective.current_stage
	for task in stage.active_tasks:
		var status_str = "UNKNOWN"
		if task.status >= 0 and task.status < Task.Status.size():
			status_str = Task.Status.keys()[task.status]

		tasks_data.append({
			"id": task.id,
			"title": task.title,
			"description": task.description,
			"event_type": task.event_type,
			"target_coord": task.target_coord,
			"target_id": task.target_id,
			"effort_required": task.effort_required,
			"is_optional": task.is_optional,
			"is_opposed": task.is_opposed,
			"opposition_value": task.opposition_value,
			"journal_entry_id": task.journal_entry_id,
			"reward_id": task.reward_id,
			"dialogue_id": task.dialogue_id,
			"zone_coords": task.zone_coords,
			"current": task.current_effort,
			"required": task.effort_required,
			"completed": task.status == Task.Status.COMPLETED,
			"icon": task.icon,
			"stage_id": stage.id,
			"status": status_str
		})
	return tasks_data

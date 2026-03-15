class_name HUDTaskPresenter
extends RefCounted

## Presenter for transforming Narrative/Task data into UI-friendly structures.
## Extracted from HUDController to reduce complexity.

static func transform_objective_to_data(objective: Objective, unit_manager: UnitManager = null) -> Array:
	var grouped_data: Array = []
	if not objective or not objective.is_active or not objective.current_stage:
		return grouped_data

	var stage = objective.current_stage
	var factions = [Unit.Faction.PLAYER, Unit.Faction.ENEMY, Unit.Faction.NEUTRAL]
	
	for faction in factions:
		var faction_tasks: Array = []
		
		# 1. Get explicit tasks for this faction from the stage
		for task in stage.active_tasks:
			if task.owning_faction == faction:
				faction_tasks.append(_transform_task(task, stage.id))
		
		# 2. Add default task if no tasks but has units
		if faction_tasks.is_empty() and unit_manager:
			var units: Array = unit_manager.get_units_by_faction(faction)
			if not units.is_empty():
				if faction == Unit.Faction.ENEMY or faction == Unit.Faction.NEUTRAL:
					var player_units: Array = unit_manager.get_player_units()
					var total_player_count: int = player_units.size()
					var alive_player_count: int = 0
					for u in player_units:
						if is_instance_valid(u) and u.willpower > 0:
							alive_player_count += 1
					
					var defeated_player_count = total_player_count - alive_player_count
					
					faction_tasks.append({
						"id": "default_eliminate_" + str(faction),
						"title": TranslationServer.translate("hud.task.default_eliminate_title"),
						"description": TranslationServer.translate("hud.task.default_eliminate_desc"),
						"status": TranslationServer.translate("hud.task.status_active"),
						"completed": false,
						"current": defeated_player_count,
						"required": total_player_count,
						"icon": null
					})
		
		if not faction_tasks.is_empty():
			var faction_name: String = TranslationServer.translate("hud.faction_player_upper")
			if faction == Unit.Faction.ENEMY: faction_name = TranslationServer.translate("hud.faction_enemy_upper")
			elif faction == Unit.Faction.NEUTRAL: faction_name = TranslationServer.translate("hud.faction_neutral_upper")
			
			grouped_data.append({
				"faction": faction,
				"faction_name": faction_name,
				"tasks": faction_tasks
			})
			
	return grouped_data

static func _transform_task(task: Task, stage_id: String) -> Dictionary:
	var status_str: String = TranslationServer.translate("hud.task.status_unknown")
	if task.status >= 0 and task.status < Task.Status.size():
		status_str = Task.Status.keys()[task.status]
		if status_str == "ACTIVE": status_str = TranslationServer.translate("hud.task.status_active")
		elif status_str == "COMPLETED": status_str = TranslationServer.translate("hud.task.completed")
		elif status_str == "IN_PROGRESS": status_str = TranslationServer.translate("hud.task.in_progress")

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
		"opposition_value": task.opposition_value,
		"journal_entry_id": task.journal_entry_id,
		"reward_id": task.reward_id,
		"dialogue_id": task.dialogue_id,
		"zone_coords": task.zone_coords,
		"current": task.current_effort,
		"required": task.effort_required,
		"completed": task.status == Task.Status.COMPLETED,
		"icon": task.icon,
		"stage_id": stage_id,
		"status": status_str
	}

extends RefCounted
class_name TaskRepairer

func repair(level: Level, report: Dictionary, _context: Dictionary, options: LevelAutoFixOptions) -> void:
	if not options.log_missing_params or level.objective == null:
		return
	var level_name: String = _context["level_name"]
	for st in level.objective.stages:
		if st == null: continue
		for i in range(st.tasks.size()):
			var t: Task = st.tasks[i]
			if t == null: continue
			_repair_task_metadata(t, i, st.id, report, level_name)

func _repair_task_metadata(t: Task, index: int, stage_id: String, report: Dictionary, level_name: String) -> void:
	if String(t.id).is_empty():
		var new_id = "task_%s_%d" % [stage_id, index]
		t.id = StringName(new_id)
		report["applied"].append({
			"type": "task_metadata",
			"level_id": level_name,
			"field": "id",
			"to": new_id,
			"reason": "missing task id"
		})
		report["messages"].append("[LevelAutoFix] Missing ID for task #%d in stage %s repaired to '%s'." % [index, stage_id, new_id])
	if t.title.is_empty():
		var new_title = "Task %d" % index
		t.title = new_title
		report["applied"].append({
			"type": "task_metadata",
			"level_id": level_name,
			"field": "title",
			"to": new_title,
			"reason": "missing task title"
		})
		report["messages"].append("[LevelAutoFix] Missing title for task %s repaired to '%s'." % [t.id, new_title])
	if t.event_type.is_empty():
		var new_type = "interact"
		t.event_type = new_type
		report["applied"].append({
			"type": "task_metadata",
			"level_id": level_name,
			"field": "event_type",
			"to": new_type,
			"reason": "missing event type"
		})
		report["messages"].append("[LevelAutoFix] Missing event_type for task %s repaired to '%s'." % [t.id, new_type])

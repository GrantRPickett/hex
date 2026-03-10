extends RefCounted
class_name DialogueRepairer

const DIALOGUE_BLOCKED_TYPES: Array[String] = ["enemy_spawn", "player_start", "neutral_start", "location"]

func repair(_level: Level, dialogue_rows: Array, report: Dictionary, context: Dictionary, options: LevelAutoFixOptions) -> void:
	if dialogue_rows.is_empty():
		return
	var blocked_for_dialogues := DIALOGUE_BLOCKED_TYPES
	var validate_coord: Callable = context["validate_coord"] as Callable
	var reason_label_of: Callable = context["reason_label"] as Callable
	var find_replacement: Callable = context["find_replacement"] as Callable
	var level_name: String = context["level_name"]

	for row: LevelDialogueEntry in dialogue_rows:
		if row == null:
			continue
		var row_label: String = row.resource_path if not String(row.resource_path).is_empty() else "dialogue #%s" % row.entry_id
		var original: Vector2i = row.coord

		# If the dialogue does not require adjacency, it is likely triggered logically (e.g. on_enter)
		# and does not need a valid physical coordinate.
		if not row.requires_adjacent:
			continue

		var check: Dictionary = validate_coord.call(original, blocked_for_dialogues)
		var reason: String = check.reason

		if reason == "": # No fix needed, record its occupancy for subsequent checks
			if options.log_missing_params:
				_repair_dialogue_metadata(row, report, level_name)
			continue

		var replacement: Vector2i = find_replacement.call(original, blocked_for_dialogues)
		var reason_label: String = reason_label_of.call(reason)

		if replacement == Vector2i(-1, -1):
			report["failed"].append({
				"type": "dialogue",
				"row_path": row.resource_path if row else "",
				"level_id": level_name,
				"from": {"x": original.x, "y": original.y},
				"to": null,
				"reason": reason_label,
			})
			report["messages"].append("[LevelAutoFix] Unable to repair dialogue %s at (%s,%s): %s." % [row_label, original.x, original.y, reason_label])
			continue

		row.coord = replacement
		if options.log_missing_params:
			_repair_dialogue_metadata(row, report, level_name)
		report["applied"].append({
			"type": "dialogue",
			"row_path": row.resource_path if row else "",
			"level_id": level_name,
			"from": {"x": original.x, "y": original.y},
			"to": {"x": replacement.x, "y": replacement.y},
			"reason": reason_label,
		})
		report["messages"].append("[LevelAutoFix] %s moved from (%s,%s) to (%s,%s) due to %s." % [row_label, original.x, original.y, replacement.x, replacement.y, reason_label])

func _repair_dialogue_metadata(row: LevelDialogueEntry, report: Dictionary, level_name: String) -> void:
	if String(row.entry_id).is_empty():
		var new_id = "dlg_%d" % row.hash()
		row.entry_id = StringName(new_id)
		report["applied"].append({
			"type": "dialogue_metadata",
			"row_path": row.resource_path,
			"level_id": level_name,
			"field": "entry_id",
			"to": new_id,
			"reason": "missing dialogue entry id"
		})
		report["messages"].append("[LevelAutoFix] Missing entry_id for dialogue repaired to '%s'." % new_id)

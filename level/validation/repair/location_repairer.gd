extends RefCounted
class_name LocationRepairer

func repair(level: Level, _location_rows: Array, report: Dictionary, context: Dictionary, options: LevelAutoFixOptions) -> void:
	var location_entries: Array[LevelTaskEntry] = []
	if level.locations:
		location_entries.assign(level.locations)
	
	var blocked_for_locations: Array[String] = ["location", "enemy_spawn", "player_start", "neutral_start", "neutral_roster"]
	var validate_coord:  = context["validate_coord"] as Callable
	var reason_label_of:  = context["reason_label"] as Callable
	var find_replacement:  = context["find_replacement"] as Callable
	var add_occupancy := context["add_occupancy"] as Callable
	var level_name: String = context["level_name"]
	
	for i in range(location_entries.size()):
		var location_entry: LevelTaskEntry = location_entries[i]
		if location_entry == null:
			continue
		
		var row_label: String = location_entry.resource_path if not String(location_entry.resource_path).is_empty() else "location #%s" % i
		var original: Vector2i = location_entry.coord
		var check = validate_coord.call(original, blocked_for_locations)
		var reason: String = check.reason
		
		if reason == "":
			add_occupancy.call(original, "location")
			if options.log_missing_params:
				_repair_location_metadata(location_entry, i, report, level_name)
			continue
		
		var replacement: Vector2i = find_replacement.call(original, blocked_for_locations)
		var reason_label: String = reason_label_of.call(reason)
		
		if replacement == Vector2i(-1, -1):
			report["failed"].append({
				"type": "location",
				"row_path": location_entry.resource_path,
				"level_id": level_name,
				"from": {"x": original.x, "y": original.y},
				"to": null,
				"reason": reason_label,
			})
			report["messages"].append("[LevelAutoFix] Unable to repair location %s at (%s,%s): %s." % [row_label, original.x, original.y, reason_label])
			continue
		
		location_entry.coord = replacement
		add_occupancy.call(replacement, "location")
		
		if options.log_missing_params:
			_repair_location_metadata(location_entry, i, report, level_name)
			
		report["applied"].append({
			"type": "location",
			"row_path": location_entry.resource_path,
			"level_id": level_name,
			"from": {"x": original.x, "y": original.y},
			"to": {"x": replacement.x, "y": replacement.y},
			"reason": reason_label,
		})
		report["messages"].append("[LevelAutoFix] %s moved from (%s,%s) to (%s,%s) due to %s." % [row_label, original.x, original.y, replacement.x, replacement.y, reason_label])

func _repair_location_metadata(loc: LevelTaskEntry, index: int, report: Dictionary, level_name: String) -> void:
	if loc.location_name.is_empty():
		var new_name: String = "Location_%d" % index
		loc.location_name = new_name
		report["applied"].append({
			"type": "location_metadata",
			"row_path": loc.resource_path,
			"level_id": level_name,
			"field": "location_name",
			"to": new_name,
			"reason": "missing location name"
		})
		report["messages"].append("[LevelAutoFix] Missing name for location %d repaired to '%s'." % [index, new_name])

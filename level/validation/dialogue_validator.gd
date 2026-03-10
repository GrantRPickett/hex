extends RefCounted
class_name DialogueValidator

static func validate_rows(rows: Array, level_id: String, width: int, height: int) -> Array[String]:
	var errors: Array[String] = []
	for row in rows:
		if row == null:
			continue
		
		# Added check for missing dialogue resource (fixes test_dialogue_missing_timeline_reported)
		if not "dialogue_resource_path" in row or String(row.dialogue_resource_path).is_empty():
			errors.append("[LevelRows] Dialogue row %s is missing dialogue resource for %s" % [row.resource_path, level_id])

		# Allow (-999, -999) for dialogues that aren't triggers in the world
		if row.coord != Vector2i(-999, -999) and not GridService.is_in_bounds(row.coord, width, height):
			errors.append("[LevelRows] Dialogue row %s is out of bounds for %s" % [row.resource_path, level_id])
	return errors

static func validate_journal_links(dialogue_rows: Array, journal_rows: Array, level_id: String, objective: Objective = null) -> Array[String]:
	var errors: Array[String] = []

	# Build lookup of dialogue entry_ids
	var dialogue_ids := {}
	for row in dialogue_rows:
		if row == null:
			continue
		var id := String(row.entry_id)
		if not id.is_empty():
			dialogue_ids[id] = row

	# Build lookup of journal entries by ID and related_id
	var journal_ids := {}
	var journal_by_related := {}
	for j in journal_rows:
		if j == null:
			continue
		var jid := String(j.id)
		if not jid.is_empty():
			journal_ids[jid] = j

		var rel := String(j.related_id)
		if not rel.is_empty():
			if journal_by_related.has(rel):
				errors.append("[LevelRows] Duplicate journal related_id %s for %s" % [rel, level_id])
			journal_by_related[rel] = j

	# Collect explicit links from objective/stages/tasks
	var explicit_dialogue_whitelists := {}
	var explicit_journal_whitelists := {}
	if objective:
		for stage in objective.stages:
			if stage:
				# Stage level
				_add_explicit_links(stage, explicit_dialogue_whitelists, explicit_journal_whitelists)
				# Task level
				for task in stage.tasks:
					if task:
						_add_explicit_links(task, explicit_dialogue_whitelists, explicit_journal_whitelists)

	# Ensure every dialogue has a corresponding journal (either by related_id or explicit whitelist)
	for id in dialogue_ids.keys():
		if not journal_by_related.has(id) and not explicit_dialogue_whitelists.has(id):
			errors.append("[LevelRows] Dialogue entry_id %s missing related journal entry for %s" % [id, level_id])

	# Ensure every journal with a related_id points to an existing dialogue
	for rel in journal_by_related.keys():
		if not dialogue_ids.has(rel) and not explicit_journal_whitelists.has(rel):
			var jrow = journal_by_related[rel]
			errors.append("[LevelRows] Journal entry %s related_id %s has no matching dialogue for %s" % [jrow.id, rel, level_id])

	return errors

static func _add_explicit_links(obj: Resource, d_white: Dictionary, j_white: Dictionary) -> void:
	if "enter_dialogue_id" in obj and not String(obj.enter_dialogue_id).is_empty():
		d_white[String(obj.enter_dialogue_id)] = true
	if "enter_journal_id" in obj and not String(obj.enter_journal_id).is_empty():
		j_white[String(obj.enter_journal_id)] = true
	if "exit_dialogue_id" in obj and not String(obj.exit_dialogue_id).is_empty():
		d_white[String(obj.exit_dialogue_id)] = true
	if "exit_journal_id" in obj and not String(obj.exit_journal_id).is_empty():
		j_white[String(obj.exit_journal_id)] = true

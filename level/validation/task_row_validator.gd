extends RefCounted
class_name TaskRowValidator

static func validate(level: Level, level_id: String, roster_rows: Array, loot_rows: Array, location_rows: Array) -> Array[String]:
	var errors: Array[String] = []
	if level == null or level.objective == null:
		return errors
	
	var ctx = _collect_global_context(roster_rows, loot_rows, location_rows, level)
	
	var obj := level.objective
	if not obj or not obj.stages:
		return errors

	for st in obj.stages:
		if st == null: continue
		_collect_stage_context(st, ctx)
		_validate_stage_tasks(st, level_id, ctx, errors)
		
	return errors

static func _collect_global_context(roster_rows: Array, loot_rows: Array, location_rows: Array, level: Level) -> Dictionary:
	var ctx = {
		"loot_item_ids": {},
		"loot_willpowers_by_coord": {},
		"npc_unit_ids": {},
		"npc_item_ids": {},
		"reward_item_ids": {},
		"location_ids": {},
		"location_coords": {},
		"location_willpowers_by_id": {},
		"location_willpowers_by_coord": {},
		"location_coords_by_id": {}
	}

	# Global loot rows
	for lr in loot_rows:
		if lr == null: continue
		if "is_trapped" in lr and lr.is_trapped:
			ctx.loot_item_ids["trapped"] = true
		for it in lr.items:
			if it and it is InventoryItem:
				ctx.loot_item_ids[(it as InventoryItem).origin_id] = true
		if lr.stats:
			ctx.loot_willpowers_by_coord[_coord_key(lr.coord)] = lr.stats.willpower

	# Global roster rows
	for rr in roster_rows:
		if rr == null: continue
		var uid := String(rr.unit_id) if "unit_id" in rr else ""
		if not uid.is_empty():
			ctx.npc_unit_ids[uid] = true
		if "inventory" in rr:
			for it in rr.inventory:
				if it and it is InventoryItem:
					ctx.npc_item_ids[(it as InventoryItem).origin_id] = true

	# Reward items from objective tasks
	if level.objective:
		for st in level.objective.stages:
			if st:
				for t in st.tasks:
					if t and t.get("reward_resource"):
						var rr = t.get("reward_resource")
						if rr.reward_type == TaskReward.RewardType.ITEM:
							ctx.reward_item_ids[rr.reward_value] = true

	# Global location rows
	for loc in location_rows:
		if loc == null: continue
		var lid := String(loc.loc_id) if "loc_id" in loc else String(loc.loc_name) if "loc_name" in loc else ""
		if not lid.is_empty():
			ctx.location_ids[lid] = true
			if loc.stats:
				ctx.location_willpowers_by_id[lid] = loc.stats.willpower
			ctx.location_coords_by_id[lid] = loc.coord

		ctx.location_coords[_coord_key(loc.coord)] = true
		if loc.stats:
			ctx.location_willpowers_by_coord[_coord_key(loc.coord)] = loc.stats.willpower
			
	return ctx

static func _collect_stage_context(st: Stage, ctx: Dictionary) -> void:
	# Collect stage-embedded unit spawns
	if "enemy_spawns" in st:
		for es in st.get("enemy_spawns"):
			if es and "unit_name" in es: ctx.npc_unit_ids[String(es.unit_name)] = true
	if "neutral_spawns" in st:
		for ns in st.get("neutral_spawns"):
			if ns:
				var name = ns.unit_name if "unit_name" in ns else ""
				if not name.is_empty(): ctx.npc_unit_ids[String(name)] = true

	# Collect stage-embedded loot spawns
	if "loot_spawns" in st:
		for ls in st.get("loot_spawns"):
			if ls:
				var lid := String(ls.id)
				if not lid.is_empty():
					ctx.loot_item_ids[lid] = true
				
				if "is_trapped" in ls and ls.is_trapped:
					ctx.loot_item_ids["trapped"] = true
				for it in ls.items:
					if it and it is InventoryItem:
						ctx.loot_item_ids[(it as InventoryItem).origin_id] = true
				if ls.stats:
					ctx.loot_willpowers_by_coord[_coord_key(ls.coord)] = ls.stats.willpower

	# Collect stage-embedded location spawns
	if "location_spawns" in st:
		for lsp in st.get("location_spawns"):
			if lsp:
				var lid := String(lsp.id)
				if lid.is_empty():
					lid = String(lsp.location_name)
				
				if not lid.is_empty():
					ctx.location_ids[lid] = true
					var stats = lsp.get_stats() if lsp.has_method("get_stats") else null
					if stats:
						ctx.location_willpowers_by_id[lid] = stats.willpower
					ctx.location_coords_by_id[lid] = lsp.coord
				ctx.location_coords[_coord_key(lsp.coord)] = true

static func _validate_stage_tasks(st: Stage, level_id: String, ctx: Dictionary, errors: Array[String]) -> void:
	for t in st.tasks:
		if t == null: continue
		_validate_single_task(t, st.id, level_id, ctx, errors)

static func _validate_single_task(t: Task, stage_id: String, level_id: String, ctx: Dictionary, errors: Array[String]) -> void:
	# Validate missing metadata parameters
	if String(t.id).is_empty():
		errors.append("[LevelRows] Task in stage %s is missing 'id' for %s" % [stage_id, level_id])
	if t.title == "New Task" or t.title.is_empty():
		errors.append("[LevelRows] Task %s in stage %s has default/empty title for %s" % [t.id, stage_id, level_id])
	if t.event_type.is_empty():
		errors.append("[LevelRows] Task %s in stage %s is missing 'event_type' for %s" % [t.id, stage_id, level_id])
		
	# Enforce duration/effort exclusivity
	if t.duration_turns > 0 and t.effort_required > 0:
		push_warning("[LevelRows] Task %s has both duration and effort; preferring duration for %s" % [String(t.id), level_id])
		t.effort_required = 0

	# Validate reward_resource path
	if t.get("reward_resource"):
		var reward = t.get("reward_resource")
		if reward.reward_type == TaskReward.RewardType.ITEM:
			var item_path: String = "res://Resources/items/%s.tres" % reward.reward_value
			if not FileAccess.file_exists(item_path):
				errors.append("[LevelRows] Task %s reward item '%s' not found at %s for %s" % [String(t.id), reward.reward_value, item_path, level_id])

	_validate_task_target(t, level_id, ctx, errors)

static func _validate_task_target(t: Task, level_id: String, ctx: Dictionary, errors: Array[String]) -> void:
	var kind := String(t.target_kind)
	var target_id := String(t.target_id)
	var target_coord := t.target_coord

	if kind == "item":
		var ok: bool = ctx.loot_item_ids.has(target_id) or ctx.npc_item_ids.has(target_id) or ctx.reward_item_ids.has(target_id)
		if not ok:
			errors.append("[LevelRows] Task %s item target '%s' not found in loot/NPC/Rewards for %s" % [String(t.id), target_id, level_id])

		# Check willpower sync if coordinate is known
		if target_coord != GameConstants.INVALID_COORD:
			var key = _coord_key(target_coord)
			if ctx.loot_willpowers_by_coord.has(key):
				var wp = ctx.loot_willpowers_by_coord[key]
				if t.effort_required != wp:
					errors.append("[LevelRows] Task %s effort_required (%d) misaligned with loot willpower (%d) for %s" % [String(t.id), t.effort_required, wp, level_id])

	elif kind == "location":
		var id_ok: bool = not target_id.is_empty() and ctx.location_ids.has(target_id)
		var coord_ok: bool = (target_coord != GameConstants.INVALID_COORD) and ctx.location_coords.has(_coord_key(target_coord))

		if not (id_ok or coord_ok):
			errors.append("[LevelRows] Task %s location target not found (id '%s', coord %s) for %s" % [String(t.id), target_id, target_coord, level_id])
		else:
			# If both are present, they must match
			if id_ok and coord_ok:
				var expected_coord = ctx.location_coords_by_id[target_id]
				if target_coord != expected_coord:
					errors.append("[LevelRows] Task %s target_coord %s does not match location '%s' at %s for %s" % [String(t.id), target_coord, target_id, expected_coord, level_id])

			# Check willpower sync
			var target_willpower: int = -1
			if id_ok:
				target_willpower = ctx.location_willpowers_by_id.get(target_id, -1)
			elif coord_ok:
				target_willpower = ctx.location_willpowers_by_coord.get(_coord_key(target_coord), -1)

			if target_willpower != -1 and t.effort_required != target_willpower:
				errors.append("[LevelRows] Task %s effort_required (%d) misaligned with location willpower (%d) for %s" % [String(t.id), t.effort_required, target_willpower, level_id])

	elif kind == "unit":
		if target_id.is_empty() or not ctx.npc_unit_ids.has(target_id):
			errors.append("[LevelRows] Task %s unit target '%s' not found among non-player spawns for %s" % [String(t.id), target_id, level_id])

static func _coord_key(coord: Vector2i) -> String:
	return HexLib.key_of(coord)

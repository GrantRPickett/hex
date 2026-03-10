extends RefCounted
class_name TaskRowValidator

static func validate(level: Level, level_id: String, roster_rows: Array, loot_rows: Array, location_rows: Array) -> Array[String]:
	var errors: Array[String] = []
	if level == null or level.objective == null:
		return errors
	
	# Build row-scoped sets and willpower lookups
	var loot_item_ids := {}
	var loot_willpowers_by_coord := {}

	# Global loot rows
	for lr in loot_rows:
		if lr == null: continue
		if "is_trapped" in lr and lr.is_trapped:
			loot_item_ids["trapped"] = true
		for it in lr.items:
			if it and it is InventoryItem:
				loot_item_ids[(it as InventoryItem).origin_id] = true
		if lr.stats:
			loot_willpowers_by_coord[_coord_key(lr.coord)] = lr.stats.willpower

	var npc_unit_ids := {}
	var npc_item_ids := {}

	# Global roster rows
	for rr in roster_rows:
		if rr == null: continue
		var uid := String(rr.unit_id) if "unit_id" in rr else ""
		if not uid.is_empty():
			npc_unit_ids[uid] = true
		if "inventory" in rr:
			for it in rr.inventory:
				if it and it is InventoryItem:
					npc_item_ids[(it as InventoryItem).origin_id] = true

	var reward_item_ids := {}
	if level.objective:
		for st in level.objective.stages:
			if st:
				for t in st.tasks:
					if t and t.get("reward_resource"):
						var rr = t.get("reward_resource")
						if rr.reward_type == TaskReward.RewardType.ITEM:
							reward_item_ids[rr.reward_value] = true

	var location_ids := {}
	var location_coords := {}
	var location_willpowers_by_id := {}
	var location_willpowers_by_coord := {}
	var location_coords_by_id := {}

	# Global location rows
	for loc in location_rows:
		if loc == null: continue
		var lid := String(loc.loc_id) if "loc_id" in loc else String(loc.loc_name) if "loc_name" in loc else ""
		if not lid.is_empty():
			location_ids[lid] = true
			if loc.stats:
				location_willpowers_by_id[lid] = loc.stats.willpower
			location_coords_by_id[lid] = loc.coord

		location_coords[_coord_key(loc.coord)] = true
		if loc.stats:
			location_willpowers_by_coord[_coord_key(loc.coord)] = loc.stats.willpower

	# Iterate tasks in stages and collect stage-embedded spawns
	var obj := level.objective
	if not obj or not obj.stages:
		return errors

	for st in obj.stages:
		if st == null: continue

		# Collect stage-embedded unit spawns
		if "enemy_spawns" in st:
			for es in st.get("enemy_spawns"):
				if es and "unit_name" in es: npc_unit_ids[String(es.unit_name)] = true
		if "neutral_spawns" in st:
			for ns in st.get("neutral_spawns"):
				if ns:
					var name = ns.unit_name if "unit_name" in ns else ""
					if not name.is_empty(): npc_unit_ids[String(name)] = true

		# Collect stage-embedded loot spawns
		if "loot_spawns" in st:
			for ls in st.get("loot_spawns"):
				if ls:
					if "is_trapped" in ls and ls.is_trapped:
						loot_item_ids["trapped"] = true
					for it in ls.items:
						if it and it is InventoryItem:
							loot_item_ids[(it as InventoryItem).origin_id] = true
					if ls.stats:
						loot_willpowers_by_coord[_coord_key(ls.coord)] = ls.stats.willpower

		# Collect stage-embedded location spawns
		if "location_spawns" in st:
			for lsp in st.get("location_spawns"):
				if lsp:
					var lid := String(lsp.location_name)
					if not lid.is_empty():
						location_ids[lid] = true
						if lsp.has_method("get_stats") and lsp.get_stats():
							location_willpowers_by_id[lid] = lsp.get_stats().willpower
						location_coords_by_id[lid] = lsp.coord
					location_coords[_coord_key(lsp.coord)] = true

		for t in st.tasks:
			if t == null: continue

			# Validate missing metadata parameters
			if String(t.id).is_empty():
				errors.append("[LevelRows] Task in stage %s is missing 'id' for %s" % [st.id, level_id])
			if t.title == "New Task" or t.title.is_empty():
				errors.append("[LevelRows] Task %s in stage %s has default/empty title for %s" % [t.id, st.id, level_id])
			if t.event_type.is_empty():
				errors.append("[LevelRows] Task %s in stage %s is missing 'event_type' for %s" % [t.id, st.id, level_id])
			# Enforce duration/effort exclusivity
			if t.duration_turns > 0 and t.effort_required > 0:
				push_warning("[LevelRows] Task %s has both duration and effort; preferring duration for %s" % [String(t.id), level_id])
				t.effort_required = 0

			# Validate reward_resource path
			if t.get("reward_resource"):
				var reward = t.get("reward_resource")
				if reward.reward_type == TaskReward.RewardType.ITEM:
					var item_path = "res://Resources/items/%s.tres" % reward.reward_value
					if not FileAccess.file_exists(item_path):
						errors.append("[LevelRows] Task %s reward item '%s' not found at %s for %s" % [String(t.id), reward.reward_value, item_path, level_id])

			# Validate target when target_kind is set
			var kind := String(t.target_kind)
			var target_id := String(t.target_id)
			var target_coord := t.target_coord

			if kind == "item":
				var ok := loot_item_ids.has(target_id) or npc_item_ids.has(target_id) or reward_item_ids.has(target_id)
				if not ok:
					errors.append("[LevelRows] Task %s item target '%s' not found in loot/NPC/Rewards for %s" % [String(t.id), target_id, level_id])

				# Check willpower sync if coordinate is known
				if target_coord != Vector2i(-999, -999):
					var key = _coord_key(target_coord)
					if loot_willpowers_by_coord.has(key):
						var wp = loot_willpowers_by_coord[key]
						if t.effort_required != wp:
							errors.append("[LevelRows] Task %s effort_required (%d) misaligned with loot willpower (%d) for %s" % [String(t.id), t.effort_required, wp, level_id])

			elif kind == "location":
				var id_ok := not target_id.is_empty() and location_ids.has(target_id)
				var coord_ok := (target_coord != Vector2i(-999, -999)) and location_coords.has(_coord_key(target_coord))

				if not (id_ok or coord_ok):
					errors.append("[LevelRows] Task %s location target not found (id '%s', coord %s) for %s" % [String(t.id), target_id, target_coord, level_id])
				else:
					# Check for coordinate sync
					if id_ok and target_coord == Vector2i(-999, -999):
						errors.append("[LevelRows] Task %s is missing target_coord but has target_id '%s' for %s" % [String(t.id), target_id, level_id])
					elif id_ok and coord_ok:
						var expected_coord = location_coords_by_id[target_id]
						if target_coord != expected_coord:
							errors.append("[LevelRows] Task %s target_coord %s does not match location '%s' at %s for %s" % [String(t.id), target_coord, target_id, expected_coord, level_id])

					# Check willpower sync
					var target_willpower = -1
					if id_ok:
						target_willpower = location_willpowers_by_id.get(target_id, -1)
					elif coord_ok:
						target_willpower = location_willpowers_by_coord.get(_coord_key(target_coord), -1)

					if target_willpower != -1 and t.effort_required != target_willpower:
						errors.append("[LevelRows] Task %s effort_required (%d) misaligned with location willpower (%d) for %s" % [String(t.id), t.effort_required, target_willpower, level_id])

			elif kind == "unit":
				if target_id.is_empty() or not npc_unit_ids.has(target_id):
					errors.append("[LevelRows] Task %s unit target '%s' not found among non-player spawns for %s" % [String(t.id), target_id, level_id])
	return errors

static func _coord_key(coord: Vector2i) -> String:
	return GridService.key_of(coord)

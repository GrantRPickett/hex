extends RefCounted
class_name ConnectivityValidator

static func validate(level: Level, level_id: String, roster_rows: Array, loot_rows: Array, location_rows: Array, start_rows: Array) -> Array[String]:
	if level.terrain_data == null or level.terrain_data.terrain_rows.is_empty(): return []

	var dims := HexLib.dims_of(level)
	var player_starts: Array[Vector2i] = []
	for row in start_rows:
		if row and row.faction == Unit.Faction.PLAYER: player_starts.append(row.coord)
	if player_starts.is_empty(): return []

	var poi_map := _collect_pois(level, roster_rows, loot_rows, location_rows, int(dims.width), int(dims.height))

	var terrain_map := TerrainMap.new()
	terrain_map.set_offset_axis(int(dims.axis))
	terrain_map.load_from_rows(level.terrain_data.terrain_rows, int(dims.width), int(dims.height))

	var start_coord = player_starts[0]
	if not terrain_map.is_passable(start_coord):
		return ["[Connectivity] Primary player start at %s is on impassable terrain for %s" % [start_coord, level_id]]

	var reachable := _perform_reachability_scan(start_coord, terrain_map, int(dims.width), int(dims.height), int(dims.axis))
	return _report_connectivity_errors(poi_map, player_starts, reachable, level_id)

static func _collect_pois(level: Level, roster_rows: Array, loot_rows: Array, location_rows: Array, width: int, height: int) -> Dictionary:
	var poi_map := {}
	var add_poi: Callable = func(p_coord: Vector2i, label: String):
		if not HexLib.is_in_bounds(p_coord, width, height): return
		var key = HexLib.key_of(p_coord)
		if not poi_map.has(key): poi_map[key] = []
		poi_map[key].append(label)

	for row in roster_rows:
		if row: add_poi.call(row.coord, "Roster entry (%s)" % row.resource_path.get_file())
	for row in loot_rows:
		if row: add_poi.call(row.coord, "Loot entry (%s)" % row.resource_path.get_file())
	for row in location_rows:
		if row: add_poi.call(row.coord, "Location entry (%s)" % row.resource_path.get_file())

	if level.objective:
		for stage in level.objective.stages:
			if stage:
				# Scoped POIs from stage-embedded spawns
				if "enemy_spawns" in stage:
					for es in stage.get("enemy_spawns"):
						if es:
							var name = es.unit_name if "unit_name" in es else "Unit"
							add_poi.call(es.coord, "Stage Enemy spawn (%s)" % name)
				if "neutral_spawns" in stage:
					for ns in stage.get("neutral_spawns"):
						if ns:
							var name = ns.unit_name if "unit_name" in ns else "Unit"
							add_poi.call(ns.coord, "Stage Neutral spawn (%s)" % name)
				if "location_spawns" in stage:
					for lsp in stage.get("location_spawns"):
						if lsp: add_poi.call(lsp.coord, "Stage Location spawn (%s)" % lsp.location_name)
				if "loot_spawns" in stage:
					for ls in stage.get("loot_spawns"):
						if ls: add_poi.call(ls.coord, "Stage Loot spawn")

				for task in stage.tasks:
					if task and task.target_coord != Vector2i(-999, -999):
						add_poi.call(task.target_coord, "Task target '%s'" % task.title)
	return poi_map

static func _perform_reachability_scan(start_coord: Vector2i, terrain_map: TerrainMap, width: int, height: int, axis: int) -> Dictionary:
	var reachable := {}
	var queue: Array[Vector2i] = [start_coord]
	reachable[HexLib.key_of(start_coord)] = true

	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		var neighbors: Array = HexLib.get_neighbor_offsets(current, axis)
		for offset: Vector2i in neighbors:
			var next = current + offset
			if not HexLib.is_in_bounds(next, width, height): continue
			var key = HexLib.key_of(next)
			if reachable.has(key) or not terrain_map.is_passable(next): continue
			reachable[key] = true
			queue.append(next)
	return reachable

static func _report_connectivity_errors(poi_map: Dictionary, player_starts: Array[Vector2i], reachable: Dictionary, level_id: String) -> Array[String]:
	var errors: Array[String] = []
	for key in poi_map.keys():
		if not reachable.has(key):
			for desc in poi_map[key]:
				errors.append("[Connectivity] %s at %s is unreachable from player start for %s" % [desc, key, level_id])

	for i in range(1, player_starts.size()):
		var ps = player_starts[i]
		if not reachable.has(HexLib.key_of(ps)):
			errors.append("[Connectivity] Player start at %s is unreachable from primary player start for %s" % [ps, level_id])
	return errors

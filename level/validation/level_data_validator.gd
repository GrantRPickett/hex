class_name LevelDataValidator
extends RefCounted

static func validate_data(data: Dictionary) -> void:
	filter_coords(data, ["player_starts", "enemy_starts", "location_coords", "loot_coords"])

static func filter_coords(data: Dictionary, keys: Array[String]) -> void:
	for key in keys:
		if not data.has(key):
			continue
		var filtered: Array[Vector2i] = []
		var seen := {}
		for coord in data[key]:
			if coord.x < 0 or coord.y < 0:
				GameLogger.error(GameLogger.Category.MAP, "LevelDataValidator: Rejected %s with negative axis: %s" % [key, coord])
				continue
			var k := "%s,%s" % [coord.x, coord.y]
			if seen.has(k):
				continue
			seen[k] = true
			filtered.append(coord)
		data[key] = filtered

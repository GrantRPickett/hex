class_name SpawnUtils
extends RefCounted

static func parse_entry(entry) -> Dictionary:
	var result := {"scene": null, "coord": Vector2i(-999, -999)}
	if entry == null:
		return result
	if entry is Dictionary:
		result.scene = entry.get("unit_scene") if entry.has("unit_scene") else null
		result.coord = entry.get("coord", result.coord)
		return result
	if "unit_scene" in entry:
		result.scene = entry.unit_scene
	if "coord" in entry:
		result.coord = entry.coord
	return result

static func to_spawn_entry(parsed: Dictionary) -> LevelUnitSpawnEntry:
	var se := LevelUnitSpawnEntry.new()
	se.unit_scene = parsed.get("scene")
	se.coord = parsed.get("coord", Vector2i(-999, -999))
	if parsed.has("ai_profile"):
		se.ai_profile = parsed.ai_profile
	return se

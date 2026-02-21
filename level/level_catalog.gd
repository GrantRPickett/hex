class_name LevelCatalog
extends RefCounted

const LEVELS: Array[Dictionary] = [
	{"id": "level_0", "path": "res://Resources/level_data/hometown/levels/hometown.tres", "display_name": "Hometown", "prerequisites": [], "is_hometown": true, "repeatable": true},
	{"id": "level_1", "path": "res://Resources/level_data/level_1/levels/level_1.tres", "display_name": "The Beginning", "prerequisites": []},
	{"id": "level_2", "path": "res://Resources/level_data/level_2/levels/level_2.tres", "display_name": "Crossroads", "prerequisites": ["level_1"]},
	{"id": "level_3", "path": "res://Resources/level_data/level_3/levels/level_3.tres", "display_name": "Fork in the Road", "prerequisites": ["level_1"]},
	{"id": "level_4", "path": "res://Resources/level_data/level_4/levels/level_4.tres", "display_name": "Branching Path", "prerequisites": ["level_1"]},
	{"id": "level_5", "path": "res://Resources/level_data/level_5/levels/level_5.tres", "display_name": "Twin Peaks", "prerequisites": ["level_2", "level_3"]},
	{"id": "level_6", "path": "res://Resources/level_data/level_6/levels/level_6.tres", "display_name": "Confluence", "prerequisites": ["level_3", "level_4"]},
	{"id": "level_7", "path": "res://Resources/level_data/level_7/levels/level_7.tres", "display_name": "The Nexus", "prerequisites": ["level_2", "level_4"]},
	{"id": "test_level", "path": "res://Resources/level_data/test_level/levels/test_level.tres", "display_name": "Test Level", "prerequisites": []},
]

func get_levels() -> Array[Dictionary]:
	return LEVELS.duplicate(true)

func get_level_by_id(level_id: String) -> Dictionary:
	for entry in LEVELS:
		if entry.get("id", "") == level_id:
			return entry.duplicate(true)
	return {}

func find_level_by_path(path: String) -> Dictionary:
	for entry in LEVELS:
		if entry.get("path", "") == path:
			return entry.duplicate(true)
	return {}


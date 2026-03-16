class_name LevelCatalog
extends RefCounted

const LEVELS: Array[Dictionary] = [
	{"id": "hometown", "path": "res://Resources/level_data/hometown/hometown.tres", "display_name": "Hometown", "prerequisites": [], "is_hometown": true, "repeatable": true},
	{"id": "test_level", "path": "res://Resources/level_data/test_level/test_level.tres", "display_name": "Test Level", "prerequisites": []},
	{"id": "zoo_test", "path": "res://Resources/level_data/zoo_test/zoo_test.tres", "display_name": "Feature Zoo Level", "prerequisites": []},
	{"id": "faction_branching_test", "path": "res://Resources/level_data/faction_branching_test/faction_branching_test.tres", "display_name": "Faction Branching Test", "prerequisites": []},
	{"id": "quest_competition", "path": "res://Resources/level_data/quest_competition/quest_competition.tres", "display_name": "Quest for the Golden Idol", "prerequisites": []},
	{"id": "new_level", "path": "res://Resources/level_data/new_level/new_level.tres", "display_name": "New Level Template", "prerequisites": []},
	{"id": "target_group_tasks", "path": "res://Resources/level_data/target_group_tasks/target_group_tasks.tres", "display_name": "Target Group Tasks", "prerequisites": []},
	{"id": "omega_trial", "path": "res://Resources/level_data/omega_trial/omega_trial.tres", "display_name": "The Omega Trial", "prerequisites": []},
	{"id": "test_item_conv", "path": "res://Resources/level_data/test_item_conv/test_item_conv.tres", "display_name": "Item Conversion Test", "prerequisites": []},
	{"id": "convince_guard", "path": "res://Resources/level_data/convince_guard/convince_guard.tres", "display_name": "Convince the Guard", "prerequisites": []},
]
func get_default_level() -> String:
	return "res://Resources/level_data/hometown/hometown.tres"

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

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
	{"id": "moba_level", "path": "res://Resources/level_data/moba_level/moba_level.tres", "display_name": "The Emerald Arena", "prerequisites": []},
	{"id": "gym_level", "path": "res://Resources/level_data/gym_level/gym_level.tres", "display_name": "Testing Gym", "prerequisites": []},
	{"id": "tutorial_01", "path": "res://Resources/level_data/tutorial_01/tutorial_01.tres", "display_name": "The Gatekeeper", "prerequisites": []},
	{"id": "tutorial_02", "path": "res://Resources/level_data/tutorial_02/tutorial_02.tres", "display_name": "The Briar Path", "prerequisites": []},
	{"id": "tutorial_03", "path": "res://Resources/level_data/tutorial_03/tutorial_03.tres", "display_name": "The Sinking Cache", "prerequisites": []},
	{"id": "tutorial_04", "path": "res://Resources/level_data/tutorial_04/tutorial_04.tres", "display_name": "The Shadowed Ruins", "prerequisites": []},
	{"id": "tutorial_05", "path": "res://Resources/level_data/tutorial_05/tutorial_05.tres", "display_name": "The Outpost", "prerequisites": []},
	{"id": "tutorial_06", "path": "res://Resources/level_data/tutorial_06/tutorial_06.tres", "display_name": "The Frozen Vault", "prerequisites": []},
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

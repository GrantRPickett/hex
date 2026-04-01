from file_paths_loader import FilePathsLoader

# Initialize FilePaths helper
paths_helper = FilePathsLoader("Resources/file_paths.json")

# Mapping of GDScript class names to their file paths
SCRIPT_PATHS = {
	"Level": paths_helper.get_path("resources.core.level") or "res://level/level.gd",
	"Objective": paths_helper.get_path("resources.task_system.objective") or "res://Gameplay/narrative/task/objective.gd",
	"Stage": paths_helper.get_path("resources.task_system.stage") or "res://Gameplay/narrative/task/stage.gd",
	"Task": paths_helper.get_path("resources.task_system.task") or "res://Gameplay/narrative/task/task.gd",
	"LevelDialogueEntry": paths_helper.get_path("resources.level_data.level_dialogue_entry") or "res://level/level_dialogue_entry.gd",

	"JournalEntry": paths_helper.get_path("resources.level_data.level_journal_entry") or "res://level/journal_entry.gd",
	"LevelDialogueJournalEntry": paths_helper.get_path("resources.level_data.level_dialogue_journal_entry") or "res://level/level_dialogue_journal_entry.gd",
	"LevelTerrainData": paths_helper.get_path("resources.level_data.level_terrain_data") or "res://level/level_terrain_data.gd",
	"UnitRosterDefinition": paths_helper.get_path("resources.rosters.unit_roster_definition") or "res://Gameplay/roster/unit_roster_definition.gd",
	"LevelUnitSpawnEntry": paths_helper.get_path("resources.level_data.level_unit_spawn_entry") or "res://level/level_unit_spawn_entry.gd",
	"LevelLootEntry": paths_helper.get_path("resources.level_data.level_loot_entry") or "res://level/level_loot_entry.gd",
	"LevelLocationEntry": paths_helper.get_path("resources.level_data.level_location_entry") or "res://level/level_location_entry.gd",
	"LevelTaskEntry": paths_helper.get_path("resources.level_data.level_task_entry") or "res://level/level_task_entry.gd",

	"CompletionCondition": paths_helper.get_path("resources.task_system.completion_condition") or "res://Gameplay/narrative/task/completion_condition.gd",
	"TaskReward": paths_helper.get_path("resources.task_system.task_reward") or "res://Gameplay/narrative/task/task_reward.gd",
	"CombatStats": paths_helper.get_path("resources.level_data.combat_stats") or "res://level/combat_stats.gd",
	"InventoryItem": paths_helper.get_path("gameplay.components.inventory_item") or "res://Gameplay/targets/inventory_item.gd",
	"ItemTemplate": paths_helper.get_path("resources.items.item_template") or "res://Resources/items/item_template.gd",
}

# Subdirectories for level data organization
LEVEL_DATA_SUBDIRS = [
	'stages', 'terrain_rows', 'start_rows', 'roster_rows',
	'loot_rows', 'location_rows', 'dialogue_rows',
	'journal_entry_rows', 'summaries'
]

# Mapping of enum strings to integer values (Sync with Godot scripts)
ENUM_VALUES = {
	"CompletionMode": {
		"ALL_REQUIRED": 0,
		"ANY_REQUIRED": 1,
		"ANY_WITH_BRANCHING": 2,
	},
	"TaskStatus": {
		"PENDING": 0,
		"ACTIVE": 1,
		"COMPLETED": 2,
		"FAILED": 3,
		"CANCELLED": 4,
	},
	"UnitFaction": {
		"PLAYER": 0,
		"ENEMY": 1,
		"NEUTRAL": 2,
	},
	"TaskType": { # Event Type aligned with GameConstants.TaskEvents
		"interact": "interact",
		"visit": "visit",
		"explore": "explore",
		"move": "move",
		"loot": "loot",
		"trapped": "trapped",
		"attack": "attack",
		"convince": "convince",
		"ability_used": "ability_used",
		"dialogue_started": "dialogue_started",
		"dialogue_finished": "dialogue_finished",
		"unit_defeated": "unit_defeated",
		"round_changed": "round_changed",
		"explore_zone": "explore_zone",
		"eliminate": "eliminate",
		"countdown": "countdown",
	},
	"TaskRewardType": {
		"ITEM": 0,
		"HINT": 1,
		"UNIT_ADDITION": 2
	}
}

# Fallback scenes
GENERIC_UNIT_SCENE = paths_helper.get_path("scenes.templates.unit") or "res://Gameplay/scene_templates/generic_unit.tscn"
GENERIC_LOCATION_SCENE = paths_helper.get_path("scenes.templates.location") or "res://Gameplay/scene_templates/location.tscn"
GENERIC_LOOT_SCENE = paths_helper.get_path("scenes.templates.loot") or "res://Gameplay/scene_templates/loot.tscn"

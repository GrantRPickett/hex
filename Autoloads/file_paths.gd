## Centralized File Paths Registry
##
## This script serves as a single source of truth for all file paths used throughout the project.
## Using this registry reduces refactoring burden when moving files around.
##
## Usage:
##   const FilePaths = preload("res://Autoloads/file_paths.gd")
##   var path = FilePaths.SCENES.GAMEPLAY
##
## ⚠️ WARNINGS FOR DYNAMICALLY-GENERATED PATHS:
##   - Dialogue paths with dynamic level prefixes (see dialogue_rows/)
##   - Level resource paths loaded from LevelCatalog
##   - JSON conversion outputs (json_to_tres.py)
##   See DYNAMIC_PATHS section below

extends Node


# ============================================================================
# SCENE PATHS (.tscn files)
# ============================================================================

class Scenes:
	const GAMEPLAY := "res://Gameplay/gameplay.tscn"
	const TITLE_SCREEN := "res://Menus/title_screen.tscn"
	const CREDITS := "res://Menus/credits.tscn"
	const LEVEL_SELECT := "res://Menus/level_select.tscn"
	const LOCATION := "res://Gameplay/location.tscn"
	const PAUSE_MENU := "res://Menus/pause_menu.tscn"
	const CONTROLS_MENU := "res://Menus/controls_menu.tscn"
	const SETTINGS_MENU := "res://Menus/settings_menu.tscn"
	const JOURNAL_UI := "res://GUI/journal_ui.tscn"

	# GUI Panels
	const ROUND_INFO_PANEL := "res://GUI/round_info_panel.tscn"
	const LOCATIONS_LIST_PANEL := "res://GUI/locations_list_panel.tscn"
	const TASKS_LIST_PANEL := "res://GUI/tasks_list_panel.tscn"
	const UNIT_DETAILS_PANEL := "res://GUI/unit_details_panel.tscn"
	const COMBAT_PREVIEW_PANEL := "res://GUI/combat_preview_panel.tscn"
	const LOCATION_DETAILS_PANEL := "res://GUI/location_details_panel.tscn"
	const TASK_DETAILS_PANEL := "res://GUI/task_details_panel.tscn"
	const TERRAIN_DETAILS_PANEL := "res://GUI/terrain_details_panel.tscn"
	const ACTIONS_PANEL := "res://GUI/actions_panel.tscn"
	const LOOT_DETAILS_PANEL := "res://GUI/loot_details_panel.tscn"
	const WEATHER_PANEL := "res://GUI/weather_panel.tscn"
	const MORALE_PANEL := "res://GUI/morale_panel.tscn"
	const TASK_LIST_ITEM := "res://GUI/task_list_item.tscn"
	const LOCATION_DISPLAY_ITEM := "res://GUI/location_display_item.tscn"

	# Character Scenes
	const ASSASSIN := "res://Resources/characters/core/assassin.tscn"
	const BERSERKER := "res://Resources/characters/core/berserker.tscn"
	const DUELIST := "res://Resources/characters/core/duelist.tscn"
	const HEALER := "res://Resources/characters/core/healer.tscn"
	const MONK := "res://Resources/characters/core/monk.tscn"
	const SCOUT := "res://Resources/characters/core/scout.tscn"

	# Scene Templates
	const GENERIC_UNIT := "res://Gameplay/scene_templates/generic_unit.tscn"
	const GENERIC_ENEMY := "res://Gameplay/scene_templates/generic_enemy.tscn"
	const GENERIC_NEUTRAL := "res://Gameplay/scene_templates/generic_neutral.tscn"
	const LOOT := "res://Gameplay/scene_templates/loot.tscn"
	const LOCATION_TEMPLATE := "res://Gameplay/scene_templates/location.tscn"
	const GENERIC_LOCATION := "res://Gameplay/scene_templates/location.tscn"

# ============================================================================
# AUTOLOAD SCRIPTS (.gd files registered in project.godot)
# ============================================================================

class Autoloads:
	const CONTROL_SETTINGS := "res://Autoloads/control_settings.gd"
	const GAME_CONFIG := "res://Autoloads/game_config.gd"
	const SCENE_TRANSITION := "res://Autoloads/scene_transition.gd"
	const INPUT_MAPPER := "res://Autoloads/input_mapper.gd"
	const AUDIO_BUS_CONTROLLER := "res://Autoloads/audio_bus_controller.gd"
	const EVENT_BUS := "res://Autoloads/event_bus.gd"
	const SAVE_MANAGER := "res://Autoloads/save_manager.gd"
	const LEVEL_MANAGER := "res://Autoloads/level_manager.gd"
	const DISPLAY_SETTINGS := "res://Autoloads/display_settings.gd"
	const WEATHER_MANAGER := "res://Autoloads/weather_manager.gd"
	const JOURNAL_MANAGER := "res://Autoloads/journal_manager.gd"
	const ACHIEVEMENT_MANAGER := "res://Autoloads/achievement_manager.gd"


# ============================================================================
# RESOURCE CLASSES & SCRIPTS (.gd script class definitions)
# ============================================================================

class Resources:
	# Core level/game resources
	const LEVEL := "res://level/Level.gd"
	const GOAL_DEFINITION := "res://Resources/goal_definition.gd"
	const GOAL_STEP := "res://Resources/goal_step.gd"
	const INPUT_ACTIONS := "res://Resources/input_actions.gd"
	const DISPLAY_ORIENTATION := "res://Resources/display_orientation.gd"

	# Task & objective system
	const OBJECTIVE := "res://Gameplay/narrative/task/objective.gd"
	const STAGE := "res://Gameplay/narrative/task/stage.gd"
	const TASK := "res://Gameplay/narrative/task/task.gd"
	const TASK_DEFINITION := "res://Gameplay/narrative/task/task_definition.gd"
	const COMPLETION_CONDITION := "res://Gameplay/narrative/task/completion_condition.gd"

	# Level data structures
	const LEVEL_TERRAIN_DATA := "res://level/level_terrain_data.gd"
	const LEVEL_TERRAIN_ROW := "res://level/level_terrain_row.gd"
	const LEVEL_META_ROW := "res://level/level_meta_row.gd"
	# (LEVEL_START_ROW removed — replaced by LEVEL_UNIT_SPAWN_ENTRY)
	const LEVEL_DIALOGUE_ENTRY := "res://level/level_dialogue_entry.gd"
	const LEVEL_JOURNAL_ENTRY := "res://level/level_journal_entry.gd"
	const LEVEL_LOOT_ENTRY := "res://level/level_loot_entry.gd"
	const LEVEL_LOOT_ROW := "res://level/level_loot_row.gd"
	const LEVEL_GOAL_ROW := "res://level/level_goal_row.gd"
	const LEVEL_TASK_ROW := "res://level/level_task_row.gd"
	const LEVEL_UNIT_SPAWN_ENTRY := "res://level/level_unit_spawn_entry.gd"
	const LEVEL_ROSTER_ROW := "res://level/level_roster_row.gd"
	const LEVEL_TASK_ENTRY := "res://level/level_task_entry.gd"
	const LEVEL_DIALOGUE_JOURNAL_ENTRY := "res://level/level_dialogue_journal_entry.gd"
	const LEVEL_ROW_LOADER := "res://level/level_row_loader.gd"
	const LEVEL_ROW_VALIDATOR := "res://level/level_row_validator.gd"
	const LEVEL_AUTO_FIX_OPTIONS := "res://level/level_auto_fix_options.gd"
	const LEVEL_AUTO_FIX_SERVICE := "res://level/level_auto_fix_service.gd"
	const LEVEL_CATALOG := "res://level/level_catalog.gd"

	# Roster/Unit system
	const UNIT_ROSTER_DEFINITION := "res://Gameplay/roster/unit_roster_definition.gd"

	# Dialogue system
	const ACHIEVEMENT := "res://Resources/achievements/achievement.gd"
	const DEFAULT_ANIMATION_STYLE_SET := "res://Resources/animations/default_animation_styles.tres"
	const DEFAULT_PLAYER_ROSTER := "res://Resources/rosters/default_player_roster.tres"
	const DEFAULT_ENEMY_ROSTER := "res://Resources/rosters/default_enemy_roster.tres"
	const DEFAULT_NEUTRAL_ROSTER := "res://Resources/rosters/default_neutral_roster.tres"
	const LOCALIZATION_STRINGS := "res://Resources/Localization/localization_strings.gd"


# ============================================================================
# GAMEPLAY SCRIPTS (.gd gameplay logic files - NOT preloaded by default)
# ============================================================================

class Gameplay:
	const GAMEPLAY_MAIN := "res://Gameplay/gameplay.gd"
	const UNIT := "res://Gameplay/targets/unit.gd"
	const UNIT_COMPONENT_FACTORY := "res://Gameplay/unit_component_factory.gd"
	const UNIT_SERIALIZER := "res://Gameplay/unit_serializer.gd"
	const AI_CONTROLLER := "res://Gameplay/ai_controller.gd"

	# Level Management
	const LEVEL_MANAGER_GAMEPLAY := "res://level/level_manager_gameplay.gd"
	const LEVEL_FLOW_CONTROLLER := "res://level/level_flow_controller.gd"
	const LEVEL_PROGRESS_STORE := "res://level/level_progress_store.gd"
	const LEVEL_BUILD_CONTEXT := "res://level/level_build_context.gd"
	const AUTO_BATTLE_DIAGNOSTICS := "res://Gameplay/auto_battle_diagnostics.gd"

	const ROSTER_LOADER := "res://Gameplay/roster_loader.gd"
	const ROSTER_PERSISTENCE := "res://Gameplay/roster_persistence.gd"
	const TARGET_SPAWNER := "res://Gameplay/target_spawner.gd"
	const DIALOGUE_TRIGGER := "res://Gameplay/dialogue_trigger.gd"
	const DIALOGUE_TRIGGER_GROUP := "res://Gameplay/dialogue_trigger_group.gd"
	const DIALOGUE_ACTION_SERVICE := "res://Gameplay/dialogue_action_service.gd"
	const HUD_COMPONENT_FACTORY := "res://Gameplay/hud_component_factory.gd"

	# Components
	const INVENTORY_COMPONENT := "res://Gameplay/components/inventory_component.gd"
	const ACTION_POINTS_COMPONENT := "res://Gameplay/components/action_points_component.gd"
	const MOVEMENT_RANGE_CACHE := "res://Gameplay/components/movement_range_cache.gd"

	# Map/Terrain
	const TERRAIN_MAP := "res://Gameplay/map/terrain_map.gd"

	# Terrain types
	const TERRAIN_STONE := "res://Gameplay/terrain/stone.gd"
	const TERRAIN_CAVE_ENTRANCE := "res://Gameplay/terrain/cave_entrance.gd"
	const TERRAIN_WATERFALL := "res://Gameplay/terrain/waterfall.gd"
	const TERRAIN_LAVA_FLOW := "res://Gameplay/terrain/lava_flow.gd"
	const TERRAIN_MOUNTAIN_PEAK := "res://Gameplay/terrain/mountain_peak.gd"
	const TERRAIN_DESERT_OASIS := "res://Gameplay/terrain/desert_oasis.gd"
	const TERRAIN_MONASTERY := "res://Gameplay/terrain/monastery.gd"
	const TERRAIN_GRAVEYARD := "res://Gameplay/terrain/graveyard.gd"
	const TERRAIN_FLOATING_ISLAND := "res://Gameplay/terrain/floating_island.gd"
	const TERRAIN_ROCK_DUNE := "res://Gameplay/terrain/rock_dune.gd"
	const TERRAIN_ASH := "res://Gameplay/terrain/ash.gd"
	const TERRAIN_BRIDGE_CAUSEWAY := "res://Gameplay/terrain/bridge_causeway.gd"
	const TERRAIN_COURTYARD := "res://Gameplay/terrain/courtyard.gd"
	const TERRAIN_SAND := "res://Gameplay/terrain/sand.gd"
	const TERRAIN_ENCHANTED_FOREST := "res://Gameplay/terrain/enchanted_forest.gd"
	const TERRAIN_FORT := "res://Gameplay/terrain/fort.gd"
	const TERRAIN_GRASS := "res://Gameplay/terrain/grass.gd"
	const TERRAIN_HILL_HIGH_GROUND := "res://Gameplay/terrain/hill_high_ground.gd"
	const TERRAIN_ICE := "res://Gameplay/terrain/ice.gd"
	const TERRAIN_JUNGLE := "res://Gameplay/terrain/jungle.gd"
	const TERRAIN_KEEP := "res://Gameplay/terrain/keep.gd"
	const TERRAIN_LEAF_PLATFORM := "res://Gameplay/terrain/leaf_platform.gd"
	const TERRAIN_MUD := "res://Gameplay/terrain/mud.gd"
	const TERRAIN_RUINS := "res://Gameplay/terrain/ruins.gd"
	const TERRAIN_OASIS := "res://Gameplay/terrain/oasis.gd"
	const TERRAIN_PATH := "res://Gameplay/terrain/path.gd"
	const TERRAIN_QUAGMIRE := "res://Gameplay/terrain/quagmire.gd"
	const TERRAIN_RIVER := "res://Gameplay/terrain/river.gd"
	const TERRAIN_SWAMP := "res://Gameplay/terrain/swamp.gd"
	const TERRAIN_TREE_VILLAGE := "res://Gameplay/terrain/tree_village.gd"
	const TERRAIN_UNDERGROUND := "res://Gameplay/terrain/underground.gd"
	const TERRAIN_VINES := "res://Gameplay/terrain/vines.gd"
	const TERRAIN_WALL := "res://Gameplay/terrain/wall.gd"
	const TERRAIN_CROSSROADS := "res://Gameplay/terrain/crossroads.gd"
	const TERRAIN_CRYSTAL := "res://Gameplay/terrain/crystal.gd"
	const TERRAIN_PLAZA := "res://Gameplay/terrain/plaza.gd"

	# Task/Narrative
	const TASK_CONTROLLER := "res://Gameplay/narrative/task/task_controller.gd"

	# Journal
	const JOURNAL_SECTION := "res://Gameplay/journal/journal_section.gd"
	const JOURNAL_TOPIC := "res://Gameplay/journal/journal_topic.gd"

	# Input commands
	const GAME_COMMAND := "res://Gameplay/input_commands/game_command.gd"
	const COMMAND_RESULT := "res://Gameplay/input_commands/command_result.gd"
	const COMMAND_VALIDATOR := "res://Gameplay/input_commands/command_validator.gd"
	const COMMAND_FACTORY := "res://Gameplay/input_commands/command_factory.gd"
	const GAME_COMMAND_CONTEXT := "res://Gameplay/input_commands/game_command_context.gd"
	const INPUT_COMMAND_ROUTER := "res://Gameplay/input_commands/input_command_router.gd"


# ============================================================================
# DATA DIRECTORIES (For Dir.list_dir_absolute or similar scans)
# ============================================================================

class Directories:
	const ACHIEVEMENTS := "res://Resources/achievements/"
	const LEVEL_DATA := "res://Resources/level_data/"
	const CHARACTERS := "res://Resources/characters/"
	const ROSTERS := "res://Resources/rosters/"
	const CORE_CHARACTERS := "res://Resources/characters/core"
	const LOOT_LISTS := "res://Resources/loot_lists/"
	const GUI := "res://GUI/"
	const MENUS := "res://Menus/"
	const TESTS := "res://tests/"
	const ADDONS := "res://addons/"


# ============================================================================
# USER/CONFIG PATHS (Runtime-generated or user-specific)
# ============================================================================

class UserPaths:
	const SAVE_GAME_CONFIG := "user://hex_config.cfg"
	const SAVE_GAME_FILE := "user://save_game.cfg"
	const ROSTER_SAVE := "user://player_roster.tres"


# ============================================================================
# ADDON/PLUGIN PATHS (Third-party or engine addons)
# ============================================================================

class Addons:
	const GDUNIT4 := "res://addons/gdUnit4/bin/GdUnitCmdTool.gd"
	const DIALOGIC := "res://addons/dialogic/Resources/timeline.gd"
	const HEXAGON_TILEMAPLAYER := "res://addons/hexagon_tilemaplayer/"


# ============================================================================
# TEST PATHS (.gd test files)
# ============================================================================

class Tests:
	const TEST_UTILS := "res://tests/test_utils.gd"
	const TEST_SCENE_TRANSITION_SIGNALS := "res://tests/test_scene_transition_signals.gd"
	const TEST_GAMEPLAY_LEVEL_LOADING := "res://tests/test_gameplay_level_loading.gd"
	const TEST_LEVEL_SELECT_AND_PLAYTHROUGH := "res://tests/test_level_select_and_playthrough.gd"


# ============================================================================
# DYNAMIC PATHS (Generated at runtime - Cannot be fully centralized)
# ============================================================================
##
## ⚠️ WARNING: These paths are constructed dynamically and CANNOT be fully
##	centralized in this file. If you need to refactor directories containing
##	dynamically-built paths, use a search-and-replace and test thoroughly.

class DynamicPaths:
	## Pattern: "res://Resources/level_data/{level_id}/dialogues/{level_id}_{dialogue_id}.dialogue"
	## Generated in: Gameplay/narrative/task/task_controller.gd
	## Also see: json_to_tres.py (builds dialogue files)
	const DIALOGUE_PATH_PATTERN := "res://Resources/level_data/%s/dialogues/%s_%s.dialogue"

	## Pattern: Resource paths from LevelCatalog entries
	## Each level entry in LevelCatalog has its own path
	## Example: "res://Resources/level_data/test_level/levels/test_level.tres"
	const LEVEL_CATALOG_PATTERN := "res://Resources/level_data/%s/levels/%s.tres"


	## Get a dialogue path following the standard pattern
	static func get_dialogue_path(level_id: String, dialogue_id: String) -> String:
		return DIALOGUE_PATH_PATTERN % [level_id, level_id, dialogue_id]


	## Get a level resource path from level ID
	static func get_level_path(level_id: String) -> String:
		return LEVEL_CATALOG_PATTERN % [level_id, level_id]


# ============================================================================
# STATIC HELPER METHODS
# ============================================================================

## Returns the platform-appropriate path separator.
## Note: Godot internal paths (res://, user://) should always use "/".
static func get_path_separator() -> String:
	if OS.get_name() == "Windows":
		return "\\"
	return "/"


## Joins two path segments using Godot's built-in path_join.
## This is the preferred way to construct paths in Godot 4.
static func join_path(base: String, extra: String) -> String:
	return base.path_join(extra)


## Validates that a path exists in the Godot resource system
static func path_exists(path: String) -> bool:
	if path.begins_with("user://"):
		return FileAccess.file_exists(path)
	return ResourceLoader.exists(path)


## Gets all nested class names in this file (for introspection)
static func get_all_categories() -> Array[String]:
	return [
		"Scenes",
		"Autoloads",
		"Resources",
		"Gameplay",
		"Directories",
		"UserPaths",
		"Addons",
		"Tests",
		"DynamicPaths",
	]


## Returns a dictionary of all static paths for debugging/validation
static func get_all_paths() -> Dictionary:
	var paths := {}

	var instance = FilePaths.new()
	# Collect from each category
	for category in get_all_categories():
		var class_ref = instance.get(category)
		if class_ref and typeof(class_ref) == TYPE_OBJECT:
			var props = class_ref.get_property_list()
			for prop in props:
				if prop.name.begins_with("_"):
					continue
				var value = class_ref.get(prop.name)
				if typeof(value) == TYPE_STRING and (value.begins_with("res://") or value.begins_with("user://")):
					paths[category + "." + prop.name] = value

	return paths

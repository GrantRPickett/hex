extends Node
#class_name GameConstants

## Global constants and enums for the HEX project.
## This provides a single source of truth for magic numbers and strings.

# ============================================================================
# COORDINATE CONSTANTS
# ============================================================================

## Used to represent an invalid, uninitialized, or "not set" grid coordinate.
const INVALID_COORD : Vector2i = Vector2i(-999, -999)

## Used to represent an invalid index in an array or collection.
const INVALID_INDEX := -1

## Used for distance calculations where a target is effectively unreachable.
const INFINITY_DISTANCE := 999999


# ============================================================================
# COMMAND & ACTION NAMES
# ============================================================================

class Commands:
	enum CommandID {
		NONE,
		MOVE_ACTION,
		ATTACK,
		AID,
		LOOT,
		CONVINCE,
		TALK,
		WAIT,
		USE_SKILL,
		INTERACT,
		MOVE_TO_COORD,
		CONFIRM_MOVE,
		CANCEL_MOVE,
		VISIT,
		EXPLORE,
		TRAPPED,
		TRIGGER_DIALOGUE,
		UNDO,
		TOGGLE_ENEMY_RANGE,
		TOGGLE_FREE_CAM,
		ZOOM_CAMERA,
		SELECTION_CYCLE,
		SELECT_INDEX,
		PRIMARY_ACTION,
		JOY_MOVE,
		MOVE_AND_INTERACT
	}

	const MOVE_ACTION := "move_action"
	const ATTACK := "attack_unit"
	const AID := "aid_ally"
	const LOOT := "loot"
	const CONVINCE := "convince_unit"
	const TALK := "talk_to_unit"
	const WAIT := "wait"
	const USE_SKILL := "use_skill"
	const INTERACT := "interact"
	const MOVE_TO_COORD := "move_to_coord"
	const CONFIRM_MOVE := "confirm_move"
	const CANCEL_MOVE := "cancel_move"
	const VISIT := "visit"
	const EXPLORE := "explore"
	const TRAPPED := "trapped"
	const TRIGGER_DIALOGUE := "trigger_dialogue"
	const UNDO := "undo"
	const TOGGLE_ENEMY_RANGE := "toggle_enemy_range"
	const TOGGLE_FREE_CAM := "toggle_free_cam"
	const ZOOM_CAMERA := "zoom_camera"
	const SELECTION_CYCLE := "selection_cycle"
	const SELECT_INDEX := "select_index"
	const PRIMARY_ACTION := "primary_action"
	const JOY_MOVE := "joy_move"
	const MOVE_AND_INTERACT_TYPE := "move_and_interact"

# ============================================================================
# INTERACTION TYPES
# ============================================================================
class Interactions:
	const VISIT := "visit"
	const EXPLORE := "explore"
	const ATTACK := "attack"
	const LOOT := "loot"
	const GATHER := "gather"
	const TALK := "talk"
	const CONVINCE := "convince"
	const AID := "aid"
	const SKILL := "skill"
	const TRAPPED := "trapped"
	const INTERACT := "interact"

class ActionIds:
	const LOCATION_OPPOSED := &"location_opposed"
	const LOCATION_UNOPPOSED := &"location_unopposed"
	const UNIT_OPPOSED := &"unit_opposed"
	const UNIT_UNOPPOSED := &"unit_unopposed"
	const ITEM_OPPOSED := &"item_opposed"
	const ITEM_UNOPPOSED := &"item_unopposed"
	const WAIT := &"wait"
	const MOVE := &"move"
	const SKILL := &"skill"
	const MOVE_AND_INTERACT := &"action_move_and_interact"


# ============================================================================
# COMBAT CONSTANTS
# ============================================================================

class Combat:
	## Number of attribute pairs (Body, Mind, Spirit)
	const PAIR_COUNT := 3
	## Weights for defense calculation: 0.34 * min(pair) + 0.66 * max(pair)
	const DEFENSE_MIN_WEIGHT := 0.34
	const DEFENSE_MAX_WEIGHT := 0.66


# ============================================================================
# UNIT ATTRIBUTES & WEATHER PRESSURES
# ============================================================================

class Attributes:
	enum AttributeIndex {
		GRIT = 0,
		FLOW = 1,
		GUSTO = 2,
		FOCUS = 3,
		SHINE = 4,
		SHADE = 5,
		WILLPOWER = 6
	}

	static func get_attribute_name(idx: AttributeIndex) -> String:
		match idx:
			AttributeIndex.GRIT: return GRIT
			AttributeIndex.FLOW: return FLOW
			AttributeIndex.GUSTO: return GUSTO
			AttributeIndex.FOCUS: return FOCUS
			AttributeIndex.SHINE: return SHINE
			AttributeIndex.SHADE: return SHADE
			AttributeIndex.WILLPOWER: return WILLPOWER
		return ""

	static func get_attribute_index(name: String) -> AttributeIndex:
		var lower_name = name.to_lower()
		match lower_name:
			GRIT: return AttributeIndex.GRIT
			FLOW: return AttributeIndex.FLOW
			GUSTO: return AttributeIndex.GUSTO
			FOCUS: return AttributeIndex.FOCUS
			SHINE: return AttributeIndex.SHINE
			SHADE: return AttributeIndex.SHADE
			WILLPOWER: return AttributeIndex.WILLPOWER
		return AttributeIndex.GRIT # Fallback

	const GRIT := "grit"
	const FLOW := "flow"
	const GUSTO := "gusto"
	const FOCUS := "focus"
	const SHINE := "shine"
	const SHADE := "shade"
	const WILLPOWER := "willpower"

	const COMBAT_ATTRIBUTES: Array[String] = [GRIT, FLOW, GUSTO, FOCUS, SHINE, SHADE]
	const ALL_ATTRIBUTES: Array[String] = [GRIT, FLOW, GUSTO, FOCUS, SHINE, SHADE, WILLPOWER] # Array concatenation in const not supported in all Godot 4 versions, keeping literal but as a subset
	const PRESSURE_TYPES: Array[String] = [SHINE, SHADE, FLOW, GRIT, GUSTO, FOCUS]

	const OPPOSITES := {
		SHINE: SHADE,
		SHADE: SHINE,
		FLOW: GRIT,
		GRIT: FLOW,
		GUSTO: FOCUS,
		FOCUS: GUSTO
	}

	const ATTRIBUTE_COLORS := {
		SHINE: Color(0.835, 0.369, 0.0),	# Vermillion (#D55E00) - Red variant
		SHADE: Color(0.337, 0.706, 0.914),  # Sky Blue (#56B4E9) - Cyan variant
		FOCUS: Color(0.8, 0.475, 0.655),	# Reddish Purple (#CC79A7) - Purple variant
		GRIT: Color(0.902, 0.624, 0.0),	 # Orange (#E69F00) - Orange variant
		FLOW: Color(0.0, 0.447, 0.698),	 # Blue (#0072B2) - Blue variant
		GUSTO: Color(0.0, 0.62, 0.451)	  # Bluish Green (#009E73) - Green variant
	}

	static func colorize_attributes(text: String) -> String:
		var result = text
		for attr in COMBAT_ATTRIBUTES:
			var color = ATTRIBUTE_COLORS.get(attr, Color.WHITE)
			var hex = color.to_html(false)
			# Find matches in both lowercase and capitalized form
			var attr_name = attr.capitalize()
			var lower_name = attr.to_lower()

			# Replace Capitalized first (regex-like logic but simple replace)
			result = result.replace(attr_name, "[color=#%s]%s[/color]" % [hex, attr_name])
			result = result.replace(lower_name, "[color=#%s]%s[/color]" % [hex, lower_name])
		return result


# ============================================================================
# WEATHER NAMES
# ============================================================================

class Weather:
	# Basic conditions (Primary mapped)
	const SUNNY := "Sunny"
	const CLOUDY := "Cloudy"
	const RAINY := "Rainy"
	const ARID := "Arid"
	const WINDY := "Windy"
	const CALM := "Calm"
	const TEMPERATE := "Temperate"

	# Hard mode Combos
	const PARCHED := "Parched"
	const MUGGY := "Muggy"
	const OVERCAST := "Overcast"
	const DRIZZLE := "Drizzle"
	const HOT_WINDS := "Hot Winds"
	const COLD_WINDS := "Cold Winds"
	const STORM_WINDS := "Storm Winds"
	const DUST_STORM := "Dust Storm"


# ============================================================================
# TASK & NARRATIVE
# ============================================================================

class Tasks:
	const KIND_NONE := &"none"
	const KIND_UNIT := &"unit"
	const KIND_LOCATION := &"location"
	const KIND_ITEM := &"item"

	const DURATION_CUMULATIVE := &"cumulative"
	const DURATION_CONSECUTIVE := &"consecutive"

	const CONDITION_DEFEAT_ALL := "DEFEAT_ALL_UNITS_OF_FACTION"

class Loyalty:
	enum Type {
		PLAYER,
		ENEMY,
		NEUTRAL,
		STATIC
	}


class TaskEvents:
	const INTERACT := "interact"
	const VISIT := "visit"
	const EXPLORE := "explore"
	const MOVE := "move"
	const LOOT := "loot"
	const TRAPPED := "trapped"
	const ATTACK := "attack"
	const CONVINCE := "convince"
	const ABILITY_USED := "ability_used"
	const DIALOGUE_STARTED := "dialogue_started"
	const DIALOGUE_FINISHED := "dialogue_finished"
	const UNIT_DEFEATED := "unit_defeated"
	const ROUND_CHANGED := "round_changed"
	const EXPLORE_ZONE := "explore_zone"
	const ELIMINATE := "eliminate"
	const COUNTDOWN := "countdown"


# ============================================================================
# AI & DECISION MAKING
# ============================================================================

class AI:
	# Action Types
	const ACTION_ATTACK := &"attack"
	const ACTION_TALK := &"talk"
	const ACTION_LOOT := &"loot"
	const ACTION_CONVINCE := &"convince"
	const ACTION_EXPLORE := &"explore"
	const ACTION_VISIT := &"visit"
	const ACTION_AID_ALLY := &"aid_ally"
	const ACTION_MOVE_TO_ENEMY := &"move_to_enemy"
	const ACTION_MOVE_TO_TALK := &"move_to_talk"
	const ACTION_MOVE_TO_LOOT := &"move_to_loot"
	const ACTION_MOVE_TO_TASK := &"move_to_task"
	const ACTION_MOVE_TO_CONVINCE := &"move_to_convince"
	const ACTION_MOVE_TO_CENTER := &"move_to_center"

	# Standardized Multipliers (used with CombatPriorityProfile weights)
	const MULTIPLIER_TALK := 22.0
	const MULTIPLIER_ATTACK := 10.0
	const MULTIPLIER_TASK := 16.0
	const MULTIPLIER_LOOT := 14.0
	const MULTIPLIER_CONVINCE := 12.0
	const MULTIPLIER_AID_ALLY := 5.0

	# Move-Toward Multipliers
	const MULTIPLIER_MOVE_TO_TALK := 12.0
	const MULTIPLIER_MOVE_TO_TASK := 4.0
	const MULTIPLIER_MOVE_TO_LOOT := 2.0
	const MULTIPLIER_MOVE_TO_ENEMY := 5.0
	const MULTIPLIER_MOVE_TO_CONVINCE := 6.0

	# Interaction Role Weights
	const WEIGHT_OPPOSED := 0.85
	const WEIGHT_UNOPPOSED := 1.0

	# Scoring Ratios
	const RATIO_MOVE_TO_TARGET := 0.5
	const RATIO_FALLBACK_ACTION := 0.1

	# Base Scores (fallbacks if no profile exists)
	const SCORE_ATTACK_BASE := 100.0
	const SCORE_TALK_BASE := 115.0
	const SCORE_TASK_BASE := 85.0
	const SCORE_CONVINCE_BASE := 80.0
	const SCORE_LOOT_BASE := 75.0
	const SCORE_AID_ALLY_BASE := 20.0

	# Movement scores
	const SCORE_MOVE_TO_TALK_BASE := 35.0
	const SCORE_MOVE_TO_ENEMY := 50.0
	const SCORE_MOVE_TO_TASK := 25.0
	const SCORE_MOVE_TO_LOOT := 15.0
	const SCORE_MOVE_TO_CENTER := 5.0

	# Modifiers
	const THREAT_PENALTY := 15.0
	const SCORE_MORALE_ADJUSTMENT_MAX := 20.0

	const DIALOGUE_PRIORITY_BONUS := 50.0
	const GRID_ADJACENCY_THRESHOLD := 1.5


class Difficulty:
	const AI_SCALE_EASY := 0.5
	const AI_SCALE_NORMAL := 1.0
	const AI_SCALE_HARD := 2.0

	const AI_MORALE_WEIGHT_EASY := 1.0
	const AI_MORALE_WEIGHT_NORMAL := 0.5
	const AI_MORALE_WEIGHT_HARD := 0.0

	const RETREAT_THRESHOLD_EASY := 0.1
	const RETREAT_THRESHOLD_NORMAL := 0.2
	const RETREAT_THRESHOLD_HARD := 0.3

	const COMBAT_MODIFIER_EASY := 0.8
	const COMBAT_MODIFIER_NORMAL := 1.0
	const COMBAT_MODIFIER_HARD := 1.2

	const DEBUG_STAT_BOOST := 100


# ============================================================================
# ANIMATION & UI DELAYS
# ============================================================================

class UI:
	const DEFAULT_TWEEN_DURATION := 0.3
	const DEFEAT_RETURN_DELAY := 2.0
	const CREDITS_RETURN_DELAY := 10.0
	const AI_THINK_DELAY := 0.5
	const AI_ACTION_DELAY := 0.2

	# Dialogue specific timings
	const DIALOGUE_DEFAULT_AUTO_DELAY := 2.0
	const DIALOGUE_DEFAULT_TEXT_SPEED := 1.0
	const DIALOGUE_BASE_TEXT_STEP := 0.02
	const DIALOGUE_MIN_SPEED_MULTIPLIER := 0.1

	# HUD Tab Names
	const TAB_LOCATIONS := "locations"
	const TAB_TASKS := "tasks"
	const TAB_UNIT := "unit"

	# Pause Menu Layouts
	const PAUSE_ANCHOR_PORTRAIT_LEFT := 0.05
	const PAUSE_ANCHOR_PORTRAIT_RIGHT := 0.95
	const PAUSE_ANCHOR_PORTRAIT_TOP := 0.1
	const PAUSE_ANCHOR_PORTRAIT_BOTTOM := 0.9
	
	const PAUSE_ANCHOR_LANDSCAPE_LEFT := 0.15
	const PAUSE_ANCHOR_LANDSCAPE_RIGHT := 0.85
	const PAUSE_ANCHOR_LANDSCAPE_TOP := 0.15
	const PAUSE_ANCHOR_LANDSCAPE_BOTTOM := 0.85

class Inventory:
	const ACTION_MINUS := "minus"
	const ACTION_HAND := "hand"
	const ACTION_EQUIP := "equip"
	
	const STASH_SIZE_PORTRAIT := Vector2(1200, 80)
	const STASH_SIZE_LANDSCAPE := Vector2(300, 800)
	const STASH_ITEM_WIDTH_LANDSCAPE := 250.0


# ============================================================================
# SETTINGS & CONFIGURATION
# ============================================================================

class Settings:
	const DIFFICULTY_EASY := "easy"
	const DIFFICULTY_NORMAL := "normal"
	const DIFFICULTY_HARD := "hard"

	const ANIMATION_SPEED_SLOW := "slow"
	const ANIMATION_SPEED_NORMAL := "normal"
	const ANIMATION_SPEED_FAST := "fast"
	const ANIMATION_SPEED_SKIP := "skip"

	const ORIENTATION_LANDSCAPE := "landscape"
	const ORIENTATION_PORTRAIT := "portrait"

	# Setting Paths (matches GameConfig.Paths)
	const LANGUAGE := "display/language"
	const DIALOGUE_AUTO_ADVANCE := "dialogue/auto_advance_enabled"
	const DIALOGUE_AUTO_SPEED := "dialogue/auto_advance_speed"
	const DIALOGUE_TEXT_SPEED := "dialogue/text_speed"

	# Audio Settings Paths
	const AUDIO_MASTER_VOLUME := "audio/master_db"
	const AUDIO_MUSIC_VOLUME := "audio/music_db"
	const AUDIO_SFX_VOLUME := "audio/sfx_db"
	const AUDIO_UI_VOLUME := "audio/ui_db"
	const AUDIO_ENVIRONMENT_VOLUME := "audio/environment_db"
	const AUDIO_NARRATIVE_VOLUME := "audio/narrative_db"

	const AUDIO_MASTER_MUTED := "audio/master_muted"
	const AUDIO_MUSIC_MUTED := "audio/music_muted"
	const AUDIO_SFX_MUTED := "audio/sfx_muted"
	const AUDIO_UI_MUTED := "audio/ui_muted"
	const AUDIO_ENVIRONMENT_MUTED := "audio/environment_muted"
	const AUDIO_NARRATIVE_MUTED := "audio/narrative_muted"


# ============================================================================
# COMMAND CONTEXT & PAYLOAD KEYS
# ============================================================================

class Context:
	const UNIT_MANAGER := "unit_manager"
	const TURN_CONTROLLER := "turn_controller"
	const MOVE_CONTROLLER := "move_controller"
	const TASK_CONTROLLER := "task_controller"
	const GRID := "grid"
	const GRID_VISUALS := "grid_visuals"
	const TERRAIN_MAP := "terrain_map"
	const HEX_NAVIGATOR := "hex_navigator"
	const CAMERA_CONTROLLER := "camera_controller"
	const BINDING_SERVICE := "binding_service"
	const DIALOGUE_ACTION_SERVICE := "dialogue_action_service"
	const LOOT_MANAGER := "loot_manager"

class Payload:
	const COMMAND := "command"
	const PAYLOAD := "payload"
	const RESULT := "result"
	const ACTION := "action"

	const ATTACKER_INDEX := "attacker_index"
	const TARGET_INDEX := "target_index"
	const HELPER_INDEX := "helper_index"
	const INITIATOR_INDEX := "initiator_index"
	const LOOTER_INDEX := "looter_index"
	const WORKER_INDEX := "worker_index"
	const UNIT_INDEX := "unit_index"

	const TARGET := "target"
	const TASK_ID := "task_id"
	const COORD := "coord"
	const TARGET_COORD := "target_coord"
	const LOOT_COORD := "loot_coord"
	const AXIS := "axis"
	const SKILL := "skill"
	const ATTRIBUTE_INDEX := "attribute_index"
	const DIALOGUE_ID := "dialogue_id"
	const DIALOGUE_RESOURCE_PATH := "dialogue_resource_path"
	const START_TITLE := "start_title"


# ============================================================================
# FACTION NAMES (Helper)
# ============================================================================
# Note: Faction enum is defined in Unit.gd

static func get_faction_name(faction: int) -> String:
	if LevelManager.current_level:
		match faction:
			Unit.Faction.PLAYER: return LevelManager.current_level.player_faction_name
			Unit.Faction.ENEMY: return LevelManager.current_level.enemy_faction_name
			Unit.Faction.NEUTRAL: return LevelManager.current_level.neutral_faction_name

	match faction:
		Unit.Faction.PLAYER: return "Player"
		Unit.Faction.ENEMY: return "Enemy"
		Unit.Faction.NEUTRAL: return "Neutral"
		_: return "Unknown"

# ============================================================================
# COLORS
# ============================================================================

class Colors:
	# General UI
	const WHITE_TRANSPARENT := Color(1, 1, 1, 0)
	const WHITE_SEMI_TRANSPARENT := Color(1, 1, 1, 0.6)
	const WHITE_MOSTLY_OPAQUE := Color(1, 1, 1, 0.9)
	const WARNING := Color(1, 0.2, 0.2)
	const HINT_TEXT := Color(1, 1, 0.8)
	const UI_WHITE := Color.WHITE
	const UI_BLACK := Color.BLACK
	const UI_GRAY := Color.GRAY
	const UI_CYAN := Color.CYAN

	# Game State Colors
	const WILLPOWER_LOW := Color.ORANGE_RED
	const WILLPOWER_MID := Color.YELLOW
	const WILLPOWER_NORMAL := Color.WHITE
	const MOVES_DEPLETED := Color.RED
	const MOVES_NORMAL := Color.WHITE
	
	const FACTION_PLAYER := Color.GREEN
	const FACTION_ENEMY := Color.RED
	const FACTION_NEUTRAL := Color.YELLOW
	const FACTION_NEUTRAL_ALT := Color.GOLD

	# Tasks & Objectives
	const TASK_COMPLETED_TEXT := Color(0.5, 0.5, 0.5) # Grey out completed tasks
	const TASK_FACTION_HEADER := Color(0.8, 0.8, 0.2) # Yellowish for faction headers
	const TASK_LOCATION_TEXT := Color(0.8, 1.0, 0.8) # Light green
	const TASK_OBJECTIVE_FADE := Color(0, 0, 0, 0)

	# Inventory & Menus
	const INV_BG := Color(0.2, 0.5, 0.3, 1.0)
	const INV_HELP_TEXT := Color(0.8, 0.8, 0.4)
	const INV_SLOT_BG := Color(0.3, 0.5, 0.8, 0.4)
	const INV_CHAR_PANEL_BG := Color(0.2, 0.4, 0.6, 0.5)
	const INV_ITEM_EQUIPPED := Color.GREEN
	const INV_ITEM_UNEQUIPPED := Color.WHITE
	const INV_CAPACITY_FULL := Color.GOLD
	const INV_CAPACITY_NORMAL := Color(0.7, 0.7, 0.7)
	const INV_HIGHLIGHT := Color.CYAN
	const INV_DEBUG_BG := Color(0.6, 0.2, 0.2, 1.0)

	# Grid Overview (Accessibility Focused)
	const GRID_HOVER := Color(1.0, 1.0, 1.0, 0.25)
	const GRID_PATH_LINE := Color(1.0, 1.0, 1.0, 0.7)
	const GRID_THREATENED_PATH := Color(1.0, 0.1, 0.1, 0.8)
	const GRID_RANGE_PLAYER := Color(0.2, 0.6, 1.0, 0.3)
	const GRID_RANGE_ENEMY := Color(1.0, 0.3, 0.3, 0.3)
	const GRID_RANGE_TENTATIVE := Color(1.0, 1.0, 0.0, 0.5)
	const GRID_AOO_THREAT := Color(1.0, 0.5, 0.0, 0.5)
	const GRID_ENEMY_RANGE_FULL := Color(1.0, 0.0, 0.0, 0.2)
	const GRID_DIALOGUE_INDICATOR := Color(1.0, 0.85, 0.0, 0.6)


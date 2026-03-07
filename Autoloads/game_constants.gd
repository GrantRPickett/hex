extends Node

## Global constants and enums for the HEX project.
## This autoload provides a single source of truth for magic numbers and strings.

# ============================================================================
# COORDINATE CONSTANTS
# ============================================================================

## Used to represent an invalid, uninitialized, or "not set" grid coordinate.
const INVALID_COORD := Vector2i(-999, -999)

## Used to represent an invalid index in an array or collection.
const INVALID_INDEX := -1

## Used for distance calculations where a target is effectively unreachable.
const INFINITY_DISTANCE := 999999


# ============================================================================
# COMMAND & ACTION NAMES
# ============================================================================

class Commands:
	const MOVE_ACTION := &"move_action"
	const ATTACK := &"attack_unit"
	const AID := &"aid_ally"
	const LOOT := &"loot"
	const CONVINCE := &"convince_unit"
	const TALK := &"talk_to_unit"
	const WAIT := &"wait"
	const USE_SKILL := &"use_skill"
	const INTERACT := &"interact"
	const MOVE_TO_COORD := &"move_to_coord"
	const CONFIRM_MOVE := &"confirm_move"
	const CANCEL_MOVE := &"cancel_move"
	const VISIT := &"visit"
	const EXPLORE := &"explore"
	const TRAPPED := &"trapped"
	const TRIGGER_DIALOGUE := &"trigger_dialogue"
	const UNDO := &"undo"
	const TOGGLE_ENEMY_RANGE := &"toggle_enemy_range"
	const TOGGLE_FREE_CAM := &"toggle_free_cam"
	const ZOOM_CAMERA := &"zoom_camera"
	const SELECTION_CYCLE := &"selection_cycle"
	const SELECT_INDEX := &"select_index"
	const PRIMARY_ACTION := &"primary_action"
	const JOY_MOVE := &"joy_move"
	const MOVE_AND_INTERACT_TYPE := &"move_and_interact"


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
	## Weights for defense calculation: 0.34 * min(pair) + 0.66 * max(pair)
	const DEFENSE_MIN_WEIGHT := 0.34
	const DEFENSE_MAX_WEIGHT := 0.66


# ============================================================================
# UNIT ATTRIBUTES & WEATHER PRESSURES
# ============================================================================

class Attributes:
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


# ============================================================================
# WEATHER NAMES
# ============================================================================

class Weather:
	const PARCHED := "Parched"
	const MUGGY := "Muggy"
	const OVERCAST := "Overcast"
	const DRIZZLE := "Drizzle"
	const HOT_WINDS := "Hot Winds"
	const COLD_WINDS := "Cold Winds"
	const STORM_WINDS := "Storm Winds"
	const DUST_STORM := "Dust Storm"
	const CALM := "Calm"
	const TEMPERATE := "Temperate"
	const SUNNY := "Sunny"
	const CLOUDY := "Cloudy"
	const RAINY := "Rainy"
	const ARID := "Arid"
	const WINDY := "Windy"


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
	const TARGET_INTERACTION := "target_interaction" # Deprecated: use specific types
	const VISIT := "visit"
	const EXPLORE := "explore"
	const MOVE := "move"
	const PICKUP := "pickup" # Legacy for LOOT
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
	const MULTIPLIER_AID_ALLY := 10.0

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
	const SCORE_AID_ALLY_BASE := 65.0

	# Movement scores
	const SCORE_MOVE_TO_TALK_BASE := 35.0
	const SCORE_MOVE_TO_ENEMY := 50.0
	const SCORE_MOVE_TO_TASK := 25.0
	const SCORE_MOVE_TO_LOOT := 15.0
	const SCORE_MOVE_TO_CENTER := 5.0

	# Penalties & Bonuses
	const THREAT_PENALTY := 15.0
	const DIALOGUE_PRIORITY_BONUS := 50.0
	const GRID_ADJACENCY_THRESHOLD := 1.5


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

	const ORIENTATION_LANDSCAPE := "landscape"
	const ORIENTATION_PORTRAIT := "portrait"

	# Setting Paths (matches GameConfig.Paths)
	const LANGUAGE := "display/language"
	const DIALOGUE_AUTO_ADVANCE := "dialogue/auto_advance_enabled"
	const DIALOGUE_AUTO_SPEED := "dialogue/auto_advance_speed"
	const DIALOGUE_TEXT_SPEED := "dialogue/text_speed"


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
	match faction:
		0: return "Player"
		1: return "Enemy"
		2: return "Neutral"
		_: return "Unknown"

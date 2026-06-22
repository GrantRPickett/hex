extends Node
#class_name GameConstants


## Global constants and enums for the HEX project.
## This provides a single source of truth for magic numbers and strings.

static var debug_enemy_movement_enabled: bool = true
static var debug_neutral_movement_enabled: bool = true

# ============================================================================
# COORDINATE CONSTANTS
# ============================================================================

## Used to represent an invalid, uninitialized, or "not set" grid coordinate.
const INVALID_COORD: Vector2i = Vector2i(-999, -999)

## Used to represent an invalid index in an array or collection.
const INVALID_INDEX: int = -1

## Sentinel value for unreachable/infinite distance in pathfinding and range checks.
const INFINITY_DISTANCE: int = 999999

## Used for distance calculations where a target is effectively unreachable.
const TRES_EXTENSION := ".tres"


## If true, AI verbose logs are suppressed to improve performance.
const SILENT_LOGS := false

# ============================================================================
# GRID AND GEOMETRY CONSTANTS
# ============================================================================

const TILE_SIZE := Vector2i(64, 64)
const TARGET_RADIUS := 32.0
const PATH_WIDTH := 4.0

enum ZIndex {
	ENEMY_RANGE = 1,
	TERRAIN = 2,
	PATH_LINE = 5,
	THREATENED_PATH = 5,
	LOCATION = 10,
	LOOT = 15,
	UNIT = 20,
	RANGE_INDICATOR = 25,
	AOO_THREAT = 26,
	DIALOGUE_INDICATOR = 27,
	HOVER = 30
}

class OverlayScale:
	const RANGE: float = 0.9
	const THREAT: float = 0.8
	const DIALOGUE: float = 0.95


# ============================================================================
# FACTIONS
# ============================================================================

enum Faction {
	PLAYER,
	ENEMY,
	NEUTRAL,
	STATIC
}

# ============================================================================
# ACTION TYPES (Shared by AI and PlayerAction)
# ============================================================================

enum ActionType {
	NONE,
	# Input / Meta
	UNDO,
	REDO,
	SELECTION_CYCLE,
	SELECT_INDEX,
	TOGGLE_FREE_CAM,
	TOGGLE_ENEMY_RANGE,
	ZOOM_CAMERA,
	JOY_MOVE,
	PRIMARY_ACTION,

	# Movement
	MOVE,
	MOVE_TO_COORD,
	CONFIRM_MOVE,
	CANCEL_MOVE,
	# Core Gameplay Actions
	WAIT,
	AID,
	SKILL,
	INTERACT,
	MOVE_AND_INTERACT,
	OPEN_ATTACK_MENU,

	# Specific Activity Types
	FIGHT,
	GATHER,
	VISIT,
	EXPLORE,
	TRAPPED,
	CONVINCE,

	# Internal / Contextual / AI
	TRIGGER_DIALOGUE,
	MOVE_TO_FIGHT,
	MOVE_TO_GATHER,
	MOVE_TO_TRAPPED,
	MOVE_TO_EXPLORE,
	MOVE_TO_VISIT,
	MOVE_TO_CONVINCE,
	MOVE_TO_CENTER
}

func get_activity_from_type(type: ActionType) -> String:
	match type:
		ActionType.FIGHT, ActionType.MOVE_TO_FIGHT:
			return Activity.FIGHT
		ActionType.AID:
			return Activity.AID
		ActionType.VISIT, ActionType.MOVE_TO_VISIT:
			return Activity.VISIT
		ActionType.EXPLORE, ActionType.MOVE_TO_EXPLORE:
			return Activity.EXPLORE
		ActionType.TRAPPED, ActionType.MOVE_TO_TRAPPED:
			return Activity.TRAPPED
		ActionType.CONVINCE, ActionType.MOVE_TO_CONVINCE:
			return Activity.CONVINCE
		ActionType.GATHER, ActionType.MOVE_TO_GATHER:
			return Activity.GATHER
		ActionType.SKILL:
			return Activity.SKILL
		ActionType.WAIT:
			return Activity.WAIT
		ActionType.MOVE:
			return Activity.MOVE
		ActionType.MOVE_AND_INTERACT:
			return Activity.INTERACT
		_:
			return ""

# Legacy helper
func get_interaction_from_type(type: ActionType) -> String:
	return get_activity_from_type(type)
# ================= ===========================================================
# TURN SIDES
# ============================================================================

enum Side {
	PLAYER,
	ENEMY,
	NEUTRAL
}

# ============================================================================
# COMMAND & ACTION NAMES
# ============================================================================

class Commands:
	# Core Strings (Shared with Activity)
	const FIGHT := Activity.FIGHT
	const AID := Activity.AID
	const GATHER := Activity.GATHER
	const CONVINCE := Activity.CONVINCE
	const VISIT := Activity.VISIT
	const EXPLORE := Activity.EXPLORE
	const TRAPPED := Activity.TRAPPED
	const INTERACT := Activity.INTERACT
	const SKILL := Activity.SKILL

	const MOVE_ACTION: String = Activity.MOVE
	const WAIT: String = Activity.WAIT
	const MOVE_TO_COORD: String = "move_to_coord"
	const CONFIRM_MOVE: String = "confirm_move"
	const CANCEL_MOVE: String = "cancel_move"
	const TRIGGER_DIALOGUE: String = "trigger_dialogue"
	const UNDO: String = "undo"
	const TOGGLE_ENEMY_RANGE: String = "toggle_enemy_range"
	const TOGGLE_FREE_CAM: String = "toggle_free_cam"
	const ZOOM_CAMERA: String = "zoom_camera"
	const SELECTION_CYCLE: String = "selection_cycle"
	const SELECT_INDEX: String = "select_index"
	const PRIMARY_ACTION: String = "primary_action"
	const JOY_MOVE := "joy_move"
	const MOVE_AND_INTERACT_TYPE := "move_and_interact"

class Activity:
	# Core Interactions & Events
	const FIGHT := "fight"
	const AOO := "aoo"
	const GATHER := "gather"
	const VISIT := "visit"
	const EXPLORE := "explore"
	const TRAPPED := "trapped"
	const CONVINCE := "convince"
	const AID := "aid"
	const SKILL := "skill"
	const INTERACT := "interact"
	const MOVE := "move"
	const WAIT := "wait"

	# Narrative Events
	const ABILITY_USED := "ability_used"
	const DIALOGUE_STARTED := "dialogue_started"
	const DIALOGUE_FINISHED := "dialogue_finished"
	const UNIT_DEFEATED := "unit_defeated"
	const ROUND_CHANGED := "round_changed"
	const EXPLORE_ZONE := "explore_zone"
	const ELIMINATE := "eliminate"
	const COUNTDOWN := "countdown"

	# Task Kinds
	const KIND_UNIT := &"unit"
	const KIND_LOCATION := &"location"
	const KIND_ITEM := &"item"
	const KIND_NONE := &"none"

# ============================================================================
# INPUT MODES
# ============================================================================
enum InputModes {
	MENU,
	MAP_FREE_CAM,
	UNIT_ACTION,
	DIALOGUE,
	INVENTORY
}
# ============================================================================
# Interactions class removed in favor of Activity

func get_task_event_for_interaction(interaction: String) -> String:
	var lower = interaction.to_lower()
	match lower:
		Activity.AID: return Activity.ABILITY_USED
		_: return lower

class ActionIds:
	const LOCATION_OPPOSED := Activity.EXPLORE
	const LOCATION_UNOPPOSED := Activity.VISIT
	const UNIT_OPPOSED := Activity.FIGHT
	const UNIT_UNOPPOSED := Activity.CONVINCE
	const ITEM_OPPOSED := Activity.TRAPPED
	const ITEM_UNOPPOSED := Activity.GATHER
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
	## The three combat attribute pairs: [attacker_attr, defender_attr]
	const COMBAT_ATTRIBUTE_PAIRS: Array = [
		[AttributeIndex.GRIT, AttributeIndex.FLOW],
		[AttributeIndex.GUSTO, AttributeIndex.FOCUS],
		[AttributeIndex.SHINE, AttributeIndex.SHADE]
	]

	enum AttackQuality {INEFFECTIVE, IDLE, RISKY, PROGRESS, SUCCESS}


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

enum AttributeIndex {
	GRIT = 0,
	FLOW = 1,
	GUSTO = 2,
	FOCUS = 3,
	SHINE = 4,
	SHADE = 5,
}

func get_attribute_name(idx: AttributeIndex) -> String:
	match idx:
		AttributeIndex.GRIT: return Attributes.GRIT
		AttributeIndex.FLOW: return Attributes.FLOW
		AttributeIndex.GUSTO: return Attributes.GUSTO
		AttributeIndex.FOCUS: return Attributes.FOCUS
		AttributeIndex.SHINE: return Attributes.SHINE
		AttributeIndex.SHADE: return Attributes.SHADE
	return ""

func get_attribute_index(attr_name: String) -> AttributeIndex:
	match attr_name.to_lower():
		Attributes.GRIT: return AttributeIndex.GRIT
		Attributes.FLOW: return AttributeIndex.FLOW
		Attributes.GUSTO: return AttributeIndex.GUSTO
		Attributes.FOCUS: return AttributeIndex.FOCUS
		Attributes.SHINE: return AttributeIndex.SHINE
		Attributes.SHADE: return AttributeIndex.SHADE
	return AttributeIndex.GRIT # Fallback

const COMBAT_ATTRIBUTE_INDICES: Array[AttributeIndex] = [
	AttributeIndex.GRIT,
	AttributeIndex.FLOW,
	AttributeIndex.GUSTO,
	AttributeIndex.FOCUS,
	AttributeIndex.SHINE,
	AttributeIndex.SHADE
]

const ALL_ATTRIBUTE_INDICES: Array[AttributeIndex] = [
	AttributeIndex.GRIT,
	AttributeIndex.FLOW,
	AttributeIndex.GUSTO,
	AttributeIndex.FOCUS,
	AttributeIndex.SHINE,
	AttributeIndex.SHADE,
]

const PRESSURE_TYPES: Array[AttributeIndex] = [
	AttributeIndex.GRIT,
	AttributeIndex.FLOW,
	AttributeIndex.GUSTO,
	AttributeIndex.FOCUS,
	AttributeIndex.SHINE,
	AttributeIndex.SHADE
]


# Attribute colors migrated to GameColors

const ATTRIBUTE_OPPOSITES: Dictionary = {
	AttributeIndex.SHINE: AttributeIndex.SHADE,
	AttributeIndex.SHADE: AttributeIndex.SHINE,
	AttributeIndex.FLOW: AttributeIndex.GRIT,
	AttributeIndex.GRIT: AttributeIndex.FLOW,
	AttributeIndex.GUSTO: AttributeIndex.FOCUS,
	AttributeIndex.FOCUS: AttributeIndex.GUSTO
}

func get_attribute_color(idx: AttributeIndex) -> Color:
	return GameColors.get_attribute_color(int(idx))

func get_attribute_opposite(idx: AttributeIndex) -> AttributeIndex:
	return ATTRIBUTE_OPPOSITES.get(idx, idx)

func get_opposite_name(attr_name: String) -> String:
	var idx: AttributeIndex = get_attribute_index(attr_name)
	var opp_idx: AttributeIndex = get_attribute_opposite(idx)
	return get_attribute_name(opp_idx)

func get_attribute_value(dict: Dictionary, idx: AttributeIndex, default: int = 0) -> int:
	if dict.is_empty(): return default
	# Priority: 1. Enum Key, 2. String Key
	if dict.has(idx): return int(dict[idx])
	var attr_name: String = get_attribute_name(idx)
	if dict.has(attr_name): return int(dict[attr_name])
	return default

func colorize_attributes(text: String) -> String:
	return GameColors.colorize_attributes(text)


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
	const KIND_NONE := Activity.KIND_NONE
	const KIND_UNIT := Activity.KIND_UNIT
	const KIND_LOCATION := Activity.KIND_LOCATION
	const KIND_ITEM := Activity.KIND_ITEM

	const DURATION_CUMULATIVE := &"cumulative"
	const DURATION_CONSECUTIVE := &"consecutive"

	const CONDITION_DEFEAT_ALL := "DEFEAT_ALL_UNITS_OF_FACTION"


# TaskEvents class removed in favor of Activity


class Journal:
	const SECTION_OBJECTIVES := "objectives"
	const SECTION_PEOPLE := "people"
	const SECTION_PLACES := "places"
	const SECTION_RULES := "rules"
	const SECTION_ACHIEVEMENTS := "achievements"

	const STATUS_ACTIVE := "active"
	const STATUS_COMPLETED := "completed"

	const ENTRY_TYPE_OBJECTIVE := "objective"
	const ENTRY_TYPE_STAGE := "stage"


class Anim:
	const TYPE_MOVE := "move"
	const TYPE_ATTACK := "attack"
	const TYPE_LOOT := "loot"
	const TYPE_INTERACT := "interact"


class Audio:
	# Bus Names
	const BUS_SFX := "SFX"
	const BUS_UI := "UI"
	const BUS_ENVIRONMENT := "Environment"
	const BUS_NARRATIVE := "Narrative"

	# Sound IDs
	const SFX_UNIT_ATTACK := "unit_attack"
	const SFX_UNIT_DAMAGE := "unit_damage"
	const SFX_UNIT_DEATH := "unit_death"
	const SFX_UNIT_MOVE := "unit_move"
	const SFX_LOOT_COLLECT := "loot_collect"
	const SFX_MORALE_CRITICAL_UNIT := "morale_critical_unit"
	const SFX_MORALE_CRITICAL_FACTION := "morale_critical_faction"

	const SFX_TURN_CHANGE := "turn_change"
	const SFX_ROUND_CHANGE := "round_change"
	const SFX_OBJECTIVE_START := "objective_start"
	const SFX_OBJECTIVE_COMPLETE := "objective_complete"
	const SFX_OBJECTIVE_FAIL := "objective_fail"
	const SFX_TASK_COMPLETE := "task_complete"
	const SFX_TASK_FAIL := "task_fail"
	const SFX_STAGE_COMPLETE := "stage_complete"
	const SFX_LEVEL_START := "level_start"
	const SFX_LEVEL_COMPLETE := "level_complete"
	const SFX_LEVEL_FAIL := "level_fail"
	const SFX_ITEM_EQUIP := "item_equip"
	const SFX_ITEM_UNEQUIP := "item_unequip"
	const SFX_CHECKPOINT := "checkpoint"
	const SFX_UNDO := "undo"
	const SFX_REDO := "redo"
	const SFX_UI_CLICK := "ui_click"
	const SFX_UI_HOVER := "ui_hover"
	const SFX_JOURNAL_UNLOCK := "journal_unlock"

	const SFX_WEATHER_CHANGE := "weather_change"
	const SFX_WEATHER_EFFECT := "weather_effect"

	const SFX_DIALOGUE_START := "dialogue_start"
	const SFX_DIALOGUE_END := "dialogue_end"


class Save:
	const KEY_GLOBAL_FLAGS := "global_flags"
	const KEY_LEVEL_FLAGS := "level_flags"
	const KEY_LEADER_UNIT_NAME := "leader_unit_name"
	const KEY_COMPLETED_LEVELS := "completed_levels"
	const KEY_IS_IN_LEVEL := "is_in_level"
	const KEY_WEATHER := "weather"
	const KEY_TURN_STATE := "turn_state"
	const KEY_TASK_STATE := "task_state"
	const KEY_LOCATION_STATE := "location_state"
	const KEY_UNITS := "units"
	const KEY_HOMETOWN_SKITS_SHOWN := "hometown_skits_shown"
	const KEY_HARD_SAVE_INDEX := "last_hard_save_index"
	const KEY_SAVE_TIMESTAMP := "save_timestamp"
	const KEY_LEVEL_ID := "level_id"
	const KEY_COMPLETED_LEVELS_COUNT := "completed_levels_count"
	const KEY_LAST_COMPLETED_LEVEL := "last_completed_level"
	const KEY_COMPLETION_HISTORY := "completion_history"


# ============================================================================
# AI & DECISION MAKING
# ============================================================================

class AI:
	# Action Types
	const ACTION_FIGHT := ActionType.FIGHT
	const ACTION_GATHER := ActionType.GATHER
	const ACTION_TRAPPED := ActionType.TRAPPED
	const ACTION_CONVINCE := ActionType.CONVINCE
	const ACTION_EXPLORE := ActionType.EXPLORE
	const ACTION_VISIT := ActionType.VISIT
	const ACTION_AID_ALLY := ActionType.AID
	const ACTION_MOVE_TO_FIGHT := ActionType.MOVE_TO_FIGHT
	const ACTION_MOVE_TO_GATHER := ActionType.MOVE_TO_GATHER
	const ACTION_MOVE_TO_TRAPPED := ActionType.MOVE_TO_TRAPPED
	const ACTION_MOVE_TO_EXPLORE := ActionType.MOVE_TO_EXPLORE
	const ACTION_MOVE_TO_VISIT := ActionType.MOVE_TO_VISIT
	const ACTION_MOVE_TO_CONVINCE := ActionType.MOVE_TO_CONVINCE
	const ACTION_MOVE_TO_CENTER := ActionType.MOVE_TO_CENTER

	# Standardized Multipliers (used with CombatPriorityProfile weights)
	const MULTIPLIER_FIGHT := 8
	const MULTIPLIER_EXPLORE := 14
	const MULTIPLIER_VISIT := 20
	const MULTIPLIER_TASK := 16
	const MULTIPLIER_GATHER := 14
	const MULTIPLIER_TRAPPED := 12
	const MULTIPLIER_CONVINCE := 22
	const MULTIPLIER_AID_ALLY := 4
	# Move-Toward Multipliers
	const MULTIPLIER_MOVE_TO_GATHER := 2
	const MULTIPLIER_MOVE_TO_TRAPPED := 4
	const MULTIPLIER_MOVE_TO_EXPLORE := 4
	const MULTIPLIER_MOVE_TO_VISIT := 4
	const MULTIPLIER_MOVE_TO_FIGHT := 4
	const MULTIPLIER_MOVE_TO_CONVINCE := 10

	# Interaction Role Weights
	const WEIGHT_OPPOSED := 0.85
	const WEIGHT_UNOPPOSED := 1.0

	# Quality Multipliers
	const QUALITY_MULTIPLIER_SUCCESS := 2.0
	const QUALITY_MULTIPLIER_PROGRESS := 1.2
	const QUALITY_MULTIPLIER_RISKY := 0.6
	const QUALITY_MULTIPLIER_IDLE := 0.3
	const QUALITY_MULTIPLIER_INEFFECTIVE := 0.1

	# Scoring Ratios
	const RATIO_MOVE_TO_TARGET := 0.5
	const RATIO_FALLBACK_ACTION := 0.1

	# Base Scores (fallbacks if no profile exists)
	const SCORE_FIGHT_BASE := 80
	const SCORE_TASK_BASE := 85
	const SCORE_CONVINCE_BASE := 110
	const SCORE_GATHER_BASE := 75
	const SCORE_TRAPPED_BASE := 65
	const SCORE_AID_ALLY_BASE := 12
	const BATCH_RESOLVE_ACTIONS := true

	# Movement scores
	const SCORE_MOVE_TO_FIGHT := 40
	const SCORE_MOVE_TO_EXPLORE := 25
	const SCORE_MOVE_TO_VISIT := 25
	const SCORE_MOVE_TO_CONVINCE := 60
	const SCORE_MOVE_TO_GATHER := 15
	const SCORE_MOVE_TO_TRAPPED := 10
	const SCORE_MOVE_TO_CENTER := 5

	# Modifiers
	const THREAT_PENALTY := 15
	const SCORE_MORALE_ADJUSTMENT_MAX := 20

	const DIALOGUE_PRIORITY_BONUS := 50
	const GRID_ADJACENCY_THRESHOLD := 1
	const AI_DISCOVERY_RADIUS := 100


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


class MenuType:
	const PAUSE := "pause"
	const ATTACK := "attack_menu"

class UI:
	const DEFAULT_TWEEN_DURATION := 0.3
	const DEFEAT_RETURN_DELAY := 2.0
	const CREDITS_RETURN_DELAY := 10.0
	const AI_THINK_DELAY := 0.5
	const AI_ACTION_DELAY := 0.2

	# Animation & Timing Defaults
	const DEFAULT_ANIMATION_DURATION := 0.2
	const MOVEMENT_STEP_DELAY := 0.25
	const JITTER_THRESHOLD := 0.1
	const UNIT_SPRITE_FLIP_THRESHOLD := 0.1

	# Speed Multipliers
	const SPEED_SLOW_MULTIPLIER := 1.5
	const SPEED_NORMAL_MULTIPLIER := 1.0
	const SPEED_FAST_MULTIPLIER := 0.25
	const SPEED_SKIP_MULTIPLIER := 0.0

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


	class Indicators:
		const SUCCESS := "★" # Elimination / Task Complete
		const PROGRESS := "▲" # Positive progress
		const RISKY := "◆" # Counter-risk or net loss
		const INEFFECTIVE := "▼" # No progress or reaction
		const IDLE := "●" # No change (Wait/Empty turn)
		const SUBMENU := "…"

class Inventory:
	const ACTION_MINUS := "minus"
	const ACTION_HAND := "hand"
	const ACTION_EQUIP := "equip"

	const STASH_SIZE_PORTRAIT := Vector2(1200, 80)
	const STASH_SIZE_LANDSCAPE := Vector2(300, 800)
	const STASH_ITEM_WIDTH_LANDSCAPE := 250.0


class Inputs:
	const MOVEMENT_PREFIX := "move_"
	const DIRECT_SELECTION_PREFIX := "select_unit_"
	const PRIMARY_ACTION := "ui_select"
	const SECONDARY_ACTION := "secondary_action"
	const WAIT_ACTION := "wait_turn"
	const CAMERA_ZOOM_IN := "camera_zoom_in"
	const CAMERA_ZOOM_OUT := "camera_zoom_out"
	const FREE_CAM_TOGGLE := "toggle_free_cam"
	const SELECTION_CYCLE_NEXT := "cycle_next"
	const SELECTION_CYCLE_PREV := "cycle_prev"
	const TOGGLE_ENEMY_RANGE := "toggle_enemy_range"
	const UI_NAV_TOGGLE := "toggle_ui_nav"
	const CONFIRM_MOVE := "confirm_move"
	const CANCEL_MOVE := "cancel_move"
	const DIALOGIC_DEFAULT_ACTION := "dialogic_default_action"
	const AUTO_BATTLE_TOGGLE := "toggle_auto_battle"
	const CAMERA_PAN_UP := "camera_pan_up"
	const CAMERA_PAN_DOWN := "camera_pan_down"
	const CAMERA_PAN_LEFT := "camera_pan_left"
	const CAMERA_PAN_RIGHT := "camera_pan_right"
	const CAMERA_ROTATE_LEFT := "camera_rotate_left"
	const CAMERA_ROTATE_RIGHT := "camera_rotate_right"
	const DIALOGUE_SKIP_ACTION := "dialogue_skip"
	const DIALOGUE_ADVANCE_ACTION := "custom_dialogue_advance"
	const PAUSE_GAME := "pause_game"


# ============================================================================
# SETTINGS & CONFIGURATION (Literal paths for GameConfig)
# ============================================================================

const SETTING_LANGUAGE := "display/language"
const SETTING_DIALOGUE_AUTO_ADVANCE := "dialogue/auto_advance_enabled"
const SETTING_DIALOGUE_AUTO_SPEED := "dialogue/auto_advance_speed"
const SETTING_DIALOGUE_TEXT_SPEED := "dialogue/text_speed"

const SETTING_CONTROLS_INVERT_Y := "controls/invert_y"
const SETTING_GAMEPLAY_DIFFICULTY := "gameplay/difficulty"
const SETTING_GAMEPLAY_ANIMATION_SPEED := "gameplay/animation_speed"
const SETTING_GAMEPLAY_BATCH_ANIMATIONS_ENABLED := "gameplay/batch_animations_enabled"
const SETTING_DISPLAY_ORIENTATION := "display/orientation"
const SETTING_DISPLAY_RESOLUTION := "display/resolution"

const SETTING_AUDIO_MASTER := "audio/master_db"
const SETTING_AUDIO_MUSIC := "audio/music_db"
const SETTING_AUDIO_SFX := "audio/sfx_db"
const SETTING_AUDIO_UI := "audio/ui_db"
const SETTING_AUDIO_ENVIRONMENT := "audio/environment_db"
const SETTING_AUDIO_NARRATIVE := "audio/narrative_db"

const SETTING_AUDIO_MASTER_MUTED := "audio/master_muted"
const SETTING_AUDIO_MUSIC_MUTED := "audio/music_muted"
const SETTING_AUDIO_SFX_MUTED := "audio/sfx_muted"
const SETTING_AUDIO_UI_MUTED := "audio/ui_muted"
const SETTING_AUDIO_ENVIRONMENT_MUTED := "audio/environment_muted"
const SETTING_AUDIO_NARRATIVE_MUTED := "audio/narrative_muted"

const SETTING_ACCESSIBILITY_HIGH_CONTRAST := "accessibility/high_contrast_enabled"
const SETTING_ACCESSIBILITY_REDUCED_MOTION := "accessibility/reduced_motion_enabled"
const SETTING_ACCESSIBILITY_UI_SCALE := "accessibility/ui_scale"

class Settings:
	const DIFFICULTY_EASY := "easy"
	const DIFFICULTY_NORMAL := "normal"
	const DIFFICULTY_HARD := "hard"

	const ANIMATION_SPEED_SLOW := "slow"
	const ANIMATION_SPEED_NORMAL := "normal"
	const ANIMATION_SPEED_FAST := "fast"
	const ANIMATION_SPEED_SKIP := "skip"

	const BATCH_ANIMATIONS_ENABLED := "batch_animations_enabled"

	const ORIENTATION_LANDSCAPE := "landscape"
	const ORIENTATION_PORTRAIT := "portrait"

	# Deprecated: Use top-level SETTING_* constants instead for cross-file compatibility
	const LANGUAGE := SETTING_LANGUAGE
	const DIALOGUE_AUTO_ADVANCE := SETTING_DIALOGUE_AUTO_ADVANCE
	const DIALOGUE_AUTO_SPEED := SETTING_DIALOGUE_AUTO_SPEED
	const DIALOGUE_TEXT_SPEED := SETTING_DIALOGUE_TEXT_SPEED
	const AUDIO_MASTER := SETTING_AUDIO_MASTER
	const ACCESSIBILITY_HIGH_CONTRAST := SETTING_ACCESSIBILITY_HIGH_CONTRAST
	const ACCESSIBILITY_REDUCED_MOTION := SETTING_ACCESSIBILITY_REDUCED_MOTION
	const ACCESSIBILITY_UI_SCALE := SETTING_ACCESSIBILITY_UI_SCALE


# ============================================================================
# COMMAND CONTEXT & PAYLOAD KEYS
# ============================================================================

class ContextKeys:
	const UNIT_CONTROLLER := "unit_controller"
	const UNIT_MANAGER := "unit_manager"
	const TASK_MANAGER := "task_manager"
	const LOOT_MANAGER := "loot_manager"
	const HEX_NAVIGATOR := "hex_navigator"
	const GRID_VISUALS := "grid_visuals"
	const HUD_CONTROLLER := "hud_controller"
	const INPUT_CONTROLLER := "input_controller"
	const MOVE_CONTROLLER := "move_controller"
	const ANIMATION_SERVICE := "animation_service"
	const CAMERA_CONTROLLER := "camera_controller"
	const TASK_CONTROLLER := "task_controller"
	const MAP_CONTROLLER := "map_controller"
	const AI_CONTROLLER := "ai_controller"
	const COMBAT_SYSTEM := "combat_system"
	const CHECKPOINT_MANAGER := "checkpoint_manager"
	const TURN_CONTROLLER := "turn_controller"
	const DIALOGUE_ACTION_SERVICE := "dialogue_action_service"
	const INTERACTION_SEQUENCER := "interaction_sequencer"
	const ROUND_ORCHESTRATOR := "round_orchestrator"
	const BINDING_SERVICE := "binding_service"
	const LOCATION_SERVICE := "location_service"
	const GRID_QUERY_SERVICE := "grid_query_service"
	const SAVE_MANAGER := "save_manager"
	const WEATHER_MANAGER := "weather_manager"
	const JOURNAL_MANAGER := "journal_manager"
	const ACHIEVEMENT_MANAGER := "achievement_manager"
	const LEVEL_RESOURCE := "level_resource"
	const TERRAIN_MAP := "terrain_map"
	const COMMAND_CONTEXT := "command_context"
	const COMMAND_ROUTER := "command_router"
	const GRID := "grid"
	const CAMERA_2D := "camera_2d"
	const PLAYER_ROSTER := "player_roster"
	const HUD := "hud"
	const AUTO_BATTLE_ACTIVE := "auto_battle_active"

class ControlSettingsKeys:
	const START_KEYCODES := "start_keycodes"
	const QUIT_KEYCODES := "quit_keycodes"
	const START_JOYPAD_BUTTONS := "start_joypad_buttons"
	const QUIT_JOYPAD_BUTTONS := "quit_joypad_buttons"
	const ALLOW_ANY_NON_QUIT_KEY_TO_START := "allow_any_non_quit_key_to_start"
	const ALLOW_ANY_JOY_BUTTON_TO_START := "allow_any_joy_button_to_start"
	const MOVE_ACTIONS := "move_actions"
	const CAMERA_ACTIONS := "camera_actions"
	const SELECTION_ACTIONS := "selection_actions"
	const INTERACTION_ACTIONS := "interaction_actions"
	const PAUSE_ACTIONS := "pause_actions"
	const VISUAL_ACTIONS := "visual_actions"

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
	const INDEX := "index"
	const DIRECTION := "direction"
	const COORD := "coord"
	const POSITION := "coord" # Alias for position-based inputs
	const TARGET_COORD := "target_coord"
	const INTERACT_TARGET_COORD := "interact_target_coord"
	const INTERACT_ACTION_TYPE := "interact_action_type"
	const TARGET_MOVE_COORD := "target_move_coord"
	const LOOT_COORD := "loot_coord"
	const AXIS := "axis"
	const ACTION_ID := "action_id"
	const SKILL := "skill"
	const ATTRIBUTE_INDEX := "attribute_index"
	const FORECAST_RESULTS := "forecast_results"
	const USE_FORECAST := "use_forecast"
	const DIALOGUE_ID := "dialogue_id"
	const DIALOGUE_RESOURCE_PATH := "dialogue_resource_path"
	const START_TITLE := "start_title"


# ============================================================================
# FACTION NAMES (Helper)
# ============================================================================
# Note: Faction enum is defined in Unit.gd

func get_faction_name(faction: Faction) -> String:
	if LevelManager.current_level:
		var raw_name: String = ""
		match faction:
			Faction.PLAYER: raw_name = LevelManager.current_level.player_faction_name
			Faction.ENEMY:  raw_name = LevelManager.current_level.enemy_faction_name
			Faction.NEUTRAL: raw_name = LevelManager.current_level.neutral_faction_name
		if not raw_name.is_empty():
			# If the raw value is a valid tr() key, use the translation; otherwise use as-is
			var translated := TranslationServer.translate(raw_name)
			return translated if translated != raw_name else raw_name

	match faction:
		Faction.PLAYER:  return TranslationServer.translate("hud.faction_player")
		Faction.ENEMY:   return TranslationServer.translate("hud.faction_enemy")
		Faction.NEUTRAL: return TranslationServer.translate("hud.faction_neutral")
		Faction.STATIC:  return TranslationServer.translate("hud.faction_static")
		_: return TranslationServer.translate("hud.target_unknown")

const FACTION_SYMBOLS: Dictionary = {
	Faction.PLAYER: "[P]",
	Faction.ENEMY: "[E]",
	Faction.NEUTRAL: "[N]",
	Faction.STATIC: "[S]"
}

func get_faction_symbol(faction: Faction) -> String:
	return FACTION_SYMBOLS.get(faction, "[?]")

# ============================================================================
# END OF CONSTANTS
# ============================================================================

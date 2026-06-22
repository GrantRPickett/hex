extends Node

## Centralized service for difficulty-related calculations and parameters.
##
## This service provides scaling factors, thresholds, and other constants
## that change based on the current game difficulty setting.

signal difficulty_changed(new_difficulty: String)

var current_difficulty: String = GameConstants.Settings.DIFFICULTY_NORMAL:
	set(value):
		if current_difficulty != value:
			current_difficulty = value
			difficulty_changed.emit(current_difficulty)

func _ready() -> void:
	# Initialize from config
	if GameConfig:
		current_difficulty = GameConfig.get_value(GameConfig.Paths.GAMEPLAY_DIFFICULTY, GameConstants.Settings.DIFFICULTY_NORMAL)
		GameConfig.config_changed.connect(_on_config_changed)

func _on_config_changed(path: String, value) -> void:
	if path == GameConfig.Paths.GAMEPLAY_DIFFICULTY:
		current_difficulty = str(value)

## Returns a general scaling factor for AI decision making impact.
func get_ai_scaling_factor() -> float:
	match current_difficulty:
		GameConstants.Settings.DIFFICULTY_EASY:
			return GameConstants.Difficulty.AI_SCALE_EASY
		GameConstants.Settings.DIFFICULTY_HARD:
			return GameConstants.Difficulty.AI_SCALE_HARD
		_:
			return GameConstants.Difficulty.AI_SCALE_NORMAL

## Returns which morale factor the AI should prioritize (0.0 = personal, 1.0 = group).
func get_ai_morale_weight() -> float:
	match current_difficulty:
		GameConstants.Settings.DIFFICULTY_EASY:
			return GameConstants.Difficulty.AI_MORALE_WEIGHT_EASY
		GameConstants.Settings.DIFFICULTY_HARD:
			return GameConstants.Difficulty.AI_MORALE_WEIGHT_HARD
		_:
			return GameConstants.Difficulty.AI_MORALE_WEIGHT_NORMAL

## Returns the retreat threshold ratio for a faction.
func get_retreat_threshold() -> float:
	match current_difficulty:
		GameConstants.Settings.DIFFICULTY_EASY:
			return GameConstants.Difficulty.RETREAT_THRESHOLD_EASY
		GameConstants.Settings.DIFFICULTY_HARD:
			return GameConstants.Difficulty.RETREAT_THRESHOLD_HARD
		_:
			return GameConstants.Difficulty.RETREAT_THRESHOLD_NORMAL

## Returns a multiplier for damage or success rates if needed.
func get_combat_modifier() -> float:
	match current_difficulty:
		GameConstants.Settings.DIFFICULTY_EASY:
			return GameConstants.Difficulty.COMBAT_MODIFIER_EASY
		GameConstants.Settings.DIFFICULTY_HARD:
			return GameConstants.Difficulty.COMBAT_MODIFIER_HARD
		_:
			return GameConstants.Difficulty.COMBAT_MODIFIER_NORMAL

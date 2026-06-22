class_name MoraleService
extends Node

## Service for managing willpower baselines and retreat checks.
## Decoupled from MoralePanel.

var _unit_manager: UnitManager
var _initial_max_willpower: Dictionary = {
	GameConstants.Faction.PLAYER: 0,
	GameConstants.Faction.ENEMY: 0,
	GameConstants.Faction.NEUTRAL: 0
}

var _retreat_status: Dictionary = {
	GameConstants.Faction.PLAYER: false,
	GameConstants.Faction.ENEMY: false,
	GameConstants.Faction.NEUTRAL: false
}

func setup(unit_manager: UnitManager) -> void:
	_unit_manager = unit_manager
	recalculate_baselines()

func recalculate_baselines() -> void:
	if not is_instance_valid(_unit_manager):
		return
		
	# Baseline is the maximum "initial" willpower encountered so far.
	# We use max() to ensure the threshold doesn't drop when units die.
	for faction in _initial_max_willpower:
		var current_max = _unit_manager.get_faction_max_willpower(faction, false)
		_initial_max_willpower[faction] = max(_initial_max_willpower[faction], current_max)

func get_initial_max_willpower(faction: int) -> int:
	return _initial_max_willpower.get(faction, 0)

func check_retreat_condition(faction: int) -> bool:
	if _retreat_status.get(faction, false):
		return true

	var initial_max = get_initial_max_willpower(faction)
	if initial_max <= 0:
		return false

	var units = []
	match faction:
		GameConstants.Faction.PLAYER: units = _unit_manager.get_player_units()
		GameConstants.Faction.ENEMY: units = _unit_manager.get_enemy_units()
		GameConstants.Faction.NEUTRAL: units = _unit_manager.get_neutral_units()

	var stats = get_willpower_stats(units)
	var threshold = initial_max * DifficultyService.get_retreat_threshold()
	if stats.current < threshold:
		_retreat_status[faction] = true
		return true

	return false

func get_willpower_stats(units: Array) -> Dictionary:
	var current: int = 0
	var max_val: int = 0
	for unit in units:
		if is_instance_valid(unit) and unit.willpower > 0:
			current += unit.willpower
		if is_instance_valid(unit):
			max_val += unit.max_willpower
	return {"current": current, "max": max_val}

func reset_retreat_status() -> void:
	for faction in _retreat_status:
		_retreat_status[faction] = false
	_initial_max_willpower = {
		GameConstants.Faction.PLAYER: 0,
		GameConstants.Faction.ENEMY: 0,
		GameConstants.Faction.NEUTRAL: 0
	}
	recalculate_baselines()

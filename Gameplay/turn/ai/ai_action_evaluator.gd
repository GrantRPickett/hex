class_name AIActionEvaluator
extends RefCounted

const _AIContext = preload("res://Gameplay/turn/ai/ai_context.gd")
const _AIAction = preload("res://Gameplay/turn/ai/ai_action.gd")
const _Unit = preload("res://Gameplay/targets/unit.gd")

## Abstract base class for AI action evaluators.
## Each subclass is responsible for finding one *family* of actions
## (e.g., attack actions, loot actions, task actions) and returning
## scored AIAction candidates.
##
## Usage:
##   var actions = evaluator.evaluate(unit, context)
##
## Concrete subclasses must override evaluate().

func evaluate(_unit: _Unit, _context: _AIContext) -> Array[_AIAction]:
	GameLogger.error(GameLogger.Category.AI, "AIActionEvaluator.evaluate() must be overridden by: %s" % get_script().resource_path)
	return []

func _discover_nearby(unit: _Unit, context: _AIContext, types: Array) -> Dictionary:
	return context.get_discovery_results(unit.get_grid_location(), GameConstants.AI.AI_DISCOVERY_RADIUS, types, {
		"unit_manager": context.unit_manager,
		"task_manager": context.task_manager,
		"loot_manager": context.loot_manager,
		"faction": unit.faction,
		"source_unit": unit
	})

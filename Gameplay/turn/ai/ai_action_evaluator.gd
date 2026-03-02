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
##   var actions: Array[AIAction] = evaluator.evaluate(unit, context)
##
## Concrete subclasses must override evaluate().

func evaluate(_unit: _Unit, _context: _AIContext) -> Array[_AIAction]:
	push_error("AIActionEvaluator.evaluate() must be overridden by: %s" % get_script().resource_path)
	return []

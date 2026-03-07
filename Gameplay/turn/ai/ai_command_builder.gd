class_name AICommandBuilder
extends RefCounted

const _AIContext = preload("res://Gameplay/turn/ai/ai_context.gd")
const _AIAction = preload("res://Gameplay/turn/ai/ai_action.gd")
const _Unit = preload("res://Gameplay/targets/unit.gd")
const _ExploreCommand = preload("res://Gameplay/commands/explore_command.gd")
const _VisitCommand = preload("res://Gameplay/commands/visit_command.gd")
const _TrappedCommand = preload("res://Gameplay/commands/trapped_command.gd")

## Converts a selected AIAction into a GameCommand + payload Dictionary.
## Encapsulates all "how do I turn this decision into a command?" logic,
## keeping AIController free from per-action-type translation details.
##
## Returns an empty Dictionary {} when the action cannot be translated.

func build(action: _AIAction, unit: _Unit, context: _AIContext) -> Dictionary:
	var unit_index := context.unit_manager.get_unit_index(unit)
	if unit_index == -1:
		return {}

	match action.type:
		GameConstants.AI.ACTION_ATTACK:
			return _attack(unit_index, action, context)
		GameConstants.AI.ACTION_EXPLORE:
			return _explore(unit_index, action)
		GameConstants.AI.ACTION_VISIT:
			return _visit(unit_index, action)
		GameConstants.AI.ACTION_LOOT:
			return _loot(unit_index, action)
		GameConstants.Interactions.TRAPPED:
			return _trapped(unit_index, action)
		GameConstants.AI.ACTION_AID_ALLY:
			return _aid_ally(unit_index, action, context)
		GameConstants.AI.ACTION_TALK:
			# Dialogue is handled by on-enter/exit triggers — AI does not dispatch talk commands.
			return {}
		GameConstants.AI.ACTION_CONVINCE:
			return _convince(unit_index, action, context)
		# Pure movement actions: movement is handled before interaction is dispatched.
		# Any remaining pure-move type means there is nothing further to execute.
		GameConstants.AI.ACTION_MOVE_TO_ENEMY, \
		GameConstants.AI.ACTION_MOVE_TO_TASK, \
		GameConstants.AI.ACTION_MOVE_TO_LOOT, \
		GameConstants.AI.ACTION_MOVE_TO_CENTER, \
		GameConstants.AI.ACTION_MOVE_TO_TALK, \
		GameConstants.AI.ACTION_MOVE_TO_CONVINCE:
			return {}
		_:
			push_warning("AICommandBuilder: no handler for action type '%s'" % action.type)
			return {}

# -- per-type builders ---------------------------------------------------------

func _convince(unit_index: int, action: AIAction, context: AIContext) -> Dictionary:
	var target_unit := action.target as Unit
	var target_index := context.unit_manager.get_unit_index(target_unit)
	if target_index == -1:
		return {}
	return {
		"cmd": ConvinceUnitCommand.new(),
		"payload": {
			"initiator_index": unit_index,
			"target_index": target_index
		}
	}

func _attack(unit_index: int, action: AIAction, context: AIContext) -> Dictionary:
	var enemy_target := action.target as Unit
	var target_index := context.unit_manager.get_unit_index(enemy_target)
	if target_index == -1:
		return {}
	return {
		"cmd": AttackUnitCommand.new(),
		"payload": {
			"attacker_index": unit_index,
			"target_index": target_index
		}
	}

func _explore(unit_index: int, action: AIAction) -> Dictionary:
	var task_target := action.target as Task
	var task_id := String(task_target.id) if task_target else ""
	if task_id.is_empty():
		return {}
	return {
		"cmd": _ExploreCommand.new(),
		"payload": {
			"worker_index": unit_index,
			"task_id": task_id
		}
	}

func _visit(unit_index: int, action: AIAction) -> Dictionary:
	var task_target := action.target as Task
	if task_target == null:
		return {}
	# VisitCommand resolves the Location from context (unit's current position).
	# The task carries enough identity via task_id for the command to look up the target.
	return {
		"cmd": _VisitCommand.new(),
		"payload": {
			"worker_index": unit_index,
			"task_id": String(task_target.id)
		}
	}

func _trapped(unit_index: int, action: AIAction) -> Dictionary:
	var task_target := action.target as Task
	var task_id := String(task_target.id) if task_target else ""
	if task_id.is_empty():
		return {}
	return {
		"cmd": _TrappedCommand.new(),
		"payload": {
			"worker_index": unit_index,
			"task_id": task_id
		}
	}

func _loot(unit_index: int, action: AIAction) -> Dictionary:
	var loot_coord := action.target as Vector2i
	return {
		"cmd": LootCommand.new(),
		"payload": {
			"looter_index": unit_index,
			"loot_coord": loot_coord
		}
	}

func _aid_ally(unit_index: int, action: AIAction, context: AIContext) -> Dictionary:
	var ally_target := action.target as Unit
	var ally_index := context.unit_manager.get_unit_index(ally_target)
	if ally_index == -1:
		return {}
	return {
		"cmd": AidAllyCommand.new(),
		"payload": {
			"helper_index": unit_index,
			"target_index": ally_index
		}
	}

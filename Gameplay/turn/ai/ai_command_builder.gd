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
	if unit_index == GameConstants.INVALID_INDEX:
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
	if target_index == GameConstants.INVALID_INDEX:
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
	if target_index == GameConstants.INVALID_INDEX:
		return {}
		
	var attacker = context.unit_manager.get_unit(unit_index)
	var best_attr = _select_best_attack_attribute(attacker)
	
	return {
		"cmd": AttackUnitCommand.new(),
		"payload": {
			"attacker_index": unit_index,
			"target_index": target_index,
			"attribute_index": best_attr
		}
	}

static func _select_best_attack_attribute(unit: Unit) -> int:
	var attrs = unit.inv.get_attributes() if unit.inv else null
	if attrs == null: return 0
	var best_index := 0
	var best_value := -INF
	for i in range(Target.COMBAT_ATTRIBUTE_NAMES.size()):
		var val = attrs.get_attribute(Target.COMBAT_ATTRIBUTE_NAMES[i])
		if val > best_value:
			best_value = val
			best_index = i
	return best_index

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
	var target_data = action.target
	var ally_target: Unit
	var attr_idx: int = 0
	
	if target_data is Unit:
		ally_target = target_data
	elif target_data is Dictionary:
		ally_target = target_data.get("unit")
		attr_idx = target_data.get("attribute_index", 0)
	
	if ally_target == null:
		return {}
		
	var ally_index := context.unit_manager.get_unit_index(ally_target)
	if ally_index == GameConstants.INVALID_INDEX:
		return {}
	return {
		"cmd": AidAllyCommand.new(),
		"payload": {
			"helper_index": unit_index,
			"target_index": ally_index,
			"attribute_index": attr_idx
		}
	}

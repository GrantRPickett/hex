class_name AICommandBuilder
extends RefCounted

const _AIContext = preload("res://Gameplay/turn/ai/ai_context.gd")
const _AIAction = preload("res://Gameplay/turn/ai/ai_action.gd")
const _Unit = preload("res://Gameplay/targets/unit.gd")

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
		&"attack":
			return _attack(unit_index, action, context)
		&"work_on_task":
			return _work_on_task(unit_index, action)
		&"loot":
			return _loot(unit_index, action)
		&"aid_ally":
			return _aid_ally(unit_index, action, context)
		&"talk":
			return _talk(unit_index, action)
		# Pure movement actions: movement is handled before interaction is dispatched.
		# Any remaining pure-move type means there is nothing further to execute.
		&"move_to_enemy", &"move_to_task", &"move_to_loot", &"move_to_center", &"move_to_talk":
			return {}
		_:
			push_warning("AICommandBuilder: no handler for action type '%s'" % action.type)
			return {}

# -- per-type builders ---------------------------------------------------------

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

func _work_on_task(unit_index: int, action: AIAction) -> Dictionary:
	var task_target := action.target as Task
	var task_id := String(task_target.id) if task_target else ""
	if task_id.is_empty():
		return {}
	return {
		"cmd": WorkOnTaskCommand.new(),
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

func _talk(unit_index: int, action: AIAction) -> Dictionary:
	var talk_data: Dictionary = action.target if action.target is Dictionary else {}
	var initiator_index := int(talk_data.get("initiator_index", unit_index))
	var target_index := int(talk_data.get("target_index", -1))
	if target_index < 0:
		return {}
	var dialogue_id_value = talk_data.get("dialogue_id", StringName(""))
	var dialogue_id: StringName = dialogue_id_value if dialogue_id_value is StringName else StringName(dialogue_id_value)
	if String(dialogue_id).is_empty():
		return {}
	return {
		"cmd": TalkToUnitCommand.new(),
		"payload": {
			"initiator_index": initiator_index,
			"target_index": target_index,
			"dialogue_id": dialogue_id
		}
	}

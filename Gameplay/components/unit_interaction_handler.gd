class_name UnitInteractionHandler
extends RefCounted

## Component responsible for handling unit interactions with targets.
##
## This component uses a strategy pattern to handle different interaction types:
## - Loot collection
## - location work
## - Combat (delegated to combat behavior)
## - Ally aid (delegated to combat behavior)

var _unit # Unit (type hint removed to avoid circular dependency)
var _loot_manager: LootManager
var _task_manager: TaskManager

func _init(unit: Unit) -> void:
	_unit = unit

func set_loot_manager(manager: LootManager) -> void:
	_loot_manager = manager

func set_task_manager(manager: TaskManager) -> void:
	_task_manager = manager

## Main interaction dispatcher - routes to appropriate interaction type
func interact(target: Target) -> bool:
	if target is Loot:
		return loot(target.get_grid_location())
	elif target is Location:
		var task_to_work_on = _task_manager.get_task_for_location(target)
		if task_to_work_on:
			return work_on_task(task_to_work_on)
		return false # No task found for this location
	elif target is Unit:
		var target_unit := target as Unit
		if target_unit.faction == _unit.faction:
			return _unit.combat_behavior.aid_ally(target_unit)
		else:
			return _unit.combat_behavior.attack(target_unit)
	return false

## Attempts to loot items at the specified grid location
func loot(loot_coord: Vector2i) -> bool:
	if not _unit.has_action_available():
		return false

	if _loot_manager == null:
		return false

	var loot_node = _loot_manager.get_loot_at(loot_coord)
	if loot_node == null:
		return false

	# The can_be_looted_by check ensures the unit is on the same tile.
	if not loot_node.can_be_looted_by(_unit):
		return false

	var inventory = _unit.get_inventory()
	if inventory == null:
		return false

	var should_auto_equip = inventory.get_items().is_empty()
	var items_looted = false

	for item in loot_node.inventory.duplicate():
		var success = false
		if should_auto_equip:
			success = _unit.equip_item(item)
		else:
			success = _unit.add_item_to_inventory(item)

		if success:
			loot_node.inventory.erase(item)
			items_looted = true

	if loot_node.inventory.is_empty():
		_loot_manager.remove_loot(loot_node)

	if items_looted:
		_unit.consume_action()

	return items_looted

## Attempts to work on a location
func work_on_task(target_task: Task) -> bool:
	if not _unit.has_action_available():
		return false

	if target_task == null:
		return false

	if not target_task.can_be_worked_on_by(_unit):
		return false

	if _task_manager == null:
		return false
	
	_unit.consume_action()
	return true

class_name UnitInteractionHandler
extends RefCounted

## Component responsible for handling unit interactions with targets.
##
## This component uses a strategy pattern to handle different interaction types:
## - Loot collection
## - Goal work
## - Combat (delegated to combat behavior)
## - Ally aid (delegated to combat behavior)

var _unit # Unit (type hint removed to avoid circular dependency)
var _loot_manager: LootManager
var _goal_manager: GoalManager

func _init(unit: Unit) -> void:
	_unit = unit

func set_loot_manager(manager: LootManager) -> void:
	_loot_manager = manager

func set_goal_manager(manager: GoalManager) -> void:
	_goal_manager = manager

## Main interaction dispatcher - routes to appropriate interaction type
func interact(target: Target) -> bool:
	if target is Loot:
		return loot(target.get_grid_location())
	elif target is Goal:
		return work_on_goal(target)
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

## Attempts to work on a goal
func work_on_goal(goal: Goal) -> bool:
	if not _unit.has_action_available():
		return false

	if goal == null:
		return false

	if not goal.can_be_worked_on_by(_unit):
		return false

	if _goal_manager == null:
		return false

	var goal_index = -1
	for i in range(_goal_manager.get_goal_count()):
		if _goal_manager.get_target(i) == goal.coord:
			goal_index = i
			break

	if goal_index == -1:
		return false

	_goal_manager.apply_progress(goal_index, _unit)
	_unit.consume_action()
	return true

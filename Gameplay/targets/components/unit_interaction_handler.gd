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
		var loot_node = target as Loot
		if loot_node.is_trapped:
			var task_to_work_on = _task_manager.get_task_for_target(target)
			if task_to_work_on:
				return work_on_task(task_to_work_on, target)
		return loot(target.get_grid_location())
	elif target is Location:
		var task_to_work_on = _task_manager.get_task_for_target(target)
		if task_to_work_on:
			return work_on_task(task_to_work_on, target)
		return false # No task found for this location
	elif target is Unit:
		var target_unit := target as Unit
		if target_unit.faction == _unit.faction:
			return _unit.combat.aid_ally(target_unit)
		else:
			return _unit.combat.attack(target_unit)
	return false

## Attempts to loot items at the specified grid location
func loot(loot_coord: Vector2i) -> bool:
	return _try_interaction(func():
		var LootDiscovery = preload("res://Gameplay/targets/discovery/loot_discovery.gd")
		var loot_node = LootDiscovery.get_immediate_loot(_unit, loot_coord, _loot_manager)
		
		if loot_node == null:
			return false

		# If trapped, we must "interact" (disarm/overcome) first.
		# This is handled similarly to location tasks.
		if loot_node.is_trapped:
			if loot_node.has_signal("interacted"):
				loot_node.emit_signal("interacted", _unit)
			return true

		var inventory = _unit.inv.get_inventory()
		if inventory == null:
			return false

		var should_auto_equip = inventory.get_items().is_empty()
		var items_looted = false

		for item in loot_node.inventory.duplicate():
			var success = false
			if should_auto_equip:
				success = _unit.inv.equip_item(item)
			else:
				success = _unit.inv.add_item_to_inventory(item)

			if success:
				loot_node.inventory.erase(item)
				items_looted = true

		if loot_node.inventory.is_empty():
			_loot_manager.remove_loot(loot_node)

		return items_looted
	)

## Attempts to work on a location
func work_on_task(target_task: Task, target_node: Target = null) -> bool:
	if target_task == null:
		return false

	# If no target_node provided, try to find one at the task's location or unit's current location
	var t_coord = target_task.target_coord
	if t_coord == Vector2i(-999, -999):
		t_coord = _unit.get_grid_location()

	if target_node == null:
		target_node = _task_manager.get_location_at(t_coord)
		if target_node == null:
			target_node = _task_manager.get_loot_at(t_coord)

	var node_to_interact = target_node

	return _try_interaction(func():
		if not target_task.can_be_worked_on_by(_unit, t_coord):
			return false

		if _task_manager == null:
			return false

		# If it's a location, call interact on it to trigger signal for TaskManager
		if node_to_interact and node_to_interact is Location:
			node_to_interact.interact(_unit)
			return true
			
		# Fallback: manually trigger task handle_event if no node but task is valid
		# This handles abstract tasks that don't have a physical location node but are active.
		if _task_manager.get_active_objective():
			var event_type = "interact"
			if target_task.event_type == "explore":
				event_type = "explore"
			
			_task_manager.get_active_objective().handle_event(event_type, {
				"unit": _unit,
				"coord": t_coord,
				"id": target_task.target_id,
				"target": node_to_interact
			})
			return true

		return true
	)

func _try_interaction(interaction_callable: Callable) -> bool:
	if not _unit.res.has_action_available():
		return false

	if interaction_callable.call():
		_unit.res.consume_action()
		return true

	return false

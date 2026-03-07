class_name TargetInteractionHandler
extends RefCounted

## Component responsible for handling unit interactions with targets.
##
## This component uses a strategy pattern to handle different interaction types:
## - Loot collection (loot, trap)
## - Location work (explore, visit)
## - Unit interaction (convince, fight)

var _unit # Unit (type hint removed to avoid circular dependency)
var _loot_manager: LootManager
var _task_manager: TaskManager
var _location_service: LocationService

const _UnitDiscovery = preload("res://Gameplay/targets/discovery/unit_discovery.gd")
const _LootDiscovery = preload("res://Gameplay/targets/discovery/loot_discovery.gd")
const _ConvinceDiscovery = preload("res://Gameplay/targets/discovery/convince_discovery.gd")

func _init(unit: Unit) -> void:
	_unit = unit

func set_loot_manager(manager: LootManager) -> void:
	_loot_manager = manager

func set_task_manager(manager: TaskManager) -> void:
	_task_manager = manager

func set_location_service(service: LocationService) -> void:
	_location_service = service

## Main interaction dispatcher - routes to appropriate interaction type
func interact(target: Target) -> bool:
	if target is Loot:
		var loot_node = target as Loot
		if loot_node.is_trapped:
			var task_to_work_on = _task_manager.get_task_for_target(target)
			if task_to_work_on:
				return explore(task_to_work_on, target)
			else:
				# Even if no task, we trigger "trap" interaction
				return _try_interaction(func():
					target.interact(_unit, {"type": GameConstants.Interactions.TRAPPED})
					return true
				)
		return loot(target.get_grid_location())
	elif target is Location:
		var loc := target as Location
		if loc.loyalty == GameConstants.Loyalty.Type.STATIC:
			print_debug("[TargetInteractionHandler] cannot interact with static location: ", loc.loc_name)
			return false


		var task_to_work_on = _task_manager.get_task_for_target(target)
		if task_to_work_on:
			return explore(task_to_work_on, target)

		return visit_location(loc)

	elif target is Unit:
		var target_unit := target as Unit
		var allies = _UnitDiscovery.get_all_units(_unit)["allies"]
		if allies.has(target_unit):
			# Spec: Same-faction (and friendly) interactions SHALL be disabled.
			return false

		# Spec: Neutral Convincing - unloyal neutrals get "convince" (unopposed)
		if _ConvinceDiscovery.is_convincable(target_unit):
			return convince_unit(target_unit)

		# Spec: Enemy Combat / Loyal Neutral Combat - "fight" (opposed)
		return fight_unit(target_unit)

	return false

## Attempts to loot items at the specified grid location
func loot(loot_coord: Vector2i) -> bool:
	return _try_interaction(func():
		var loot_node = _LootDiscovery.get_immediate_loot(_unit, loot_coord, _loot_manager)


		if loot_node == null:
			print_debug("[TargetInteractionHandler] Loot failed: No loot found at ", loot_coord)
			return false

		# If trapped, we trigger trapped interaction
		if loot_node.is_trapped:
			print_debug("[TargetInteractionHandler] Looting trapped item at ", loot_coord, " - triggering investigation")
			loot_node.interact(_unit, {"type": GameConstants.Interactions.TRAPPED})
			return true

		var inventory = _unit.inv.get_inventory()
		if inventory == null:
			print_debug("[TargetInteractionHandler] Loot failed: Unit has no inventory component")
			return false

		# Signal interaction before removing the loot node
		loot_node.interact(_unit, {"type": GameConstants.Interactions.LOOT})

		var should_auto_equip = inventory.get_items().is_empty()
		var items_looted = false

		for item in loot_node.inventory.duplicate():
			var success = false
			if should_auto_equip:
				success = _unit.inv.equip_item(item)
			else:
				success = _unit.inv.add_item_to_inventory(item)

			if success:
				print_debug("[TargetInteractionHandler] Successfully looted item: ", item.resource_name if item.resource_name else "Unnamed Item")
				loot_node.inventory.erase(item)
				items_looted = true
			else:
				print_debug("[TargetInteractionHandler] Failed to loot item: ", item.resource_name if item.resource_name else "Unnamed Item", " (inventory full?)")

		if loot_node.inventory.is_empty():
			_loot_manager.remove_loot(loot_node)

		if not items_looted:
			print_debug("[TargetInteractionHandler] Loot failed: No items were collected from the pile at ", loot_coord)
			return false

		return true
	)

## Attempts to explore a location or work on a task
func explore(target_task: Task, target_node: Target = null, attribute: String = "") -> bool:
	if target_task == null:
		return false

	var t_coord = target_task.target_coord
	if t_coord == Vector2i(-999, -999):
		t_coord = _unit.get_grid_location()

	if target_node == null:
		target_node = _task_manager.get_location_at(t_coord)
		if target_node == null:
			target_node = _task_manager.get_loot_at(t_coord)

	var node_to_interact = target_node

	return _try_interaction(func():
		if _location_service and node_to_interact is Location:
			return _location_service.explore_location(node_to_interact, _unit, target_task, attribute)

		if not target_task.can_be_worked_on_by(_unit, t_coord):
			print_debug("[TargetInteractionHandler] exploration failed: task cannot be performed by unit at ", t_coord)
			return false

		var context = {
			"is_task": true,
			"task_id": String(target_task.id),
			"type": GameConstants.Interactions.EXPLORE,
			"attribute": attribute
		}

		if is_instance_valid(node_to_interact):
			node_to_interact.interact(_unit, context)
			
			# Auto-loot if task completed and it's a loot target
			if target_task.status == Task.Status.COMPLETED:
				if node_to_interact is Loot:
					# Defer loot call to next frame to ensure task state is fully propagated
					# Actually, we can just call it here since we are in a Callable
					# but loot() consumes ANOTHER action point if we use _try_interaction.
					# We should probably use a version of loot that doesn't consume action.
					_auto_loot_from_node(node_to_interact, t_coord)
			
			return true

		# Fallback for abstract tasks
		if _task_manager and _task_manager.get_active_objective():
			_task_manager.get_active_objective().handle_event(GameConstants.TaskEvents.EXPLORE, {
				"unit": _unit,
				"coord": t_coord,
				"id": target_task.target_id,
				"target": node_to_interact,
				"context": context
			})
			return true

		return true
	)

## Attempts an unopposed visit to a location
func visit_location(location: Location) -> bool:
	if location == null:
		return false

	return _try_interaction(func():
		if _location_service:
			return _location_service.visit_location(location, _unit)

		print_debug("[TargetInteractionHandler] Visiting location: ", location.loc_name)
		location.interact(_unit, {"is_task": false, "type": GameConstants.Interactions.VISIT})
		return true
	)

## Attempts to convince a neutral unit
func convince_unit(target_unit: Unit) -> bool:
	return _try_interaction(func():
		var initiator_faction = _unit.faction
		if initiator_faction == Unit.Faction.NEUTRAL:
			initiator_faction = _unit.loyalty.neutral_loyalty

		target_unit.interact(_unit, {"type": GameConstants.Interactions.CONVINCE})
		target_unit.loyalty.apply_persuasion(initiator_faction)
		return true
	)

## Attempts to fight a unit
func fight_unit(target_unit: Unit) -> bool:
	# Interaction signal before combat execution
	target_unit.interact(_unit, {"type": GameConstants.Interactions.ATTACK})
	return _unit.combat.attack(target_unit)

func _auto_loot_from_node(loot_node: Loot, loot_coord: Vector2i) -> bool:
	if loot_node == null:
		return false

	var inventory = _unit.inv.get_inventory()
	if inventory == null:
		return false

	# Signal interaction
	loot_node.interact(_unit, {"type": GameConstants.Interactions.LOOT})

	var should_auto_equip = inventory.get_items().is_empty()
	var items_looted = false

	for item in loot_node.inventory.duplicate():
		var success = false
		if should_auto_equip:
			success = _unit.inv.equip_item(item)
		else:
			success = _unit.inv.add_item_to_inventory(item)

		if success:
			print_debug("[TargetInteractionHandler] Auto-looted item: ", item.resource_name if item.resource_name else "Unnamed Item")
			loot_node.inventory.erase(item)
			items_looted = true

	if loot_node.inventory.is_empty():
		_loot_manager.remove_loot(loot_node)

	return items_looted

func _try_interaction_detailed(interaction_callable: Callable) -> bool:
	if not _unit.res.has_action_available():
		return false

	var result = interaction_callable.call()
	if result != false:
		_unit.res.consume_action()
		return true

	return false

func _try_interaction(interaction_callable: Callable) -> bool:
	return _try_interaction_detailed(interaction_callable)

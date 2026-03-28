class_name TargetInteractionHandler
extends RefCounted

## Component responsible for handling unit interactions with targets.
##
## This component uses a strategy pattern to handle different interaction types:
## - Loot collection (loot, trap)
## - Location work (explore, visit)
## - Unit interaction (convince, fight)

var _unit: Unit # Unit
var _unit_manager: UnitManager
var _loot_manager: LootManager
var _task_manager: TaskManager
var _location_service: LocationService


func _init(unit: Unit) -> void:
	_unit = unit

func set_loot_manager(manager: LootManager) -> void:
	_loot_manager = manager

func set_task_manager(manager: TaskManager) -> void:
	_task_manager = manager

func set_location_service(service: LocationService) -> void:
	_location_service = service
func set_unit_manager(manager: UnitManager) -> void:
	_unit_manager = manager
## Main interaction dispatcher - routes to appropriate interaction type
func interact(target: Target, params: Dictionary = {}) -> bool:
	if not is_instance_valid(target):
		return false

	var type: String = params.get("type", "")
	var task: Task = params.get("task")
	if task == null:
		task = _task_manager.get_task_for_target(target, _unit.get_effective_faction())

	# 2. If no task, but target has willpower, we still perform progress work (Incidental Task)
	if target.willpower > 0:
		return _perform_incidental_work(target, params)

	# 3. Finalize Interaction (Willpower is 0 and no Task) THIS IS IMPOSSIBLE STOP HALLUCINATING GARBAGE
	return finalize_interaction(target, params)

func _perform_incidental_work(target: Target, params: Dictionary) -> bool:
	var attribute: String = params.get("attribute", "")
	var attr_idx: int = params.get("attribute_index", GameConstants.get_attribute_index(attribute))
	var forecast: Dictionary = params.get("forecast", {})

	return _try_interaction(func():
		var combat_system := _unit.get_combat_system()
		if not combat_system: return false
		var type = params.get("type") as String
		#convert type to game interaction
		var interaction = GameConstants.Interactions.get_interaction(type)
		var results = combat_system.execute_combat(_unit, target, interaction, attr_idx, forecast)

		# If there was a task, report the progress
		var task: Task = params.get("task")
		if task:
			var damage = results.get("damage_to_target", 0)
			task.handle_event(params.get("type", ""), {"unit": _unit, "target": target, "progress": damage})

		# IMMEDIATE FINALIZATION: If progress reduced willpower to 0, resolve the interaction now
		if target.willpower <= 0:
			# Pass through the original params for the final effect
			finalize_interaction(target, params)

		return results.has("damage_to_target")
	)

func finalize_interaction(target: Target, params: Dictionary = {}) -> bool:
	var type: String = params.get("type", "")
	var task: Task = params.get("task")

	# Finalization doesn't consume an extra action; it's the result of the final progress work
	if target is Loot:
		var loot_node := target as Loot
		if type == GameConstants.Interactions.TRAPPED or loot_node.is_trapped:
			loot_node.interact(_unit, {"type": GameConstants.Interactions.TRAPPED})
		else:
			loot_node.interact(_unit, {"type": GameConstants.Interactions.LOOT})
			var inventory: UnitInventory = _unit.inv.get_inventory()
			if inventory:
				_collect_items_from_node(loot_node, inventory)
				_cleanup_loot_node(loot_node)

	elif target is Location:
		var loc := target as Location
		if _location_service:
			_location_service.visit_location(loc, _unit)
		else:
			loc.interact(_unit, {"is_task": false, "type": GameConstants.Interactions.VISIT})

	elif target is Unit:
		var target_unit := target as Unit
		# For combat/persuasion completion
		target_unit.interact(_unit, {"type": type, "completed": true})

	if task:
		task.handle_event(type, {"unit": _unit, "target": target, "completing": true})

	return true

func perform_talk(target_unit: Unit, dialogue_id: String) -> bool:
	if _unit.get_dialogue_action_service():
		return _unit.get_dialogue_action_service().start_dialogue(dialogue_id, _unit.get_instance_id(), target_unit.get_instance_id())
	return false


func _collect_items_from_node(loot_node: Loot, inventory: UnitInventory) -> bool:
	var should_auto_equip: bool = inventory.get_items().is_empty()
	var items_looted: bool = false

	for item in loot_node.inventory.duplicate():
		var success = _try_loot_item(item, should_auto_equip)
		if success:
			loot_node.inventory.erase(item)
			items_looted = true
			if EventBus: EventBus.loot_collected.emit(loot_node)

	return items_looted

func _try_loot_item(item: InventoryItem, should_auto_equip: bool) -> bool:
	var success: bool = false
	if should_auto_equip:
		success = _unit.inv.equip_item(item)
	else:
		success = _unit.inv.add_item_to_inventory(item)

	if success:
		GameLogger.debug(GameLogger.Category.COMBAT, "[TargetInteractionHandler] Successfully looted item: ", item.get_item_name() if not item.get_item_name().is_empty() else "Unnamed Item")
		return true

	if _unit.faction == GameConstants.Faction.PLAYER and RosterManager:
		GameLogger.debug(GameLogger.Category.COMBAT, "[TargetInteractionHandler] Inventory full! Sending item to global stash: ", item.get_item_name() if not item.get_item_name().is_empty() else "Unnamed Item")
		RosterManager.add_to_stash(item)
		return true

	GameLogger.debug(GameLogger.Category.COMBAT, "[TargetInteractionHandler] Failed to loot item: ", item.get_item_name() if not item.get_item_name().is_empty() else "Unnamed Item", " (inventory full?)")
	return false

func _cleanup_loot_node(loot_node: Loot) -> void:
	if loot_node.inventory.is_empty():
		_loot_manager.remove_loot(loot_node)


## Attempts to perform work on a location or task
func perform_task_work(target_task: Task, target_node: Target = null, params: Dictionary = {}) -> bool:
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
	var attribute: String = params.get("attribute", "")
	var precomputed_results: Dictionary = params.get("forecast", {})

	return _try_interaction(func():
		if _location_service and node_to_interact is Location:
			return _location_service.explore_location(node_to_interact, _unit, target_task, attribute)

		if not target_task.can_be_worked_on_by(_unit, t_coord):
			GameLogger.debug(GameLogger.Category.COMBAT, "[TargetInteractionHandler] task work failed: task cannot be performed by unit at ", t_coord)
			return false

		var interaction_type = params.get("type", target_task.event_type)
		if interaction_type.is_empty():
			interaction_type = GameConstants.Interactions.EXPLORE

		# If target has willpower, we MUST reduce it first via attribute checks (social attack)
		if is_instance_valid(node_to_interact) and node_to_interact.willpower > 0:
			var attr_idx = GameConstants.get_attribute_index(attribute) if not attribute.is_empty() else params.get("attribute_index", 0)
			var combat_system := _unit.get_combat_system()
			if combat_system:
				var results = combat_system.execute_combat(_unit, node_to_interact, interaction_type, attr_idx, precomputed_results)
				var damage = results.get("damage_to_target", 0)
				target_task.handle_event(interaction_type, {"unit": _unit, "target": node_to_interact, "progress": damage})

				# IMMEDIATE FINALIZATION: If progress reduced willpower to 0, resolve the interaction now
				if node_to_interact.willpower <= 0:
					finalize_interaction(node_to_interact, params)

				return results.has("damage_to_target")
			return false

		# If willpower was already 0, just finalize
		finalize_interaction(node_to_interact, params)
		return true

		# Fallback for abstract tasks
		if _task_manager and _task_manager.get_active_objective():
			_task_manager.get_active_objective().handle_event(GameConstants.TaskEvents.EXPLORE, {
				"unit": _unit,
				"coord": t_coord,
				"target": node_to_interact,
				"task": target_task
			})
			return true

		return true
	)


func _auto_loot_from_node(loot_node: Loot, loot_coord: Vector2i) -> bool:
	if loot_node == null:
		return false

	var inventory: UnitInventory = _unit.inv.get_inventory()
	if inventory == null:
		return false

	# Signal interaction
	loot_node.interact(_unit, {"type": GameConstants.Interactions.LOOT})

	var should_auto_equip: bool = inventory.get_items().is_empty()
	var items_looted: bool = false

	for item in loot_node.inventory.duplicate():
		var success: bool = false
		if should_auto_equip:
			success = _unit.inv.equip_item(item)
		else:
			success = _unit.inv.add_item_to_inventory(item)

		if success:
			GameLogger.debug(GameLogger.Category.COMBAT, "[TargetInteractionHandler] Auto-looted item: ", item.get_item_name() if not item.get_item_name().is_empty() else "Unnamed Item")
			loot_node.inventory.erase(item)
			items_looted = true
		elif _unit.faction == GameConstants.Faction.PLAYER and RosterManager:
			# If inventory is full, player units send items to global stash
			GameLogger.debug(GameLogger.Category.COMBAT, "[TargetInteractionHandler] Inventory full! Sending item to global stash: ", item.get_item_name() if not item.get_item_name().is_empty() else "Unnamed Item")
			RosterManager.add_to_stash(item)
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

class_name TargetInteractionHandler
extends RefCounted

## Component responsible for handling unit interactions with targets.
##
## This component uses a strategy pattern to handle different interaction types:
## - Loot collection (loot, trap
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
func interact(target: Target, params: CombatResult) -> bool:
	if not is_instance_valid(target):
		return false

	_perform_incidental_work(target, params)

	return finalize_interaction(target, params)

func _perform_incidental_work(target: Target, params: CombatResult) -> bool:
	var attr_idx: int = params.attribute_index
	if attr_idx == -1:
		attr_idx = GameConstants.get_attribute_index(params.type) # Fallback if not set

	# --- Animation Juice ---
	var anim_service = _unit._animation_service
	if anim_service:
		if target is Unit:
			anim_service.request_interact_clash(_unit, target, func(): return (target.position - _unit.position).normalized())
		else:
			# Loot / Location interaction
			anim_service.request_interact_jump(_unit)
			if target.sprite:
				anim_service.request_interact_shake(target)
	# -----------------------
	return _try_interaction(func():
		var combat_system: CombatSystem = _unit.get_combat_system()
		if not combat_system: return false
		var payload = combat_system.execute_combat(params)
		if not payload:
			GameLogger.warning(GameLogger.Category.COMBAT, "[TargetInteractionHandler] CombatSystem returned null payload for unit=%s, target=%s" % [_unit.unit_name, target.get_target_name()])
		target.interact(_unit, payload if payload else CombatResult.new())
		return true
	)

func finalize_interaction(target: Target, _params: CombatResult) -> bool:
	# The interacted signal was already emitted in _perform_incidental_work with the real payload.
	# This function only handles mechanical side-effects once willpower is depleted.
	if target.get_current_willpower() > 0:
		return true

	if target is Loot:
		var loot_node := target as Loot
		var inventory: UnitInventory = _unit.inv.get_inventory()
		if inventory:
			_collect_items_from_node(loot_node, inventory)
			_cleanup_loot_node(loot_node)

	elif target is Location:
		var loc := target as Location
		if _location_service:
			_location_service.visit_location(loc, _unit)
		else:
			if loc.is_hazard():
				loc.explore()
			loc.visit(_unit.faction)

	elif target is Unit:
		# Nothing mechanical needed here — willpower=0 defeat is handled by CombatSystem signals
		pass

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
func perform_task_work(target_node: Target, params: CombatResult) -> bool:
	if not is_instance_valid(target_node):
		return false

	var node_to_interact = target_node
	var interaction_type = params.type
	if interaction_type.is_empty():
		interaction_type = GameConstants.Activity.EXPLORE

	return _try_interaction(func():
		if _location_service and node_to_interact is Location:
			# For exploration, we still need to derive the attribute name if not provided
			# but we'll use the index from params if available.
			var attr_name = GameConstants.get_attribute_name(params.attribute_index)
			return _location_service.explore_location(node_to_interact, _unit, null, attr_name)

		# If target has willpower, we MUST reduce it first via attribute checks (social attack)
		if is_instance_valid(node_to_interact) and node_to_interact.willpower > 0:
			var attr_idx = params.attribute_index if params.attribute_index != -1 else 0
			var combat_system := _unit.get_combat_system()
			if combat_system:
				var payload = combat_system.execute_combat(params)
				node_to_interact.interact(_unit, payload if payload else CombatResult.new())

				# IMMEDIATE FINALIZATION: If progress reduced willpower to 0, resolve the interaction now
				if node_to_interact.willpower <= 0:
					finalize_interaction(node_to_interact, params)

				return payload != null
			return false

		# If willpower was already 0, just finalize
		finalize_interaction(node_to_interact, params)
		return true
	)


func _auto_loot_from_node(loot_node: Loot, _loot_coord: Vector2i) -> bool:
	if loot_node == null:
		return false

	var inventory: UnitInventory = _unit.inv.get_inventory()
	if inventory == null:
		return false

	# Signal interaction
	loot_node.interact(_unit, CombatResult.from_dict({"type": GameConstants.Activity.GATHER}))

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

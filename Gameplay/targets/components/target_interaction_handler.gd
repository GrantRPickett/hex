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
## Main interaction dispatcher - all interactions resolve target willpower through combat system
func interact(target: Target, params: CombatResult) -> bool:
	if not is_instance_valid(target):
		return false

	if params == null:
		return false

	if not _unit.res.has_action_available():
		return false

	var combat_system: CombatSystem = _unit.get_combat_system()
	if not combat_system:
		return false

	# Ensure we always apply willpower changes to the actual target passed in.
	# Forecast payloads can drift (e.g., cached CombatResult pointing at a different defender),
	# but the interaction target is authoritative here.
	params.attacker = _unit
	params.defender = target

	var payload = combat_system.execute_combat(params)
	if not payload:
		GameLogger.debug(GameLogger.Category.COMBAT, "[TargetInteractionHandler] Combat failed. unit=%s, target=%s" % [_unit.unit_name, target.get_target_name()])
		return false

	target.interact(_unit, payload)
	_unit.res.consume_action()

	var result = finalize_interaction(target, params)
	# Clear target reference to avoid stale state
	target = null 
	return result


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
	var items_looted: bool = false

	for item in loot_node.inventory.duplicate():
		var success = _try_loot_item(item)
		if success:
			loot_node.inventory.erase(item)
			items_looted = true
			if EventBus: EventBus.loot_collected.emit(loot_node)

	return items_looted

func _try_loot_item(item: InventoryItem) -> bool:
	# Always try to equip first, then fall back to inventory
	var success: bool = _unit.inv.equip_item(item)
	if not success:
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

extends Node

## Manager for the player's roster and inventory state.
## Decouples roster persistence and unit instantiation from the UI.

signal roster_updated

var _roster: PlayerRoster
var _loaded_units: Array[Unit] = []

func _ready() -> void:
	_load_roster()

func _exit_tree() -> void:
	_clear_loaded_units()

## Returns the current roster resource.
func get_roster() -> PlayerRoster:
	if _roster == null:
		_load_roster()
	return _roster

## Returns the current live unit instances.
func get_units() -> Array[Unit]:
	if _loaded_units.is_empty() and _roster != null:
		_instantiate_units()
	return _loaded_units

## Synchronizes and saves the current roster state.
func save_roster() -> void:
	if _roster == null:
		return
	
	InventoryService.save_roster_state(_roster, _loaded_units)
	roster_updated.emit()

## Transfers an item and saves the state.
func transfer_item(item: InventoryItem, source_unit: Unit, target_unit: Unit) -> void:
	InventoryService.handle_item_transfer(item, source_unit, target_unit, _roster)
	save_roster()

## Swaps two items between units or stash.
func swap_items(item_a: InventoryItem, unit_a: Unit, item_b: InventoryItem, unit_b: Unit) -> void:
	# Use stash as temporary buffer if needed, but we can do it directly in service
	InventoryService.handle_item_swap(item_a, unit_a, item_b, unit_b, _roster)
	save_roster()

## Auto-equips the roster and saves the state.
func auto_equip() -> void:
	InventoryService.auto_equip_roster(_roster, _loaded_units)
	save_roster()

## DEBUG: Resets the roster to core defaults and saves.
func debug_reset_roster() -> void:
	var loader := RosterLoader.new()
	_roster = loader._build_core_player_roster()
	_instantiate_units()
	save_roster()
	roster_updated.emit()

## Synchronizes the roster from a combat unit manager and stash.
func sync_from_combat(unit_manager: UnitManager, stash_items: Array[InventoryItem]) -> void:
	if _roster == null:
		return
		
	# 1. Update stash
	_roster.stash_items = stash_items
	
	# 2. Update units that are still in combat
	var live_player_units = unit_manager.get_player_units()
	
	# We need to map our _loaded_units to these live combat units
	# However, in combat, units might be clones or different instances.
	# If they are the SAME instances (because they were passed from here), we can sync.
	# If they are different, we need to match them by name or ID.
	
	for unit in live_player_units:
		_sync_single_unit_to_roster(unit)
	
	save_roster()

## Synchronizes a single combat unit's state back to the roster.
func sync_unit(combat_unit: Unit) -> void:
	if _roster == null:
		return
	_sync_single_unit_to_roster(combat_unit)
	save_roster()

func _sync_single_unit_to_roster(combat_unit: Unit) -> void:
	if not is_instance_valid(combat_unit):
		return
		
	# Find matching unit in _loaded_units
	for loaded in _loaded_units:
		if not is_instance_valid(loaded):
			continue
			
		if loaded.unit_name == combat_unit.unit_name:
			# Sync data from combat_unit to loaded
			var memento = UnitSerializer.create_memento(combat_unit)
			UnitSerializer.restore_from_memento(loaded, memento)
			break

func _load_roster() -> void:
	if SaveManager:
		_roster = SaveManager.load_roster()
	else:
		# Fallback if SaveManager is not yet ready or available
		var loader := RosterLoader.new()
		_roster = loader._build_core_player_roster()
	
	_instantiate_units()

func _instantiate_units() -> void:
	_clear_loaded_units()
	
	if _roster == null:
		return
		
	# Logic mirrored from InventoryManagementMenu._load_roster_data
	if not _roster.roster_entries.is_empty():
		for entry in _roster.roster_entries:
			var unit = RosterPersistence.entry_to_unit(entry)
			if unit:
				_setup_unit(unit)
				_loaded_units.append(unit)
	elif not _roster.units.is_empty():
		for scene in _roster.units:
			if scene:
				var unit = scene.instantiate() as Unit
				_setup_unit(unit)
				_loaded_units.append(unit)

func _setup_unit(unit: Unit) -> void:
	add_child(unit)
	unit.visible = false
	if unit.inv:
		var attrs = unit.inv.get_attributes()
		if attrs:
			attrs.ignore_weather = true

func _clear_loaded_units() -> void:
	for unit in _loaded_units:
		if is_instance_valid(unit):
			unit.queue_free()
	_loaded_units.clear()

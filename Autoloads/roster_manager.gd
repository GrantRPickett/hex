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

## Toggles an item's equipped status.
func toggle_item_equip(item: InventoryItem, unit: Unit) -> void:
	if item == null or unit == null or unit.inv == null:
		return

	if item.equipped:
		unit.inv.unequip_item(item)
	else:
		unit.inv.equip_item(item)

	save_roster()

## Swaps two items between units or stash.
func swap_items(item_a: InventoryItem, unit_a: Unit, item_b: InventoryItem, unit_b: Unit) -> void:
	# Use stash as temporary buffer if needed, but we can do it directly in service
	InventoryService.handle_item_swap(item_a, unit_a, item_b, unit_b, _roster)
	save_roster()

## Adds an item to the global stash.
func add_to_stash(item: InventoryItem) -> void:
	if _roster == null:
		return
	_roster.stash_items.append(item)
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
		var msg: String = "[RosterManager] sync_from_combat failed: Roster is null"
		print(msg)
		push_warning(msg)
		return

	var live_player_units: Array[Unit]= unit_manager.get_player_units()
	var msg_from: String = "[RosterManager] Syncing FROM combat. Found %d live player units." % live_player_units.size()
	print(msg_from)
	push_warning(msg_from)

	# 1. Update stash (Append instead of overwrite)
	if not stash_items.is_empty():
		_roster.stash_items.append_array(stash_items)

	# 2. Update units that are still in combat
	for unit in live_player_units:
		print("[RosterManager] Syncing unit %s from combat state." % unit.unit_name)
		_sync_single_unit_to_roster(unit)

	save_roster()

## Pushes the current roster state back to live combat units.
func sync_to_combat(unit_manager: UnitManager) -> void:
	if _roster == null:
		var msg: String = "[RosterManager] sync_to_combat failed: Roster is null"
		print(msg)
		push_warning(msg)
		return

	var live_player_units: Array[Unit]= unit_manager.get_player_units()
	var roster_units = get_units()

	var msg_to: String = "[RosterManager] Syncing TO combat. Live units: %d, Roster units: %d" % [live_player_units.size(), roster_units.size()]
	print(msg_to)
	push_warning(msg_to)

	for combat_unit in live_player_units:
		var match_found := false
		# Find matching unit in roster_units (which are the source of truth from the menu)
		for loaded in roster_units:
			if not is_instance_valid(loaded):
				continue

			if loaded.unit_name == combat_unit.unit_name:
				# Sync data from the menu's unit back to the live combat unit
				var memento: Dictionary = UnitSerializer.create_memento(loaded)
				UnitSerializer.restore_from_memento(combat_unit, memento)
				var success_msg: String = "[RosterManager] SUCCESS: Synced unit %s back to combat. Items: %d" % [loaded.unit_name, memento.items.size()]
				print(success_msg)
				push_warning(success_msg)
				match_found = true
				break

		if not match_found:
			var warn_msg: String = "[RosterManager] WARNING: No roster match found for live unit: %s" % combat_unit.unit_name
			print(warn_msg)
			push_warning(warn_msg)

	# Emit selection changed twice: once with -1 to clear caches, then with the real index
	var current_idx: int = unit_manager.get_selected_index()
	unit_manager.selection_changed.emit(GameConstants.INVALID_INDEX)
	unit_manager.selection_changed.emit(current_idx)

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
			var memento: Dictionary = UnitSerializer.create_memento(combat_unit)
			UnitSerializer.restore_from_memento(loaded, memento)
			print("[RosterManager] Synced combat unit %s TO roster. Items: %d" % [combat_unit.unit_name, memento.items.size()])
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
			var unit: Unit = RosterPersistence.entry_to_unit(entry)
			if unit:
				_setup_unit(unit)
				_loaded_units.append(unit)
	elif not _roster.units.is_empty():
		for scene in _roster.units:
			if scene:
				var unit: Unit = scene.instantiate() as Unit
				_setup_unit(unit)
				_loaded_units.append(unit)

func _setup_unit(unit: Unit) -> void:
	add_child(unit)
	unit.visible = false
	unit.ignore_weather = true

func _clear_loaded_units() -> void:
	for unit in _loaded_units:
		if is_instance_valid(unit):
			unit.queue_free()
	_loaded_units.clear()

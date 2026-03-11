class_name InventoryService
extends RefCounted

## Service to handle inventory mutations and roster persistence logic.

const LOG_PREFIX := "[InventoryService]"

## Moves an item from a unit or stash to another target.
static func handle_item_transfer(item: InventoryItem, source_unit: Unit, target_unit: Unit, roster: PlayerRoster) -> void:
	if item == null or roster == null:
		return

	# Remove from source
	if source_unit == null:
		roster.stash_items.erase(item)
	else:
		source_unit.inv.remove_item_from_inventory(item)

	# Add to target
	if target_unit == null:
		roster.stash_items.append(item)
	else:
		target_unit.inv.add_item_to_inventory(item)
		target_unit.inv.equip_item(item)

## Automatically assigns best items from stash to units based on their highest stats.
static func auto_equip_roster(roster: PlayerRoster, loaded_units: Array[Unit]) -> void:
	if roster == null or loaded_units.is_empty():
		return

	var all_items: Array[InventoryItem] = []
	all_items.append_array(roster.stash_items)
	roster.stash_items.clear()

	# Strip all current items into a pool
	for unit in loaded_units:
		if unit.inv:
			var inv = unit.inv.get_inventory()
			if inv:
				var items = inv.get_items().duplicate()
				for item in items:
					unit.inv.remove_item_from_inventory(item)
				all_items.append_array(items)

	if all_items.is_empty():
		return

	# Sort pool by highest single modifier value
	all_items.sort_custom(func(a, b):
		var max_a = 0
		for v in a.attribute_modifiers.values(): max_a = max(max_a, v)
		var max_b = 0
		for v in b.attribute_modifiers.values(): max_b = max(max_b, v)
		return max_a > max_b
	)

	var target_count = clampi(ceil(float(all_items.size()) / loaded_units.size()), 1, 6)
	var items_to_process = all_items.duplicate()

	# Pass 1: Primary stats
	for unit in loaded_units:
		var best_stat = _get_highest_stat(unit)
		var i = 0
		while i < items_to_process.size():
			var item = items_to_process[i]
			if item.attribute_modifiers.get(best_stat, 0) > 0:
				if _get_unit_item_count(unit) < target_count:
					unit.inv.add_item_to_inventory(item)
					unit.inv.equip_item(item)
					items_to_process.remove_at(i)
					continue
			i += 1

	# Pass 2: Fill remaining slots
	for unit in loaded_units:
		while _get_unit_item_count(unit) < target_count and not items_to_process.is_empty():
			var item = items_to_process.pop_front()
			unit.inv.add_item_to_inventory(item)
			unit.inv.equip_item(item)

	roster.stash_items = items_to_process

## Synchronizes live unit instances back to the roster and persists to disk.
static func save_roster_state(roster: PlayerRoster, loaded_units: Array[Unit]) -> void:
	if roster == null:
		return


	# 1. Sync unit data to roster entries
	if not loaded_units.is_empty():
		var new_entries: Array[Dictionary] = []
		for unit in loaded_units:
			if is_instance_valid(unit):
				new_entries.append(RosterPersistence.unit_to_entry(unit))
		roster.roster_entries = new_entries

		# 2. Sync entries back to PackedScenes to ensure 'units' array is not stale
		var new_units: Array[PackedScene] = []
		for entry in roster.roster_entries:
			var scene = RosterPersistence.entry_to_scene(entry)
			if scene:
				new_units.append(scene)
		roster.units = new_units
	else:
		print_debug("%s No live units to sync. Preserving existing roster entries." % LOG_PREFIX)

	# 3. Persist
	if SaveManager:
		SaveManager.save_roster(roster)
		
	print("%s Saved roster state in (Units: %d, Stash: %d)" % [
		LOG_PREFIX, roster.units.size(), roster.stash_items.size()
	])

static func _get_highest_stat(unit: Unit) -> String:
	var best_stat = ""
	var best_val = -1
	if unit.inv:
		var attrs = unit.inv.get_attributes()
		if attrs:
			for stat in GameConstants.Attributes.COMBAT_ATTRIBUTES:
				var val = attrs.get_attribute(stat)
				if val > best_val:
					best_val = val
					best_stat = stat
	return best_stat

static func _get_unit_item_count(unit: Unit) -> int:
	if unit.inv and unit.inv.get_inventory():
		return unit.inv.get_inventory().get_items().size()
	return 0

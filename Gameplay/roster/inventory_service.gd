class_name InventoryService
extends RefCounted

## Service to handle inventory mutations and roster persistence logic.

const LOG_PREFIX := "[InventoryService]"

## Moves an item from a unit or stash to another target.
static func handle_item_transfer(item: InventoryItem, source_unit: Unit, target_unit: Unit, roster: PlayerRoster) -> void:
	if item == null or roster == null:
		return

	# Transaction safety: check if target can actually accept the item before removing from source
	if target_unit != null:
		var inv = target_unit.inv.get_inventory()
		if not inv: return
		
		if not item.is_quest_item():
			if SaveManager and SaveManager.is_easy_difficulty():
				pass # Ignore capacity on Easy
			elif inv.get_non_quest_items().size() >= inv.slot_capacity:
				print_debug("[InventoryService] Transfer failed: Target unit %s is full." % target_unit.unit_name)
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
		# Auto-equip when moving to a unit if it's not a quest item
		if not item.is_quest_item():
			target_unit.inv.equip_item(item)

## Swaps two items between their respective owners (units or stash).
static func handle_item_swap(item_a: InventoryItem, unit_a: Unit, item_b: InventoryItem, unit_b: Unit, roster: PlayerRoster) -> void:
	if item_a == null or item_b == null or roster == null:
		return
	
	if item_a == item_b:
		return

	# Capacity check for targets
	if not _can_accept_item_swap(unit_a, item_b, item_a):
		print_debug("[InventoryService] Unit A cannot accept item B in swap.")
		return
	if not _can_accept_item_swap(unit_b, item_a, item_b):
		print_debug("[InventoryService] Unit B cannot accept item A in swap.")
		return

	# 1. Remove both from their sources
	if unit_a == null:
		roster.stash_items.erase(item_a)
	else:
		unit_a.inv.remove_item_from_inventory(item_a)
		
	if unit_b == null:
		roster.stash_items.erase(item_b)
	else:
		unit_b.inv.remove_item_from_inventory(item_b)
		
	# 2. Add them to their new targets
	# Item A goes to Unit B's slot/stash
	if unit_b == null:
		roster.stash_items.append(item_a)
	else:
		unit_b.inv.add_item_to_inventory(item_a)
		unit_b.inv.equip_item(item_a)
		
	# Item B goes to Unit A's slot/stash
	if unit_a == null:
		roster.stash_items.append(item_b)
	else:
		unit_a.inv.add_item_to_inventory(item_b)
		unit_a.inv.equip_item(item_b)

static func _can_accept_item_swap(unit: Unit, item_coming_in: InventoryItem, item_going_out: InventoryItem) -> bool:
	if unit == null: return true # Stash has no limit
	if item_coming_in.is_quest_item(): return true # Quest items have no limit
	
	if SaveManager and SaveManager.is_easy_difficulty():
		return true # Ignore capacity on Easy
	
	var inv = unit.inv.get_inventory()
	if not inv: return false
	
	var current_count = inv.get_non_quest_items().size()
	var net_change = 1
	if not item_going_out.is_quest_item():
		net_change -= 1
		
	return (current_count + net_change) <= inv.slot_capacity

## Automatically assigns best items from stash to units based on their highest stats.
static func auto_equip_roster(roster: PlayerRoster, loaded_units: Array[Unit]) -> void:
	if roster == null or loaded_units.is_empty():
		return

	var all_items: Array[InventoryItem] = []
	all_items.append_array(roster.stash_items)
	roster.stash_items.clear()

	# Strip all current items into a pool
	for unit in loaded_units:
		if is_instance_valid(unit) and unit.inv:
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
		for v in a.get_modifiers().values(): max_a = max(max_a, v)
		var max_b = 0
		for v in b.get_modifiers().values(): max_b = max(max_b, v)
		return max_a > max_b
	)

	var valid_units = loaded_units.filter(func(u): return is_instance_valid(u))
	if valid_units.is_empty():
		return

	var target_count = clampi(ceil(float(all_items.size()) / valid_units.size()), 1, 6)
	var items_to_process = all_items.duplicate()

	# Pass 1: Primary stats
	for unit in valid_units:
		var best_stat = _get_highest_stat(unit)
		var i = 0
		while i < items_to_process.size():
			var item = items_to_process[i]
			if item.get_modifiers().get(best_stat, 0) > 0:
				if _get_unit_item_count(unit) < target_count:
					unit.inv.add_item_to_inventory(item)
					unit.inv.equip_item(item)
					items_to_process.remove_at(i)
					continue
			i += 1

	# Pass 2: Fill remaining slots
	for unit in valid_units:
		while _get_unit_item_count(unit) < target_count and not items_to_process.is_empty():
			var item = items_to_process.pop_front()
			unit.inv.add_item_to_inventory(item)
			unit.inv.equip_item(item)

	roster.stash_items.assign(items_to_process)

## Synchronizes live unit instances back to the roster and persists to disk.
static func save_roster_state(roster: PlayerRoster, loaded_units: Array[Unit]) -> void:
	if roster == null:
		return

	# 1. Map existing entries by name for easy lookup/replacement
	var entries_by_name: Dictionary = {}
	for entry in roster.roster_entries:
		var unit_name = entry.get("unit_name", "")
		if not unit_name.is_empty():
			entries_by_name[unit_name] = entry

	# 2. Sync unit data from live units to roster entries
	if not loaded_units.is_empty():
		for unit in loaded_units:
			if is_instance_valid(unit):
				if unit.is_dead:
					entries_by_name.erase(unit.unit_name)
				else:
					var entry = RosterPersistence.unit_to_entry(unit)
					entries_by_name[unit.unit_name] = entry
			# If unit is invalid (freed) and NOT dead, we keep the existing entry
		
		# Re-assemble the roster_entries array
		roster.roster_entries.assign(entries_by_name.values())

		# 3. Sync entries back to PackedScenes to ensure 'units' array is not stale
		var new_units: Array[PackedScene] = []
		for entry in roster.roster_entries:
			var scene = RosterPersistence.entry_to_scene(entry)
			if scene:
				new_units.append(scene)
		roster.units.assign(new_units)
	else:
		print_debug("%s No live units to sync. Preserving existing roster entries." % LOG_PREFIX)

	# 4. Persist
	if SaveManager:
		SaveManager.save_roster(roster)
		
	print("%s Saved roster state in (Units: %d, Stash: %d)" % [
		LOG_PREFIX, roster.units.size(), roster.stash_items.size()
	])

static func _get_highest_stat(unit: Unit) -> String:
	var best_stat = ""
	var best_val = -1
	for stat in GameConstants.Attributes.COMBAT_ATTRIBUTES:
		var val = unit.get_attribute(stat)
		if val > best_val:
			best_val = val
			best_stat = stat
	return best_stat

static func _get_unit_item_count(unit: Unit) -> int:
	if unit.inv and unit.inv.get_inventory():
		return unit.inv.get_inventory().get_items().size()
	return 0

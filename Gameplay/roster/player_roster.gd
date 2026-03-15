class_name PlayerRoster
extends UnitRoster

@export var roster_entries: Array[Dictionary] = []
@export var stash_items: Array[InventoryItem] = []
@export var quest_stash: Array[InventoryItem] = []

@export var remaining_location_titles: PackedStringArray = []

func update_roster(active_units: Array[Unit], permadeath: bool = true) -> void:
	var active_info = _build_active_entries(active_units)
	var new_entries = active_info.entries

	if not permadeath:
		new_entries = _merge_inactive_entries(new_entries, active_info.counts)

	roster_entries.assign(new_entries)
	_sync_units_from_entries()

func _build_active_entries(active_units: Array[Unit]) -> Dictionary:
	var entries: Array[Dictionary] = []
	var counts: Dictionary = {}

	for unit in active_units:
		if unit == null:
			continue

		var entry: Dictionary = RosterPersistence.unit_to_entry(unit)
		if entry.is_empty():
			continue

		entries.append(entry)
		var unit_name: String = entry.get("unit_name", "")
		if not unit_name.is_empty():
			counts[unit_name] = counts.get(unit_name, 0) + 1

	return {"entries": entries, "counts": counts}

func _merge_inactive_entries(current_entries: Array[Dictionary], active_counts: Dictionary) -> Array[Dictionary]:
	var merged: Array[Dictionary] = current_entries.duplicate()
	var previous_entries = _get_previous_entries()
	var counts_copy: Dictionary = active_counts.duplicate()

	for entry in previous_entries:
		var unit_name: String = entry.get("unit_name", "")
		if unit_name.is_empty():
			merged.append(entry)
			continue

		var remaining: int = counts_copy.get(unit_name, 0)
		if remaining > 0:
			counts_copy[unit_name] = remaining - 1
		else:
			merged.append(entry)

	return merged

func _get_previous_entries() -> Array[Dictionary]:
	if not roster_entries.is_empty():
		return roster_entries

	var legacy_entries: Array[Dictionary] = []
	for scene in units:
		var entry: Dictionary = RosterPersistence.scene_to_entry(scene)
		if not entry.is_empty():
			legacy_entries.append(entry)
	return legacy_entries

func _sync_units_from_entries() -> void:
	var new_units: Array[PackedScene] = []
	for entry in roster_entries:
		var scene: PackedScene = RosterPersistence.entry_to_scene(entry)
		if scene:
			new_units.append(scene)
	units.assign(new_units)


func add_to_stash(items: Array[InventoryItem]) -> void:
	if items.is_empty():
		return
	for item in items:
		if item == null:
			continue
		var stored: InventoryItem = item
		if item.has_method("duplicate_instance"):
			stored = item.duplicate_instance(false)
		else:
			var dup: InventoryItem = item.duplicate(true)
			if dup:
				stored = dup

		if stored.is_quest_item():
			quest_stash.append(stored)
		else:
			stash_items.append(stored)

func clear_stash() -> void:
	stash_items.clear()
	quest_stash.clear()

func get_remaining_location_titles() -> PackedStringArray:
	return remaining_location_titles

func set_remaining_location_titles(titles: PackedStringArray) -> void:
	remaining_location_titles = titles

# --- Memento for stash (quest items, etc.) ---
func create_memento() -> Dictionary:
	var stash: Array = []
	for item in stash_items:
		if item:
			stash.append(item.to_dict())

	var q_stash: Array = []
	for item in quest_stash:
		if item:
			q_stash.append(item.to_dict())

	return {
		"player_stash": stash,
		"quest_stash": q_stash,
		"remaining_location_titles": remaining_location_titles
	}

func restore_from_memento(memento: Dictionary) -> void:
	var data: Array = memento.get("player_stash", [])
	stash_items.clear()
	for d in data:
		var item := InventoryItem.from_dict(d)
		stash_items.append(item)

	var q_data: Array = memento.get("quest_stash", [])
	quest_stash.clear()
	for d in q_data:
		var item := InventoryItem.from_dict(d)
		quest_stash.append(item)

	remaining_location_titles = memento.get("remaining_location_titles", PackedStringArray())

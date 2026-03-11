class_name PlayerRoster
extends UnitRoster

@export var roster_entries: Array[Dictionary] = []
@export var stash_items: Array[InventoryItem] = []
@export var quest_stash: Array[InventoryItem] = []

@export var remaining_location_titles: PackedStringArray = []

func update_roster(active_units: Array[Unit], permadeath: bool = true) -> void:
	var new_entries: Array[Dictionary] = []
	var active_counts: Dictionary = {}

	for unit in active_units:
		if unit == null:
			continue

		var entry = RosterPersistence.unit_to_entry(unit)
		if entry.is_empty():
			continue

		new_entries.append(entry)
		var unit_name: String = entry.get("unit_name", "")
		if not unit_name.is_empty():
			active_counts[unit_name] = active_counts.get(unit_name, 0) + 1

	if not permadeath:
		var previous_entries: Array[Dictionary] = []
		previous_entries.assign(roster_entries)

		if previous_entries.is_empty() and not units.is_empty():
			for scene in units:
				var legacy_entry = RosterPersistence.scene_to_entry(scene)
				if not legacy_entry.is_empty():
					previous_entries.append(legacy_entry)

		for entry in previous_entries:
			var unit_name: String = entry.get("unit_name", "")
			if unit_name.is_empty():
				new_entries.append(entry)
				continue

			var remaining: int = active_counts.get(unit_name, 0)
			if remaining > 0:
				active_counts[unit_name] = remaining - 1
			else:
				new_entries.append(entry)

	roster_entries.assign(new_entries)

	var new_units: Array[PackedScene] = []
	for entry in roster_entries:
		var scene = RosterPersistence.entry_to_scene(entry)
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
			var dup = item.duplicate(true)
			if dup:
				stored = dup
		
		if stored.quest:
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

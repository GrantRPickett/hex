class_name PlayerRoster
extends UnitRoster

@export var roster_entries: Array[Dictionary] = []
@export var stash_items: Array[InventoryItem] = []

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

	roster_entries = new_entries

	var new_units: Array[PackedScene] = []
	for entry in roster_entries:
		var scene = RosterPersistence.entry_to_scene(entry)
		if scene:
			new_units.append(scene)

	units = new_units

func add_to_stash(items: Array[InventoryItem]) -> void:
	if items.is_empty():
		return
	for item in items:
		if item == null:
			continue
		var stored := item
		if item.has_method("duplicate_instance"):
			stored = item.duplicate_instance(false)
		else:
			var dup = item.duplicate(true)
			if dup:
				stored = dup
		stash_items.append(stored)

func clear_stash() -> void:
	stash_items.clear()


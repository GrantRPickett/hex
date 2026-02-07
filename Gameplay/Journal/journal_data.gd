# journal_data.gd
class_name JournalData #, "res://icon.svg" # Using a generic icon for now
extends Resource

@export var sections: Dictionary = {} # Dictionary of section_id -> JournalSection
@export var entries: Dictionary = {}  # Dictionary of entry_id -> JournalEntry

func _init():
	pass

func add_section(section: JournalSection):
	if not sections.has(section.id):
		sections[section.id] = section
	else:
		push_warning("JournalData: Section with ID '%s' already exists." % section.id)

func add_entry(entry: JournalEntry):
	if not entries.has(entry.id):
		entries[entry.id] = entry
		if sections.has(entry.section_id):
			var section: JournalSection = sections[entry.section_id]
			if not entry.id in section.entry_ids:
				section.entry_ids.append(entry.id)
		else:
			push_warning("JournalData: Entry '%s' refers to non-existent section ID '%s'." % [entry.id, entry.section_id])
	else:
		push_warning("JournalData: Entry with ID '%s' already exists." % entry.id)

func get_section(section_id: String) -> JournalSection:
	return sections.get(section_id)

func get_entry(entry_id: String) -> JournalEntry:
	return entries.get(entry_id)

func get_unlocked_entries_in_section(section_id: String) -> Array[JournalEntry]:
	var unlocked_entries: Array[JournalEntry] = []
	if sections.has(section_id):
		var section: JournalSection = sections[section_id]
		for entry_id in section.entry_ids:
			var entry: JournalEntry = entries.get(entry_id)
			if entry and entry.unlocked:
				unlocked_entries.append(entry)
	return unlocked_entries

func get_all_unlocked_entries() -> Dictionary:
	var all_unlocked: Dictionary = {}
	for section_id in sections:
		var section_unlocked_entries = get_unlocked_entries_in_section(section_id)
		if not section_unlocked_entries.is_empty():
			all_unlocked[section_id] = section_unlocked_entries
	return all_unlocked

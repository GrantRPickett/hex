# journal_manager.gd
extends Node

@export var journal_data_resource: Resource = preload("res://Resources/journal_data.tres")

var journal_data: JournalData

signal entry_unlocked(entry_id: String)

func _ready():
	if journal_data_resource:
		journal_data = journal_data_resource.duplicate() # Create an editable instance
		if not journal_data is JournalData:
			push_error("JournalManager: 'journal_data_resource' is not a JournalData resource.")
			journal_data = JournalData.new() # Fallback to empty data
	else:
		journal_data = JournalData.new()

	_initialize_default_content()

func _initialize_default_content():
	# Create default sections in the specified order
	var default_sections = [
		{"id": "goals", "title": "Goals"},
		{"id": "people", "title": "People"},
		{"id": "places", "title": "Places"},
		{"id": "rules", "title": "Rules"}
	]

	for section_data in default_sections:
		if not journal_data.get_section(section_data.id):
			var section = JournalSection.new(section_data.id, section_data.title)
			journal_data.add_section(section)

	# Load entries from Resources/journal/
	var journal_dir = "res://Resources/journal/"
	var dir = DirAccess.open(journal_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var entry = load(journal_dir + file_name)
				if entry is JournalEntry:
					journal_data.add_entry(entry)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("JournalManager: No journal resources found at %s" % journal_dir)

func unlock_entry(entry_id: String) -> bool:
	var entry: JournalEntry = journal_data.get_entry(entry_id)
	if entry and not entry.unlocked:
		entry.unlocked = true
		entry_unlocked.emit(entry_id)
		print("JournalManager: Unlocked entry: %s" % entry_id)
		return true
	elif entry and entry.unlocked:
		print("JournalManager: Entry '%s' already unlocked." % entry_id)
	else:
		push_warning("JournalManager: Attempted to unlock non-existent entry: %s" % entry_id)
	return false

func get_journal_data() -> JournalData:
	return journal_data

func get_entry(entry_id: String) -> JournalEntry:
	return journal_data.get_entry(entry_id)

func get_section(section_id: String) -> JournalSection:
	return journal_data.get_section(section_id)

# Method to prepare data for saving
func get_savable_data() -> Dictionary:
	var savable_entries = {}
	for entry_id in journal_data.entries:
		var entry: JournalEntry = journal_data.entries[entry_id]
		if entry.unlocked:
			savable_entries[entry_id] = true # Store only unlocked status
	return {"unlocked_journal_entries": savable_entries}

# Method to load saved data
func load_savable_data(data: Dictionary):
	if data.has("unlocked_journal_entries"):
		var unlocked_entries_map = data["unlocked_journal_entries"]
		for entry_id in unlocked_entries_map:
			var entry: JournalEntry = journal_data.get_entry(entry_id)
			if entry:
				entry.unlocked = true
			else:
				push_warning("JournalManager: Saved data refers to non-existent entry ID: %s" % entry_id)

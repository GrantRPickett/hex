# journal_ui.gd
class_name JournalUI
extends Control

@onready var sections_list = %SectionsList
@onready var entries_list = %EntriesList
@onready var entry_title_label = %EntryTitleLabel
@onready var entry_content_label = %EntryContentLabel
@onready var back_button = %BackButton

signal back_requested

var current_journal_data: JournalData
var selected_section_id: String = ""
var selected_entry_id: String = ""

func _unhandled_input(event: InputEvent) -> void:
	if $CanvasLayer.visible and event.is_action_pressed("ui_cancel"):
		back_requested.emit()
		get_viewport().set_input_as_handled()

func _ready():
	# Connect signals
	sections_list.item_selected.connect(_on_section_selected)
	entries_list.item_selected.connect(_on_entry_selected)
	if back_button:
		back_button.pressed.connect(func(): back_requested.emit())

	# Initial state
	entry_title_label.text = "Select an Entry"
	entry_content_label.text = "Choose a section and an entry from the lists on the left to view documentation."

	if JournalManager:
		current_journal_data = JournalManager.get_journal_data()
		if current_journal_data:
			_populate_sections()
	else:
		push_error("JournalUI: JournalManager not found!")
		return

func _populate_sections():
	sections_list.clear()
	var first_section_id = ""
	for section_id in current_journal_data.sections:
		var section: JournalSection = current_journal_data.get_section(section_id)
		if section:
			sections_list.add_item(section.title)
			sections_list.set_item_metadata(sections_list.item_count - 1, section.id)
			if first_section_id.is_empty():
				first_section_id = section.id
	if not first_section_id.is_empty():
		# Select the first section by default
		var index = find_item_by_metadata(sections_list, first_section_id)
		if index != -1:
			sections_list.select(index)
			_on_section_selected(index)

func _on_section_selected(index: int):
	# Clear entry details first before populating new ones
	entry_title_label.text = ""
	entry_content_label.text = ""
	selected_entry_id = ""

	selected_section_id = sections_list.get_item_metadata(index)
	_populate_entries(selected_section_id)

func _populate_entries(section_id: String):
	entries_list.clear()
	var first_entry_id = ""
	if current_journal_data:
		var unlocked_entries = current_journal_data.get_unlocked_entries_in_section(section_id)
		for entry in unlocked_entries:
			entries_list.add_item(entry.title)
			entries_list.set_item_metadata(entries_list.item_count - 1, entry.id)
			if first_entry_id.is_empty():
				first_entry_id = entry.id
	if not first_entry_id.is_empty():
		var index = find_item_by_metadata(entries_list, first_entry_id)
		if index != -1:
			entries_list.select(index)
			_on_entry_selected(index)
	else:
		# Fallback if no entries found in this section
		entry_title_label.text = "No Entries"
		entry_content_label.text = "No entries have been unlocked in this section yet."

func find_item_by_metadata(list: ItemList, metadata_value: Variant) -> int:
	for i in range(list.item_count):
		if list.get_item_metadata(i) == metadata_value:
			return i
	return -1

func _on_entry_selected(index: int):
	selected_entry_id = entries_list.get_item_metadata(index)
	var entry: JournalEntry = current_journal_data.get_entry(selected_entry_id)
	if entry:
		entry_title_label.text = entry.title
		entry_content_label.text = entry.content

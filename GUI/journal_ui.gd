class_name JournalUI
extends Control

const LocalizationStrings := preload(FilePaths.Resources.LOCALIZATION_STRINGS)


@onready var sections_list = %SectionsList
@onready var entries_list = %EntriesList
@onready var entry_title_label = %EntryTitleLabel
@onready var entry_content_label = %EntryContentLabel
@onready var back_button = %BackButton

signal back_requested

var current_journal_data: JournalData
var selected_section_id: String = ""
var selected_topic_id: String = ""
var _journal_manager: Node

func _unhandled_input(event: InputEvent) -> void:
	if $CanvasLayer.visible and event.is_action_pressed("ui_cancel"):
		back_requested.emit()
		get_viewport().set_input_as_handled()

func _ready():
	# Connect signals
	sections_list.item_selected.connect(_on_section_selected)
	entries_list.item_selected.connect(_on_topic_selected)
	if back_button:
		back_button.pressed.connect(func(): back_requested.emit())

	JournalManager.journal_cleared.connect(_on_journal_updated)
	JournalManager.entry_unlocked.connect(func(_id): _on_journal_updated())

	# Initial state
	entry_title_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_JOURNAL_SELECT_TOPIC)
	entry_content_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_JOURNAL_SELECT_TOPIC_DESC)

	var manager = _journal_manager if _journal_manager else JournalManager

	if manager:
		current_journal_data = manager.get_journal_data()
		if current_journal_data:
			_populate_sections()
	else:
		push_error("JournalUI: JournalManager not found!")
		return

func setup(p_journal_manager: Node) -> void:
	_journal_manager = p_journal_manager
	if is_node_ready():
		var manager = _journal_manager if _journal_manager else JournalManager
		if manager:
			current_journal_data = manager.get_journal_data()
			if current_journal_data:
				_populate_sections()

func _on_journal_updated():
	if current_journal_data:
		_populate_sections()

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
	# Clear details first before populating new ones
	entry_title_label.text = ""
	entry_content_label.text = ""
	selected_topic_id = ""

	selected_section_id = sections_list.get_item_metadata(index)
	_populate_topics(selected_section_id)

func _populate_topics(section_id: String):
	entries_list.clear() # UI node name remains entries_list to avoid breaking links
	var first_topic_id = ""
	if current_journal_data:
		var unlocked_topics = current_journal_data.get_unlocked_topics_in_section(section_id)
		for topic in unlocked_topics:
			entries_list.add_item(topic.title)
			entries_list.set_item_metadata(entries_list.item_count - 1, topic.id)
			if first_topic_id.is_empty():
				first_topic_id = topic.id
	if not first_topic_id.is_empty():
		var index = find_item_by_metadata(entries_list, first_topic_id)
		if index != -1:
			entries_list.select(index)
			_on_topic_selected(index)
	else:
		# Fallback if no topics found in this section
		entry_title_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_JOURNAL_NO_TOPICS)
		entry_content_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_JOURNAL_NO_TOPICS_DESC)

func find_item_by_metadata(list: ItemList, metadata_value: Variant) -> int:
	for i in range(list.item_count):
		if list.get_item_metadata(i) == metadata_value:
			return i
	return -1

func _on_topic_selected(index: int):
	selected_topic_id = entries_list.get_item_metadata(index)
	var topic: JournalTopic = current_journal_data.get_topic(selected_topic_id)
	if topic:
		entry_title_label.text = topic.title

		# Combine all unlocked entries in this topic
		var unlocked_entries = current_journal_data.get_unlocked_entries_in_topic(selected_topic_id)
		var combined_content = ""
		for entry in unlocked_entries:
			# Optionally add fact titles if they are more than just placeholders
			# combined_content += "[b]" + entry.title + "[/b]\n"
			combined_content += entry.content + "\n\n"

		entry_content_label.text = combined_content.strip_edges()

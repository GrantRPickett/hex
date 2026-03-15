class_name JournalUI
extends Control

const LocalizationStrings := preload(FilePaths.Resources.LOCALIZATION_STRINGS)


@onready var sections_list = %SectionsList
@onready var entries_list = %EntriesList
@onready var entry_title_label = %EntryTitleLabel
@onready var entry_content_label = %EntryContentLabel
@onready var back_button = %BackButton
@onready var _background_panel: Panel = $CanvasLayer/BackgroundPanel
@onready var _hbox: BoxContainer = $CanvasLayer/BackgroundPanel/HBoxContainer
@onready var _vbox_sections: Control = $CanvasLayer/BackgroundPanel/HBoxContainer/VBox_Sections
@onready var _vbox_entries: Control = $CanvasLayer/BackgroundPanel/HBoxContainer/VBox_Entries
@onready var _vbox_content: Control = $CanvasLayer/BackgroundPanel/HBoxContainer/VBox_Content
@onready var _v_separator: Control = $CanvasLayer/BackgroundPanel/HBoxContainer/VSeparator
@onready var _v_separator_2: Control = $CanvasLayer/BackgroundPanel/HBoxContainer/VSeparator2

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
	LocaleService.locale_changed.connect(_on_locale_changed)
	sections_list.item_selected.connect(_on_section_selected)
	entries_list.item_selected.connect(_on_topic_selected)
	if back_button:
		back_button.pressed.connect(func(): back_requested.emit())

	if DisplaySettings:
		DisplaySettings.display_settings_changed.connect(_on_display_settings_changed)
	
	_update_layout()
	
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

func _on_locale_changed():
	_on_journal_updated()
	if not selected_topic_id.is_empty():
		# Refresh the currently displayed topic content
		var index = find_item_by_metadata(entries_list, selected_topic_id)
		if index != -1:
			_on_topic_selected(index)

func _on_display_settings_changed(_orientation: int, _resolution: Vector2i) -> void:
	_update_layout()

func _update_layout() -> void:
	if not is_instance_valid(_background_panel): return
	
	var is_portrait := false
	if DisplaySettings:
		is_portrait = DisplaySettings.get_current_orientation() == DisplayOrientation.Orientation.PORTRAIT
	elif is_inside_tree():
		var viewport_size = get_viewport().get_visible_rect().size
		is_portrait = viewport_size.y > viewport_size.x
	
	if is_portrait:
		_background_panel.anchor_left = 0.02
		_background_panel.anchor_top = 0.02
		_background_panel.anchor_right = 0.98
		_background_panel.anchor_bottom = 0.98
		_background_panel.offset_left = 0
		_background_panel.offset_top = 0
		_background_panel.offset_right = 0
		_background_panel.offset_bottom = 0
		
		_hbox.vertical = true
		
		# In vertical mode, components must expand vertically and share height
		if _vbox_sections:
			_vbox_sections.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_vbox_sections.size_flags_stretch_ratio = 0.2
		if _vbox_entries:
			_vbox_entries.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_vbox_entries.size_flags_stretch_ratio = 0.3
		if _vbox_content:
			_vbox_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_vbox_content.size_flags_stretch_ratio = 0.5
		
		# Hide separators in portrait to save space
		if _v_separator: _v_separator.visible = false
		if _v_separator_2: _v_separator_2.visible = false
	else:
		_background_panel.anchor_left = 0.5
		_background_panel.anchor_top = 0.5
		_background_panel.anchor_right = 0.5
		_background_panel.anchor_bottom = 0.5
		_background_panel.offset_left = -450
		_background_panel.offset_top = -300
		_background_panel.offset_right = 450
		_background_panel.offset_bottom = 300
		
		_hbox.vertical = false
		
		# Restore landscape expansion/stretch ratios
		if _vbox_sections:
			_vbox_sections.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_vbox_sections.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_vbox_sections.size_flags_stretch_ratio = 0.3
		if _vbox_entries:
			_vbox_entries.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_vbox_entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_vbox_entries.size_flags_stretch_ratio = 0.3
		if _vbox_content:
			_vbox_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_vbox_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_vbox_content.size_flags_stretch_ratio = 0.7

		if _v_separator: _v_separator.visible = true
		if _v_separator_2: _v_separator_2.visible = true

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
	var first_section_id: String = ""
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
	var first_topic_id: String = ""
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
		var combined_content: String = ""
		for entry in unlocked_entries:
			# Optionally add fact titles if they are more than just placeholders
			# combined_content += "[b]" + entry.title + "[/b]\n"
			combined_content += entry.content + "\n\n"

		entry_content_label.text = combined_content.strip_edges()

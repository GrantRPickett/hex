extends Resource
class_name JournalData

const JournalSection := preload("res://Gameplay/Journal/journal_section.gd")
const JournalTopic := preload("res://Gameplay/Journal/journal_topic.gd")
const JournalEntry := preload("res://Gameplay/Journal/journal_entry.gd")

@export var sections: Dictionary = {} # Dictionary of section_id -> JournalSection
@export var topics: Dictionary = {} # Dictionary of topic_id -> JournalTopic
@export var entries: Dictionary = {} # Dictionary of entry_id -> JournalEntry

func _init():
	pass

func add_section(section: JournalSection):
	if not sections.has(section.id):
		sections[section.id] = section
	else:
		push_warning("JournalData: Section with ID '%s' already exists." % section.id)

func add_topic(topic: JournalTopic):
	if not topics.has(topic.id):
		topics[topic.id] = topic
		if sections.has(topic.section_id):
			var section: JournalSection = sections[topic.section_id]
			if not topic.id in section.topic_ids:
				section.topic_ids.append(topic.id)
		else:
			push_warning("JournalData: Topic '%s' refers to non-existent section ID '%s'." % [topic.id, topic.section_id])
	else:
		push_warning("JournalData: Topic with ID '%s' already exists." % topic.id)

func add_entry(entry: JournalEntry):
	if not entries.has(entry.id):
		entries[entry.id] = entry
		if topics.has(entry.topic_id):
			var topic: JournalTopic = topics[entry.topic_id]
			if not entry.id in topic.entry_ids:
				topic.entry_ids.append(entry.id)
		else:
			push_warning("JournalData: Entry '%s' refers to non-existent topic ID '%s'." % [entry.id, entry.topic_id])
	else:
		push_warning("JournalData: Entry with ID '%s' already exists." % entry.id)

func get_section(section_id: String) -> JournalSection:
	return sections.get(section_id)

func get_topic(topic_id: String) -> JournalTopic:
	return topics.get(topic_id)

func get_entry(entry_id: String) -> JournalEntry:
	return entries.get(entry_id)

func get_unlocked_topics_in_section(section_id: String) -> Array[JournalTopic]:
	var unlocked_topics: Array[JournalTopic] = []
	if sections.has(section_id):
		var section: JournalSection = sections[section_id]
		for topic_id in section.topic_ids:
			var topic: JournalTopic = topics.get(topic_id)
			if topic:
				# A topic is considered "unlocked" if it has at least one unlocked entry
				var has_unlocked_entry = false
				for entry_id in topic.entry_ids:
					var entry = entries.get(entry_id)
					if entry and entry.unlocked:
						has_unlocked_entry = true
						break
				if has_unlocked_entry:
					unlocked_topics.append(topic)
	return unlocked_topics

func get_unlocked_entries_in_topic(topic_id: String) -> Array[JournalEntry]:
	var unlocked_entries: Array[JournalEntry] = []
	if topics.has(topic_id):
		var topic: JournalTopic = topics[topic_id]
		for entry_id in topic.entry_ids:
			var entry: JournalEntry = entries.get(entry_id)
			if entry and entry.unlocked:
				unlocked_entries.append(entry)
	return unlocked_entries

func get_all_unlocked_entries() -> Dictionary:
	var all_unlocked: Dictionary = {}
	for entry_id in entries:
		var entry: JournalEntry = entries[entry_id]
		if entry.unlocked:
			all_unlocked[entry_id] = entry
	return all_unlocked

extends Resource
class_name JournalData

@export var sections: Dictionary = {} # Dictionary of section_id -> JournalSection
@export var topics: Dictionary = {} # Dictionary of topic_id -> JournalTopic
@export var entries: Dictionary = {} # Dictionary of entry_id -> LevelJournalEntry

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
		if not sections.has(topic.section_id):
			var new_section = JournalSection.new(topic.section_id, topic.section_id.capitalize())
			add_section(new_section)

		var section: JournalSection = sections[topic.section_id]
		if not topic.id in section.topic_ids:
			section.topic_ids.append(topic.id)

func add_entry(entry: LevelJournalEntry):
	if not entries.has(entry.id):
		entries[entry.id] = entry
		if not topics.has(entry.topic_id):
			# Automatically create topic if it doesn't exist
			var new_topic = JournalTopic.new(entry.topic_id, entry.topic_id.capitalize(), entry.section_id if not entry.section_id.is_empty() else "objectives") # Use entry.section_id or default
			add_topic(new_topic)

		var topic: JournalTopic = topics[entry.topic_id]
		if not entry.id in topic.entry_ids:
			topic.entry_ids.append(entry.id)

func has_entry(entry_id: String) -> bool:
	return entries.has(entry_id)

func replace_entry(entry: LevelJournalEntry):
	if entries.has(entry.id):
		var old_entry = entries[entry.id]
		# If topic changed, remove from old topic
		if old_entry.topic_id != entry.topic_id:
			if topics.has(old_entry.topic_id):
				topics[old_entry.topic_id].entry_ids.erase(entry.id)
		
		entries[entry.id] = entry
		
		# Ensure it's in the new topic
		if not topics.has(entry.topic_id):
			var new_topic = JournalTopic.new(entry.topic_id, entry.topic_id.capitalize(), entry.section_id if not entry.section_id.is_empty() else "objectives")
			add_topic(new_topic)
		
		var topic: JournalTopic = topics[entry.topic_id]
		if not entry.id in topic.entry_ids:
			topic.entry_ids.append(entry.id)
	else:
		add_entry(entry)

func get_section(section_id: String) -> JournalSection:
	return sections.get(section_id)

func get_topic(topic_id: String) -> JournalTopic:
	return topics.get(topic_id)

func get_entry(entry_id: String) -> LevelJournalEntry:
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

func get_unlocked_entries_in_topic(topic_id: String) -> Array[LevelJournalEntry]:
	var unlocked_entries: Array[LevelJournalEntry] = []
	if topics.has(topic_id):
		var topic: JournalTopic = topics[topic_id]
		for entry_id in topic.entry_ids:
			var entry: LevelJournalEntry = entries.get(entry_id)
			if entry and entry.unlocked:
				unlocked_entries.append(entry)
	return unlocked_entries

func get_all_unlocked_entries() -> Dictionary:
	var all_unlocked: Dictionary = {}
	for entry_id in entries:
		var entry: LevelJournalEntry = entries[entry_id]
		if entry.unlocked:
			all_unlocked[entry_id] = entry
	return all_unlocked

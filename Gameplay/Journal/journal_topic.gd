# journal_topic.gd
class_name JournalTopic
extends Resource

@export var id: String = ""
@export var title: String = "New Topic"
@export var section_id: String = ""
@export var entry_ids: Array[String] = []

func _init(p_id: String = "", p_title: String = "New Topic", p_section_id: String = ""):
	id = p_id
	title = p_title
	section_id = p_section_id

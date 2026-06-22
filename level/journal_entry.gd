extends Resource
class_name JournalEntry


@export var level_id: StringName = StringName("")
@export var flag_name: StringName = StringName("")

@export var id: String = ""
@export var title: String = "New Entry"
@export_multiline var content: String = ""
@export var unlocked: bool = false
@export var topic_id: String = ""
@export var section_id: String = ""
@export var entry_type: String = "generic"
@export var status: String = "available"
@export var related_id: String = ""

func _init(
	p_id: String = "",
	p_title: String = "New Entry",
	p_content: String = "",
	p_topic_id: String = "",
	p_section_id: String = "",
	p_entry_type: String = "generic",
	p_status: String = "available",
	p_related_id: String = ""
) -> void:
	id = p_id
	title = p_title
	content = p_content
	topic_id = p_topic_id
	section_id = p_section_id
	unlocked = false
	entry_type = p_entry_type
	status = p_status
	related_id = p_related_id

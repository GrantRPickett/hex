# journal_entry.gd
class_name JournalEntry # , "res://icon.svg" # Using a generic icon for now
extends Resource

@export var id: String = ""
@export var title: String = "New Entry"
@export_multiline var content: String = ""
@export var unlocked: bool = false
@export var topic_id: String = ""
@export var entry_type: String = "generic" # e.g., "objective", "stage", "task"
@export var status: String = "available" # e.g., "available", "active", "completed", "failed"
@export var related_id: String = "" # To store objective/stage/task ID if different from entry.id

func _init(p_id: String = "", p_title: String = "New Entry", p_content: String = "", p_topic_id: String = "", p_entry_type: String = "generic", p_status: String = "available", p_related_id: String = ""):
	id = p_id
	title = p_title
	content = p_content
	topic_id = p_topic_id
	unlocked = false
	entry_type = p_entry_type
	status = p_status
	related_id = p_related_id

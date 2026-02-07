# journal_entry.gd
class_name JournalEntry #, "res://icon.svg" # Using a generic icon for now
extends Resource

@export var id: String = ""
@export var title: String = "New Entry"
@export_multiline var content: String = ""
@export var unlocked: bool = false
@export var section_id: String = ""

func _init(p_id: String = "", p_title: String = "New Entry", p_content: String = "", p_section_id: String = ""):
	id = p_id
	title = p_title
	content = p_content
	section_id = p_section_id
	unlocked = false

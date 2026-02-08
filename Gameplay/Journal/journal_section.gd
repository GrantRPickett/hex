# journal_section.gd
class_name JournalSection # , "res://icon.svg" # Using a generic icon for now
extends Resource

@export var id: String = ""
@export var title: String = "New Section"
@export var topic_ids: Array[String] = []

func _init(p_id: String = "", p_title: String = "New Section"):
	id = p_id
	title = p_title

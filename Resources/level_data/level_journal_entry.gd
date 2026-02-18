extends Resource
class_name LevelJournalEntry

const Unit := preload("res://Gameplay/unit.gd")

@export var level_id: StringName = StringName("")
@export var entry_id: StringName = StringName("")
@export var flag_name: StringName = StringName("")
@export var section_id: String = ""
@export var topic_id: String = ""
@export var notes: String = ""

class_name LevelDialogueJournalEntry
extends LevelDialogueEntry

# Journal entry properties (optional - summarizes dialogue outcome)
@export var journal_entry_id: StringName = StringName("")
@export var journal_section_id: String = ""
@export var journal_topic_id: String = ""
@export var journal_notes: String = ""
@export var journal_flag_name: StringName = StringName("")

func has_journal() -> bool:
	return not journal_entry_id.is_empty()

# has_dialogue() from LevelDialogueEntry is inherited if we add it there,
# or we can just check dialogue_resource_path.
func has_dialogue() -> bool:
	return not dialogue_resource_path.is_empty()

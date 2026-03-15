class_name LevelDialogueEntry
extends Resource

@export var level_id: StringName = &""
@export var notes: String = ""
@export var entry_id: StringName = StringName("")
@export var initiator_name: StringName = StringName("")
@export var partner_name: StringName = StringName("")
@export var partner_faction: int = Unit.Faction.PLAYER
@export var coord: Vector2i = Vector2i.ZERO
@export_file("*.dialogue", "*.json", "*.res") var dialogue_resource_path: String = ""
@export var flag_name: StringName = StringName("")
@export var action_label: String = ""
@export var action_hint: String = ""
@export var repeatable := false
@export var requires_near := true
@export var consume_action := true
@export var group_id: StringName = StringName("")
@export var allow_partner_initiation := false

func get_flag_id() -> StringName:
	if not flag_name.is_empty():
		return flag_name
	if not dialogue_resource_path.is_empty():
		return StringName(dialogue_resource_path)
	if not initiator_name.is_empty() and not partner_name.is_empty():
		return StringName("%s_%s_dialogue" % [initiator_name, partner_name])
	return StringName(str(hash(self )))

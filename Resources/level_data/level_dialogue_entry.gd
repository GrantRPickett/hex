extends Resource
class_name LevelDialogueEntry

const Unit := preload("res://Gameplay/unit.gd")
const DialogueResource := preload("res://addons/dialogue_manager/dialogue_resource.gd")

@export var id: StringName = StringName("")
@export var initiator_name: StringName = StringName("")
@export var partner_name: StringName = StringName("")
@export var partner_faction: Unit.Faction = Unit.Faction.PLAYER
@export var coord: Vector2i = Vector2i.ZERO
@export_file("*.dialogue", "*.json", "*.res") var dialogue_resource_path: String = ""
@export var flag_name: StringName = StringName("")
@export var action_label: String = ""
@export var action_hint: String = ""
@export var repeatable := false
@export var requires_adjacent := true
@export var consume_action := true
@export var group_id: StringName = StringName("")
@export var allow_partner_initiation := false

func get_flag_id() -> StringName:
	if not flag_name.is_empty():
		return flag_name
	if not id.is_empty():
		return id
	if not resource_path.is_empty():
		return StringName(resource_path)
	if not dialogue_resource_path.is_empty():
		return StringName(dialogue_resource_path)
	if not initiator_name.is_empty() and not partner_name.is_empty():
		return StringName("%s_%s_dialogue" % [initiator_name, partner_name])
	return StringName(str(hash(self)))

func has_dialogue_resource() -> bool:
	return not dialogue_resource_path.is_empty()

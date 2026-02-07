extends Resource
class_name LevelDialogueEntry

const Unit := preload("res://Gameplay/unit.gd")
const DialogicTimeline := preload("res://addons/dialogic/Resources/timeline.gd")

@export var id: StringName = StringName("")
@export var initiator_name: StringName = StringName("")
@export var partner_name: StringName = StringName("")
@export var partner_faction: Unit.Faction = Unit.Faction.PLAYER
@export var coord: Vector2i = Vector2i.ZERO
@export var timeline: DialogicTimeline
@export_file("*.dtl", "*.tres", "*.res") var timeline_path: String = ""
@export var flag_name: StringName = StringName("")
@export var action_label: String = ""
@export var action_hint: String = ""
@export var repeatable := false
@export var requires_adjacent := true
@export var consume_action := true
@export var group_id: StringName = StringName("")
@export var allow_partner_initiation := false
@export var journal_entry_id: String = ""

func get_flag_id() -> StringName:
	if not flag_name.is_empty():
		return flag_name
	if not id.is_empty():
		return id
	if not resource_path.is_empty():
		return StringName(resource_path)
	if timeline and timeline.resource_path != "":
		return StringName(timeline.resource_path)
	if not timeline_path.is_empty():
		return StringName(timeline_path)
	if not initiator_name.is_empty() and not partner_name.is_empty():
		return StringName("%s_%s_dialogue" % [initiator_name, partner_name])
	return StringName(str(hash(self)))

func has_timeline() -> bool:
	return timeline != null or not timeline_path.is_empty()

extends Resource
class_name LevelDialogueRow

@export var level_id: StringName = StringName("")
@export var entry_id: StringName = StringName("")
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
@export var notes: String = ""

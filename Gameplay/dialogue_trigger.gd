class_name DialogueTrigger
extends Target

const Unit := preload("res://Gameplay/unit.gd")
const LevelDialogueEntry := preload("res://Resources/level_data/level_dialogue_entry.gd")


const DialogicTimeline := preload("res://addons/dialogic/Resources/timeline.gd")
const DialogueTriggerGroup := preload("res://Gameplay/dialogue_trigger_group.gd")

@export var initiator_name: StringName = StringName("")
@export var partner_name: StringName = StringName("")
@export var partner_faction: Unit.Faction = Unit.Faction.PLAYER
@export var dialogue_coord: Vector2i = Vector2i.ZERO
@export var timeline: DialogicTimeline
@export_file("*.dtl", "*.tres", "*.res") var timeline_path: String = ""
@export var action_label: String = ""
@export var action_hint: String = ""
@export var repeatable := false
@export var requires_adjacent := true
@export var consume_action := true
@export var group_id: StringName = StringName("")

var seen := false
var _dialogue_id: StringName = StringName("")
var _group: DialogueTriggerGroup

func configure_from_entry(entry: LevelDialogueEntry) -> void:
	initiator_name = entry.initiator_name
	partner_name = entry.partner_name
	partner_faction = entry.partner_faction
	timeline = entry.timeline
	timeline_path = entry.timeline_path
	action_label = entry.action_label
	action_hint = entry.action_hint
	repeatable = entry.repeatable
	requires_adjacent = entry.requires_adjacent
	consume_action = entry.consume_action
	dialogue_coord = entry.coord
	group_id = entry.group_id
	_dialogue_id = entry.get_flag_id()

func set_group(group: DialogueTriggerGroup) -> void:
	_group = group
	if _group:
		_group.register_trigger(self)

func get_dialogue_id() -> StringName:
	if _dialogue_id.is_empty():
		_dialogue_id = _generate_dialogue_id()
	return _dialogue_id

func get_action_label(partner_display_name: String) -> String:
	if not action_label.is_empty():
		return action_label
	var target_name := partner_display_name
	if target_name.is_empty():
		target_name = String(partner_name)
	return "Talk to %s" % target_name

func get_timeline_resource(cache: Dictionary) -> Resource:
	if timeline:
		return timeline
	if timeline_path.is_empty():
		return null
	if cache.has(timeline_path):
		return cache[timeline_path]
	var resource = load(timeline_path)
	if resource:
		cache[timeline_path] = resource
	return resource

func matches_initiator(name: StringName) -> bool:
	return initiator_name.is_empty() or initiator_name == name

func matches_partner(unit: Unit) -> bool:
	if unit == null:
		return false
	if not partner_name.is_empty() and unit.unit_name != partner_name:
		return false
	if partner_faction != null and unit.faction != partner_faction:
		return false
	return true

func mark_seen(from_group := false) -> void:
	if seen:
		return
	seen = true
	if not from_group and _group:
		_group.mark_seen()

func reset_seen() -> void:
	seen = false

func requires_initiator_action() -> bool:
	return consume_action

func assign_coord_on_grid(grid: TileMapLayer) -> void:
	if grid and grid.tile_set:
		grid_map = grid
		position = grid.map_to_local(dialogue_coord)
		set_external_grid_coord(dialogue_coord)

func _generate_dialogue_id() -> StringName:
	if timeline and timeline.resource_path != "":
		return StringName(timeline.resource_path)
	if not timeline_path.is_empty():
		return StringName(timeline_path)
	if not initiator_name.is_empty() and not partner_name.is_empty():
		return StringName("%s_%s_dialogue" % [initiator_name, partner_name])
	return StringName(str(hash(self)))

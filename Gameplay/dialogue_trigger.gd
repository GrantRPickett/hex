class_name DialogueTrigger
extends Target

const Unit := preload("res://Gameplay/unit.gd")
const LevelDialogueEntry := preload("res://Resources/level_data/level_dialogue_entry.gd")


const DialogueResource := preload("res://addons/dialogue_manager/dialogue_resource.gd")
const DialogueTriggerGroup := preload("res://Gameplay/dialogue_trigger_group.gd")
const LEADER_PLACEHOLDER := StringName("Leader")

@export var initiator_name: StringName = StringName("")
@export var partner_name: StringName = StringName("")
@export var partner_faction: Unit.Faction = Unit.Faction.PLAYER
@export var dialogue_coord: Vector2i = Vector2i.ZERO
@export_file("*.dialogue", "*.json", "*.res") var dialogue_resource_path: String = ""
@export var action_label: String = ""
@export var action_hint: String = ""
@export var repeatable := false
@export var requires_adjacent := true
@export var consume_action := true
@export var group_id: StringName = StringName("")
@export var allow_partner_initiation := false

var seen := false
var _dialogue_id: StringName = StringName("")
var _group: DialogueTriggerGroup

func configure_from_entry(entry: LevelDialogueEntry) -> void:
	initiator_name = entry.initiator_name
	partner_name = entry.partner_name
	partner_faction = entry.partner_faction
	dialogue_resource_path = entry.dialogue_resource_path
	action_label = entry.action_label
	action_hint = entry.action_hint
	repeatable = entry.repeatable
	requires_adjacent = entry.requires_adjacent
	consume_action = entry.consume_action
	dialogue_coord = entry.coord
	group_id = entry.group_id
	_dialogue_id = entry.get_flag_id()
	allow_partner_initiation = entry.allow_partner_initiation

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

func get_dialogue_resource(cache: Dictionary) -> Resource:
	if dialogue_resource_path.is_empty():
		return null
	if cache.has(dialogue_resource_path):
		return cache[dialogue_resource_path]
	var resource = load(dialogue_resource_path)
	if resource:
		cache[dialogue_resource_path] = resource
	return resource

func matches_initiator(target) -> bool:
	return _matches_role(target, initiator_name)

func matches_partner(unit: Unit) -> bool:
	if unit == null:
		return false
	if not _matches_role(unit, partner_name):
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

func allows_partner_initiation() -> bool:
	return allow_partner_initiation

func assign_coord_on_grid(grid: TileMapLayer) -> void:
	if grid and grid.tile_set:
		grid_map = grid
		position = grid.map_to_local(dialogue_coord)
		set_external_grid_coord(dialogue_coord)

func _generate_dialogue_id() -> StringName:
	if not dialogue_resource_path.is_empty():
		return StringName(dialogue_resource_path)
	if not initiator_name.is_empty() and not partner_name.is_empty():
		return StringName("%s_%s_dialogue" % [initiator_name, partner_name])
	return StringName(str(hash(self)))

func _matches_role(target, role_name: StringName) -> bool:
	if role_name.is_empty():
		return true
	if role_name == LEADER_PLACEHOLDER:
		if target is Unit:
			return target.is_player_leader()
		if target is StringName or typeof(target) == TYPE_STRING:
			return String(target) == String(LEADER_PLACEHOLDER)
		return false
	if target is Unit:
		return target.unit_name == role_name
	if target is StringName or typeof(target) == TYPE_STRING:
		return String(target) == String(role_name)
	return false

class_name DialogueTrigger
extends Node
const LEADER_PLACEHOLDER := StringName("Leader")

@export var entry: LevelDialogueEntry

var seen := false
var _dialogue_id: StringName = StringName("")
var _group: DialogueTriggerGroup

func configure_from_entry(new_entry: LevelDialogueEntry) -> void:
	entry = new_entry
	_dialogue_id = entry.get_flag_id()

func set_group(group: DialogueTriggerGroup) -> void:
	_group = group
	if _group:
		_group.register_trigger(self )

func get_dialogue_id() -> StringName:
	if _dialogue_id.is_empty():
		if entry:
			_dialogue_id = entry.get_flag_id()
		else:
			_dialogue_id = StringName(str(hash(self )))
	return _dialogue_id

func get_action_label(partner_display_name: String) -> String:
	if entry and not entry.action_label.is_empty():
		return entry.action_label

	var target_name := partner_display_name
	if target_name.is_empty() and entry:
		target_name = String(entry.partner_name)
	return "Talk to %s" % target_name

func get_dialogue_resource(cache: Dictionary) -> DialogueResource:
	if not entry or entry.dialogue_resource_path.is_empty():
		return null
	if cache.has(entry.dialogue_resource_path):
		return cache[entry.dialogue_resource_path]
	var resource: Resource = load(entry.dialogue_resource_path)
	if resource is DialogueResource:
		cache[entry.dialogue_resource_path] = resource
		return resource
	return null

func matches_initiator(target) -> bool:
	if not entry: return false
	return _matches_role(target, entry.initiator_name)

func matches_partner(unit: Unit) -> bool:
	if unit == null or not entry:
		return false
	if not _matches_role(unit, entry.partner_name):
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
	return entry.consume_action if entry else true

func allows_partner_initiation() -> bool:
	return entry.allow_partner_initiation if entry else false

# func assign_coord_on_grid(grid: TileMapLayer) -> void:
# 	if grid and grid.tile_set and entry:
# 		grid_map = grid
# 		position = grid.map_to_local(entry.coord)
# 		set_external_grid_coord(entry.coord)

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

# Property accessors for entry data
var initiator_name: StringName:
	get: return entry.initiator_name if entry else StringName("")

var partner_name: StringName:
	get: return entry.partner_name if entry else StringName("")

var requires_near: bool:
	get: return entry.requires_near if entry else true

var action_hint: String:
	get: return entry.action_hint if entry else ""

var repeatable: bool:
	get: return entry.repeatable if entry else false

func has_journal() -> bool:
	return entry is LevelDialogueJournalEntry and entry.has_journal()

func get_journal_entry_id() -> StringName:
	return entry.journal_entry_id if entry is LevelDialogueJournalEntry else StringName("")

func get_journal_section_id() -> String:
	return entry.journal_section_id if entry is LevelDialogueJournalEntry else ""

func get_journal_topic_id() -> String:
	return entry.journal_topic_id if entry is LevelDialogueJournalEntry else ""

func get_journal_notes() -> String:
	return entry.journal_notes if entry is LevelDialogueJournalEntry else ""

func get_journal_flag_name() -> StringName:
	return entry.journal_flag_name if entry is LevelDialogueJournalEntry else StringName("")

func get_resource_path() -> String:
	return entry.dialogue_resource_path if entry else ""

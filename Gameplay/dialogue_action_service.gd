class_name DialogueActionService
extends RefCounted

const HexNavigator := preload("res://Gameplay/hex_navigator.gd")
const CommandResult := preload("res://Gameplay/input_commands/command_result.gd")
const Level := preload("res://Resources/Level.gd")
const DialogueTrigger :  = preload("res://Gameplay/dialogue_trigger.gd")
const DEFAULT_DIALOGIC_PATH := NodePath("/root/Dialogic")

signal dialogue_started(flag_id: StringName)
signal dialogue_finished(flag_id: StringName)

const LEADER_PLACEHOLDER := StringName("Leader")
const SEEN_DIALOGUES_KEY := "seen_dialogues"

var _unit_manager: UnitManager
var _hud: Hud
var _hud_controller: HUDController
var _grid: TileMapLayer
var _input_handler: InputHandler
var _input_controller: InputController
var _dialogic_path: NodePath = DEFAULT_DIALOGIC_PATH
var _dialogue_triggers: Dictionary = {}
var _registered_triggers: Array[DialogueTrigger] = []
var _seen_flags: Dictionary = {}
var _current_level_id: StringName = StringName("")
var _active_flag: StringName = StringName("")
var _grid_axis := TileSet.TILE_OFFSET_AXIS_VERTICAL
var _pending_trigger: DialogueTrigger
var _is_dialogue_active := false
var _input_handler_state := {
	"process": false,
	"physics": false,
	"unhandled": false,
}
var _hud_visible_before := true
var _hud_controller_visible_before := true
var _timeline_cache: Dictionary = {}

func setup(
	unit_manager: UnitManager,
	hud: Hud,
	hud_controller: HUDController,
	grid: TileMapLayer,
	input_handler: InputHandler = null,
	input_controller: InputController = null,
	dialogic_path: NodePath = DEFAULT_DIALOGIC_PATH
) -> void:
	_unit_manager = unit_manager
	_hud = hud
	_hud_controller = hud_controller
	_grid = grid
	_input_handler = input_handler
	_input_controller = input_controller
	_dialogic_path = dialogic_path
	_update_grid_axis()
	_load_seen_flags()

func prepare_for_level(level: Level) -> void:
	_cleanup_registered_triggers()
	_dialogue_triggers.clear()
	_pending_trigger = null
	_active_flag = StringName("")
	var new_level_id := _resolve_level_identifier(level)
	#if _current_level_id != new_level_id:
	#	_seen_flags.clear()
	_current_level_id = new_level_id
	print_debug("[DialogueActionService] Prepared for level %s" % String(new_level_id))

func register_triggers(triggers: Array[DialogueTrigger]) -> void:
	_dialogue_triggers.clear()
	_registered_triggers = triggers.duplicate(false)
	_pending_trigger = null
	for trigger in triggers:
		if trigger == null:
			continue
		var id := trigger.get_dialogue_id()
		if id.is_empty():
			continue
		if _seen_flags.get(id, false):
			trigger.mark_seen(true)
		else:
			trigger.reset_seen()
		_dialogue_triggers[id] = trigger
	var trigger_ids: Array[String] = []
	for key in _dialogue_triggers.keys():
		trigger_ids.append(String(key))
	print_debug("[DialogueActionService] Registered %s trigger(s): %s" % [_dialogue_triggers.size(), ", ".join(trigger_ids)])

func append_dialogue_actions(actions: Array[Dictionary], unit: Unit, unit_manager: UnitManager) -> void:
	if unit == null or unit_manager == null or _dialogue_triggers.is_empty():
		if unit == null:
			print_debug("[DialogueActionService] Skipping dialogue actions: unit is null")
		elif unit_manager == null:
			print_debug("[DialogueActionService] Skipping dialogue actions: unit manager missing")
		else:
			print_debug("[DialogueActionService] Skipping dialogue actions: no registered triggers")
		return
	if not unit.has_action_available():
		print_debug("[DialogueActionService] Unit '%s' has no action available; cannot offer talk" % unit.unit_name)
		return
	var unit_index := unit_manager.get_unit_index(unit)
	if unit_index == -1:
		print_debug("[DialogueActionService] Unit '%s' has invalid index; cannot offer talk" % unit.unit_name)
		return
	var unit_coord := unit_manager.get_coord(unit_index)
	var appended := 0
	var leader_flags := "leader=" + str(unit.is_player_leader())
	print_debug("[DialogueActionService] Checking %s dialogue trigger(s) for '%s' (%s) at %s" % [_dialogue_triggers.size(), unit.unit_name, leader_flags, unit_coord])
	for trigger in _dialogue_triggers.values():
		if trigger == null or not _is_trigger_available(trigger):
			continue
		var info := "trigger=%s initiator=%s partner=%s allow_partner=%s requires_adjacent=%s" % [
			trigger.get_dialogue_id(),
			String(trigger.initiator_name),
			String(trigger.partner_name),
			str(trigger.allows_partner_initiation()),
			str(trigger.requires_adjacent)
		]
		print_debug("[DialogueActionService] Evaluating %s" % info)
		if trigger.matches_initiator(unit):
			var partner_indices := _collect_partner_indices(trigger, unit_manager, unit_index, unit_coord)
			if partner_indices.is_empty():
				print_debug("[DialogueActionService] Trigger %s matched initiator '%s' but found no eligible partners (requires_adjacent=%s)." % [trigger.get_dialogue_id(), unit.unit_name, trigger.requires_adjacent])
			for partner_index in partner_indices:
				var partner := unit_manager.get_unit(partner_index)
				var label : String = trigger.get_action_label(partner.unit_name if partner else "")
				actions.append(_build_dialogue_action(trigger, unit_index, partner_index, label))
				appended += 1
		elif trigger.allows_partner_initiation() and trigger.matches_partner(unit):
			var initiator_indices := _collect_initiator_indices(trigger, unit_manager, unit_index, unit_coord)
			if initiator_indices.is_empty():
				print_debug("[DialogueActionService] Trigger %s allows partner start for '%s' but no initiators met the requirements." % [trigger.get_dialogue_id(), unit.unit_name])
			for initiator_idx in initiator_indices:
				var other := unit_manager.get_unit(initiator_idx)
				var label : String = trigger.get_action_label(other.unit_name if other else "")
				actions.append(_build_dialogue_action(trigger, initiator_idx, unit_index, label))
				appended += 1
	if appended == 0:
		print_debug("[DialogueActionService] No dialogue actions available for '%s'" % unit.unit_name)
	else:
		print_debug("[DialogueActionService] Added %s dialogue action(s) for '%s'" % [appended, unit.unit_name])

func start_dialogue(dialogue_id: StringName, initiator_index: int, target_index: int) -> CommandResult:
	var normalized_id := dialogue_id if dialogue_id is StringName else StringName(dialogue_id)
	if normalized_id.is_empty():
		return CommandResult.invalid_payload("Missing dialogue id")
	if _dialogue_triggers.is_empty():
		return CommandResult.failed("No dialogue triggers registered")
	var trigger: DialogueTrigger = _dialogue_triggers.get(normalized_id)
	if trigger == null:
		return CommandResult.invalid_payload("Unknown dialogue id")
	if not _is_trigger_available(trigger):
		return CommandResult.precondition_failed("Dialogue already completed")
	var initiator := _unit_manager.get_unit(initiator_index)
	var target := _unit_manager.get_unit(target_index)
	if initiator == null or target == null:
		return CommandResult.invalid_payload("Units unavailable")
	if not trigger.matches_partner(target):
		return CommandResult.precondition_failed("Partner mismatch")
	if trigger.requires_adjacent:
		if not _are_coords_adjacent(
			_unit_manager.get_coord(initiator_index),
			_unit_manager.get_coord(target_index)
		):
			return CommandResult.precondition_failed("Units must be adjacent")
	var timeline := trigger.get_timeline_resource(_timeline_cache)
	if timeline == null:
		return CommandResult.failed("Timeline missing for dialogue")
	_pending_trigger = trigger
	_active_flag = trigger.get_dialogue_id()
	if trigger.requires_initiator_action() and initiator.has_action_available():
		initiator.consume_action()
	dialogue_started.emit(_active_flag)
	var dialogic := _get_dialogic_handler()
	if dialogic:
		_enter_dialogue_mode()
		var callable := Callable(self, "_on_dialogue_timeline_finished")
		if dialogic.timeline_ended.is_connected(callable):
			dialogic.timeline_ended.disconnect(callable)
		dialogic.timeline_ended.connect(callable, CONNECT_ONE_SHOT)
		dialogic.start(timeline)
	else:
		_finalize_dialogue_completion()
	return CommandResult.success()

func is_dialogue_active() -> bool:
	return _is_dialogue_active

func has_active_dialogue_with(initiator: Unit, partner: Unit) -> bool:
	if initiator == null or partner == null:
		return false

	for trigger in _dialogue_triggers.values():
		if not _is_trigger_available(trigger):
			continue
		if trigger.matches_initiator(initiator) and trigger.matches_partner(partner):
			return true
		if trigger.allows_partner_initiation() and trigger.matches_partner(initiator) and trigger.matches_initiator(partner):
			return true

	return false

func _collect_partner_indices(trigger: DialogueTrigger, unit_manager: UnitManager, initiator_index: int, initiator_coord: Vector2i) -> Array[int]:
	var indices: Array[int] = []
	for idx in range(unit_manager.get_unit_count()):
		if idx == initiator_index:
			continue
		var partner := unit_manager.get_unit(idx)
		if not is_instance_valid(partner):
			continue
		if not trigger.matches_partner(partner):
			continue
		if partner.willpower <= 0:
			continue
		if trigger.requires_adjacent:
			var partner_coord := unit_manager.get_coord(idx)
			if not _are_coords_adjacent(initiator_coord, partner_coord):
				continue
		indices.append(idx)
	return indices

func _collect_initiator_indices(trigger: DialogueTrigger, unit_manager: UnitManager, partner_index: int, partner_coord: Vector2i) -> Array[int]:
	var indices: Array[int] = []
	for idx in range(unit_manager.get_unit_count()):
		if idx == partner_index:
			continue
		var candidate := unit_manager.get_unit(idx)
		if not is_instance_valid(candidate):
			continue
		if not trigger.matches_initiator(candidate):
			continue
		if candidate.willpower <= 0:
			continue
		if trigger.requires_adjacent:
			var coord := unit_manager.get_coord(idx)
			if not _are_coords_adjacent(coord, partner_coord):
				continue
		indices.append(idx)
	return indices

func _are_coords_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return HexNavigator.get_hex_distance(a, b, _grid_axis) == 1

func _build_dialogue_action(trigger: DialogueTrigger, initiator_index: int, partner_index: int, label: String) -> Dictionary:
	return {
		"type": "talk",
		"label": label,
		"available": true,
		"dialogue_id": trigger.get_dialogue_id(),
		"initiator_index": initiator_index,
		"target_index": partner_index,
		"hint": trigger.action_hint,
	}

func _is_trigger_available(trigger: DialogueTrigger) -> bool:
	if trigger == null:
		return false
	if trigger.seen and not trigger.repeatable:
		return false
	if _active_flag == trigger.get_dialogue_id():
		return false
	return true

func _get_dialogic_handler() -> Node:
	var tree := Engine.get_main_loop()
	if tree is SceneTree:
		var root := (tree as SceneTree).root
		if root:
			return root.get_node_or_null(_dialogic_path)
	return null

func _resolve_level_identifier(level: Level) -> StringName:
	if level == null:
		return StringName("")
	if level.resource_path != "":
		return StringName(level.resource_path)
	return StringName(level.display_name)

func _enter_dialogue_mode() -> void:
	if _is_dialogue_active:
		return
	_is_dialogue_active = true
	if is_instance_valid(_hud):
		_hud_visible_before = _hud.visible
		_hud.visible = false
	if is_instance_valid(_hud_controller):
		_hud_controller_visible_before = _hud_controller.visible
		_hud_controller.visible = false
	if is_instance_valid(_input_handler):
		_input_handler_state.process = _input_handler.is_processing()
		_input_handler_state.physics = _input_handler.is_physics_processing()
		_input_handler_state.unhandled = _input_handler.is_processing_unhandled_input()
		_input_handler.set_process(false)
		_input_handler.set_physics_process(false)
		_input_handler.set_process_unhandled_input(false)
	if is_instance_valid(_input_controller):
		_input_controller.set_ui_navigation_mode(true)

func _exit_dialogue_mode() -> void:
	if not _is_dialogue_active:
		return
	_is_dialogue_active = false
	if is_instance_valid(_hud):
		_hud.visible = _hud_visible_before
	if is_instance_valid(_hud_controller):
		_hud_controller.visible = _hud_controller_visible_before
	if is_instance_valid(_input_handler):
		_input_handler.set_process(_input_handler_state.process)
		_input_handler.set_physics_process(_input_handler_state.physics)
		_input_handler.set_process_unhandled_input(_input_handler_state.unhandled)
	if is_instance_valid(_input_controller):
		_input_controller.set_ui_navigation_mode(false)

func _update_grid_axis() -> void:
	if is_instance_valid(_grid) and _grid.tile_set:
		_grid_axis = _grid.tile_set.tile_offset_axis

func _on_dialogue_timeline_finished() -> void:
	_finalize_dialogue_completion()

func _finalize_dialogue_completion() -> void:
	if _pending_trigger:
		# Check if the trigger has a journal entry to unlock
		if _pending_trigger.has_method("get_journal_entry_id"): # Use has_method for safety
			var journal_entry_id = _pending_trigger.get_journal_entry_id()
			if not journal_entry_id.is_empty() and JournalManager:
				JournalManager.unlock_entry(journal_entry_id)

		if not _pending_trigger.repeatable:
			_mark_trigger_seen(_pending_trigger)
	dialogue_finished.emit(_active_flag)
	_active_flag = StringName("")
	_exit_dialogue_mode()
	_pending_trigger = null

func _mark_trigger_seen(trigger: DialogueTrigger) -> void:
	if trigger == null:
		return
	trigger.mark_seen()
	_seen_flags[trigger.get_dialogue_id()] = true
	_save_seen_flags()

func _cleanup_registered_triggers() -> void:
	for trigger in _registered_triggers:
		if is_instance_valid(trigger):
			trigger.queue_free()
	_registered_triggers.clear()


func _load_seen_flags() -> void:
	if not Engine.has_singleton("SaveManager"):
		push_warning("DialogueActionService: SaveManager not found. Seen dialogues will not persist.")
		return
	var loaded_flags = SaveManager.get_value(SEEN_DIALOGUES_KEY, {})
	if loaded_flags is Dictionary:
		_seen_flags = loaded_flags
	else:
		push_warning("DialogueActionService: Invalid data type for seen flags in save. Expected Dictionary.")
		_seen_flags = {}


func _save_seen_flags() -> void:
	if not Engine.has_singleton("SaveManager"):
		return
	SaveManager.set_value(SEEN_DIALOGUES_KEY, _seen_flags)

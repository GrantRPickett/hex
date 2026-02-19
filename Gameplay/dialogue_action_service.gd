class_name DialogueActionService
extends RefCounted

# Global classes - no need to preload:
# HexNavigator, CommandResult, Level, DialogueTrigger, InputActions
const DEFAULT_DIALOG_PATH := NodePath("/root/DialogueManager")

signal dialogue_started(flag_id: StringName)
signal dialogue_finished(flag_id: StringName)
signal journal_entry_unlocked(entry_id: StringName, section_id: String, topic_id: String, notes: String, flag_name: StringName)

const LEADER_PLACEHOLDER := StringName("Leader")
const SEEN_DIALOGUES_KEY := "seen_dialogues"

var _unit_manager: UnitManager
var _hud: Hud
var _hud_controller: HUDController
var _grid: TileMapLayer
var _input_handler: InputHandler
var _input_controller: InputController
var _dialog_path: NodePath = DEFAULT_DIALOG_PATH
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
var _dialogue_resource_cache: Dictionary = {}

func setup(services: GameSessionServices, config: GameSessionBuilder.Config) -> void:
	print_debug("DialogueActionService: setup() called.")
	_unit_manager = services.unit_manager
	_hud = services.hud
	_hud_controller = services.hud_controller
	_grid = config.grid
	_input_handler = config.input_handler
	_input_controller = services.input_controller
	_dialog_path = DEFAULT_DIALOG_PATH # dialogue_manager_path will always be default for now
	_update_grid_axis()
	_load_seen_flags()

func prepare_for_level(level: Level) -> void:
	print_debug("DialogueActionService: prepare_for_level() called for level: %s" % level.display_name if level else "null")
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
	print_debug("DialogueActionService: register_triggers() called with %d triggers." % triggers.size())
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
	print_debug("DialogueActionService: append_dialogue_actions() called for unit: %s" % unit.unit_name if unit else "null")
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
			# Allow dialogue without partner if no specific partner is required
			if partner_indices.is_empty():
				if _can_dialogue_proceed_without_partner(trigger):
					print_debug("[DialogueActionService] Trigger %s matched initiator '%s' - allowing self dialogue (no partner required)." % [trigger.get_dialogue_id(), unit.unit_name])
					var label: String = trigger.get_action_label("")
					actions.append(_build_dialogue_action(trigger, unit_index, unit_index, label))
					appended += 1
				else:
					print_debug("[DialogueActionService] Trigger %s matched initiator '%s' but found no eligible partners (requires_adjacent=%s)." % [trigger.get_dialogue_id(), unit.unit_name, trigger.requires_adjacent])
			else:
				for partner_index in partner_indices:
					var partner := unit_manager.get_unit(partner_index)
					var label: String = trigger.get_action_label(partner.unit_name if partner else "")
					actions.append(_build_dialogue_action(trigger, unit_index, partner_index, label))
					appended += 1
		elif trigger.allows_partner_initiation() and trigger.matches_partner(unit):
			var initiator_indices := _collect_initiator_indices(trigger, unit_manager, unit_index, unit_coord)
			if initiator_indices.is_empty():
				print_debug("[DialogueActionService] Trigger %s allows partner start for '%s' but no initiators met the requirements." % [trigger.get_dialogue_id(), unit.unit_name])
			for initiator_idx in initiator_indices:
				var other := unit_manager.get_unit(initiator_idx)
				var label: String = trigger.get_action_label(other.unit_name if other else "")
				actions.append(_build_dialogue_action(trigger, initiator_idx, unit_index, label))
				appended += 1
	if appended == 0:
		print_debug("[DialogueActionService] No dialogue actions available for '%s'" % unit.unit_name)
	else:
		print_debug("[DialogueActionService] Added %s dialogue action(s) for '%s'" % [appended, unit.unit_name])

func get_trigger_at(coord: Vector2i) -> DialogueTrigger:
	for trigger in _dialogue_triggers.values():
		if is_instance_valid(trigger) and trigger.get_grid_location() == coord:
			return trigger
	return null

func trigger_at_coord(coord: Vector2i, initiator_unit: Unit = null) -> CommandResult:
	var trigger = get_trigger_at(coord)
	if trigger == null:
		return CommandResult.failed("No dialogue trigger at coord %s" % coord)

	if not _is_trigger_available(trigger):
		return CommandResult.precondition_failed("Dialogue already seen and not repeatable")

	var initiator = initiator_unit
	if initiator == null:
		initiator = _unit_manager.get_selected_unit()

	if initiator == null:
		return CommandResult.failed("No initiator unit provided or selected")

	if not trigger.matches_initiator(initiator):
		return CommandResult.precondition_failed("Unit %s cannot initiate this dialogue" % initiator.unit_name)

	var initiator_index = _unit_manager.get_unit_index(initiator)
	var initiator_coord = _unit_manager.get_coord(initiator_index)
	var partner_indices = _collect_partner_indices(trigger, _unit_manager, initiator_index, initiator_coord)

	if partner_indices.is_empty():
		# Check if dialogue can proceed without a specific partner
		if _can_dialogue_proceed_without_partner(trigger):
			print_debug("DialogueActionService: trigger_at_coord allowing self-dialogue for trigger %s" % trigger.get_dialogue_id())
			return start_dialogue(trigger.get_dialogue_id(), initiator_index, initiator_index)
		else:
			return CommandResult.precondition_failed("No valid partner found for dialogue at %s" % coord)

	# Start dialogue with the first valid partner
	return start_dialogue(trigger.get_dialogue_id(), initiator_index, partner_indices[0])

func start_dialogue(dialogue_id: StringName, initiator_index: int, target_index: int) -> CommandResult:
	print_debug("DialogueActionService: start_dialogue() called for ID: %s, initiator: %d, target: %d" % [dialogue_id, initiator_index, target_index])
	var normalized_id := dialogue_id if dialogue_id is StringName else StringName(dialogue_id)
	if normalized_id.is_empty():
		print_debug("DialogueActionService: start_dialogue failed - Missing dialogue id")
		return CommandResult.invalid_payload("Missing dialogue id")
	if _dialogue_triggers.is_empty():
		print_debug("DialogueActionService: start_dialogue failed - No triggers registered")
		return CommandResult.failed("No dialogue triggers registered")
	var trigger: DialogueTrigger = _dialogue_triggers.get(normalized_id)
	if trigger == null:
		print_debug("DialogueActionService: start_dialogue failed - Unknown dialogue id: %s" % normalized_id)
		return CommandResult.invalid_payload("Unknown dialogue id")
	if not _is_trigger_available(trigger):
		print_debug("DialogueActionService: start_dialogue failed - Trigger unavailable")
		return CommandResult.precondition_failed("Dialogue already completed")
	var initiator := _unit_manager.get_unit(initiator_index)
	var target := _unit_manager.get_unit(target_index)
	if initiator == null or target == null:
		print_debug("DialogueActionService: start_dialogue failed - Units unavailable (initiator: %s, target: %s)" % [initiator, target])
		return CommandResult.invalid_payload("Units unavailable")

	# Allow self-dialogue if no specific partner is required
	var is_self_dialogue = (initiator_index == target_index)
	if not is_self_dialogue and not trigger.matches_partner(target):
		print_debug("DialogueActionService: start_dialogue failed - Partner mismatch")
		return CommandResult.precondition_failed("Partner mismatch")

	if not is_self_dialogue and trigger.requires_adjacent:
		if not _are_coords_adjacent(
			_unit_manager.get_coord(initiator_index),
			_unit_manager.get_coord(target_index)
		):
			print_debug("DialogueActionService: start_dialogue failed - Units not adjacent")
			return CommandResult.precondition_failed("Units must be adjacent")
	var dialogue_resource := trigger.get_dialogue_resource(_dialogue_resource_cache)
	if dialogue_resource == null:
		print_debug("DialogueActionService: start_dialogue failed - Dialogue resource missing for dialogue")
		return CommandResult.failed("Dialogue resource missing for dialogue")
	_pending_trigger = trigger
	_active_flag = trigger.get_dialogue_id()
	if trigger.requires_initiator_action() and initiator.has_action_available():
		initiator.consume_action()
	dialogue_started.emit(_active_flag)
	var dialogue_manager := _get_dialogue_manager()
	if dialogue_manager:
		print_debug("DialogueActionService: DialogueManager found. Initiating dialogue.")
		_enter_dialogue_mode()
		var callable := Callable(self, "_on_dialogue_ended") # Name change for consistency
		if dialogue_manager.dialogue_ended.is_connected(callable):
			dialogue_manager.dialogue_ended.disconnect(callable)
		dialogue_manager.dialogue_ended.connect(callable, CONNECT_ONE_SHOT)
		dialogue_manager.show_dialogue_balloon(dialogue_resource) # Using show_dialogue_balloon
		print_debug("DialogueActionService: DialogueManager started successfully.")
	else:
		print_debug("DialogueActionService: DialogueManager NOT found. Finalizing immediately.")
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

func _can_dialogue_proceed_without_partner(trigger: DialogueTrigger) -> bool:
	"""Check if a dialogue can proceed without a specific partner requirement."""
	if trigger == null or trigger.partner_name.is_empty():
		# No specific partner name means no partner is required
		return true
	return false

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

func _get_dialogue_manager() -> Node:
	print_debug("DialogueActionService: _get_dialogue_manager() called.")
	var tree := Engine.get_main_loop()
	if tree is SceneTree:
		var root := (tree as SceneTree).root
		if root:
			print_debug("DialogueActionService: Searching for DialogueManager at path: %s" % _dialog_path)
			var handler = root.get_node_or_null(_dialog_path)
			print_debug("DialogueActionService: _get_dialogue_manager() found handler: %s" % (handler != null))
			return handler
	return null

func _resolve_level_identifier(level: Level) -> StringName:
	if level == null:
		return StringName("")
	if level.resource_path != "":
		return StringName(level.resource_path)
	return StringName(level.display_name)

func _enter_dialogue_mode() -> void:
	print_debug("DialogueActionService: _enter_dialogue_mode() called.")
	if _is_dialogue_active:
		print_debug("DialogueActionService: Dialogue mode already active.")
		return
	_is_dialogue_active = true
	if is_instance_valid(_hud):
		_hud_visible_before = _hud.visible
		_hud.visible = false
	if is_instance_valid(_hud_controller):
		_hud_controller_visible_before = _hud_controller.visible
		_hud_controller.visible = false

func _exit_dialogue_mode() -> void:
	print_debug("DialogueActionService: _exit_dialogue_mode() called.")
	if not _is_dialogue_active:
		return
	_is_dialogue_active = false
	if is_instance_valid(_hud):
		_hud.visible = _hud_visible_before
	if is_instance_valid(_hud_controller):
		_hud_controller.visible = _hud_controller_visible_before

func _update_grid_axis() -> void:
	if is_instance_valid(_grid) and _grid.tile_set:
		_grid_axis = _grid.tile_set.tile_offset_axis


func _on_dialogue_ended(_dialogue_id) -> void:
	print_debug("DialogueActionService: _on_dialogue_ended() called.")
	_finalize_dialogue_completion()

func _finalize_dialogue_completion() -> void:
	print_debug("DialogueActionService: _finalize_dialogue_completion() called. Pending trigger: %s" % (_pending_trigger != null))
	if _pending_trigger:
		if not _pending_trigger.repeatable:
			_mark_trigger_seen(_pending_trigger)

		# Handle Coupled Journal Entry
		if _pending_trigger.has_journal():
			var j_id := _pending_trigger.get_journal_entry_id()
			var j_sec := _pending_trigger.get_journal_section_id()
			var j_top := _pending_trigger.get_journal_topic_id()
			var j_notes := _pending_trigger.get_journal_notes()
			var j_flag := _pending_trigger.get_journal_flag_name()

			print_debug("[DialogueActionService] Unlocking coupled journal entry: %s" % j_id)
			journal_entry_unlocked.emit(j_id, j_sec, j_top, j_notes, j_flag)

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
	var save_manager := _get_save_manager()
	if save_manager == null:
		push_warning("DialogueActionService: SaveManager not found. Seen dialogues will not persist.")
		_seen_flags = {}
		return
	var loaded_flags = save_manager.get_value(SEEN_DIALOGUES_KEY, {})
	if loaded_flags is Dictionary:
		_seen_flags = loaded_flags
	else:
		push_warning("DialogueActionService: Invalid data type for seen flags in save. Expected Dictionary.")
		_seen_flags = {}


func _save_seen_flags() -> void:
	var save_manager := _get_save_manager()
	if save_manager == null:
		return
	save_manager.set_value(SEEN_DIALOGUES_KEY, _seen_flags)

func _skip_dialogue() -> void:
	print_debug("DialogueActionService: _skip_dialogue() called.")
	var dialogue_manager := _get_dialogue_manager()
	if dialogue_manager and is_instance_valid(dialogue_manager): # Disconnect the signal that finalizes completion when dialogue naturally ends
		var callable := Callable(self, "_on_dialogue_ended")
		if dialogue_manager.dialogue_ended.is_connected(callable):
			dialogue_manager.dialogue_ended.disconnect(callable)

		# Dialogue Manager's show_dialogue_balloon returns the balloon scene, which typically has methods to close/hide itself.
		# We don't have a direct reference to the balloon scene from here, so we'll rely on DialogueManager to close it.
		# A direct skip might be a feature to add to the balloon scene itself, or DialogueManager might have a global way to close the active balloon.
		# For now, simply finalize completion.
		push_warning("DialogueActionService: Direct skip for DialogueManager is not directly implemented here. Relying on balloon's own skip/close mechanism.")
		_finalize_dialogue_completion()


func skip_active_dialogue() -> void:
	_skip_dialogue()

func handle_dialogue_request(dialogue_resource_path: String) -> void:
	print_debug("DialogueActionService: handle_dialogue_request() called for path: %s" % dialogue_resource_path)
	if DialogueManager:
		var dialogue_resource = load(dialogue_resource_path)
		if dialogue_resource:
			_enter_dialogue_mode() # Enter dialogue mode
			var callable := Callable(self, "_on_dialogue_ended")
			if DialogueManager.dialogue_ended.is_connected(callable):
				DialogueManager.dialogue_ended.disconnect(callable)
			DialogueManager.dialogue_ended.connect(callable, CONNECT_ONE_SHOT)
			DialogueManager.show_dialogue_balloon(dialogue_resource, "start")
			print_debug("DialogueActionService: DialogueManager started successfully via handle_dialogue_request.")
		else:
			push_error("DialogueActionService: Failed to load dialogue resource from path: ", dialogue_resource_path)
			_finalize_dialogue_completion() # Ensure cleanup if resource fails to load
	else:
		push_error("DialogueActionService: DialogueManager not found or not an autoload.")
		_finalize_dialogue_completion() # Ensure cleanup if DialogueManager is missing

func _get_save_manager() -> Node:
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		var root := (main_loop as SceneTree).root
		if root and root.has_node("SaveManager"):
			return root.get_node("SaveManager")
	return null

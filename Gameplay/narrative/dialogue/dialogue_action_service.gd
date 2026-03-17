class_name DialogueActionService
extends RefCounted

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
var _save_manager: Node
var _dialog_path: NodePath = DEFAULT_DIALOG_PATH

var _trigger_manager: DialogueTriggerManager = DialogueTriggerManager.new()
var _evaluator: DialogueTriggerEvaluator = DialogueTriggerEvaluator.new()

var _current_level_id: StringName = StringName("")
var _active_flag: StringName = StringName("")
var _pending_trigger: DialogueTrigger
var _is_dialogue_active := false
var _autoplay_enabled := false
var _autoplay_delay := GameConstants.UI.DIALOGUE_DEFAULT_AUTO_DELAY
var _text_speed := GameConstants.UI.DIALOGUE_DEFAULT_TEXT_SPEED
var _hud_visible_before := true
var _hud_controller_visible_before := true
var _dialogue_resource_cache: Dictionary = {}
var _level: Level
var _state: GameState
var _dialogue_state: DialogueState = DialogueState.new()
var _active_balloon: Node = null

func setup(state: GameState, config: GameSessionBuilder.Config) -> void:
	print_debug("DialogueActionService: setup() called.")
	_state = state
	_unit_manager = state.unit_manager
	_hud = state.hud
	_hud_controller = state.hud_controller
	_grid = config.grid
	_input_handler = config.input_handler
	_input_controller = state.input_controller
	_save_manager = state.save_manager
	_dialog_path = DEFAULT_DIALOG_PATH

	_trigger_manager.setup(_save_manager)
	_evaluator.setup(_unit_manager, _get_grid_axis())

	if not _dialogue_state.flag_changed.is_connected(_on_flag_changed):
		_dialogue_state.flag_changed.connect(_on_flag_changed)

func _on_flag_changed(flag_name: String, value: Variant) -> void:
	if _save_manager:
		# For now, we assume flags set during a level are level-specific.
		# If we need global flags, we might need a naming convention or a separate method.
		_save_manager.set_level_flag(String(_current_level_id), flag_name, value)

func _get_grid_axis() -> int:
	if is_instance_valid(_grid) and _grid.tile_set:
		return _grid.tile_set.tile_offset_axis
	return TileSet.TILE_OFFSET_AXIS_VERTICAL

func set_level(level: Level) -> void:
	print_debug("DialogueActionService: set_level() called.")
	_level = level
	var new_triggers: Array[DialogueTrigger] = []
	if is_instance_valid(_level) and _level.dialogue_entries:
		for entry in _level.dialogue_entries:
			if is_instance_valid(entry):
				var trigger := DialogueTrigger.new()
				trigger.configure_from_entry(entry)
				if entry.coord != Vector2i.ZERO:
					trigger.assign_coord_on_grid(_grid)
				new_triggers.append(trigger)
	register_triggers(new_triggers)

func prepare_for_level(level: Level) -> void:
	print_debug("DialogueActionService: prepare_for_level() called.")
	_trigger_manager.clear_triggers()
	_pending_trigger = null
	_active_flag = StringName("")
	_current_level_id = _resolve_level_identifier(level)

func register_triggers(triggers: Array[DialogueTrigger]) -> void:
	print_debug("DialogueActionService: register_triggers() called.")
	_trigger_manager.register_triggers(triggers)
	_pending_trigger = null

func append_dialogue_actions(actions: Array[UnitAction], unit: Unit, _um: UnitManager) -> void:
	_evaluator.set_grid_axis(_get_grid_axis())
	_evaluator.append_dialogue_actions(actions, unit, _trigger_manager.get_all_triggers(), _active_flag)

func get_trigger_at(coord: Vector2i) -> DialogueTrigger:
	return _trigger_manager.get_trigger_at(coord)

func trigger_at_coord(coord: Vector2i, initiator_unit: Unit = null) -> CommandResult:
	var trigger: DialogueTrigger = get_trigger_at(coord)
	if trigger == null: return CommandResult.failed("No dialogue trigger at coord %s" % coord)
	if not _evaluator.is_trigger_available(trigger, _active_flag):
		return CommandResult.precondition_failed("Dialogue already seen and not repeatable")

	var initiator: Unit = initiator_unit if initiator_unit else _unit_manager.get_selected_unit()
	if initiator == null: return CommandResult.failed("No initiator unit provided or selected")
	if not trigger.matches_initiator(initiator):
		return CommandResult.precondition_failed("Unit %s cannot initiate this dialogue" % initiator.unit_name)

	var initiator_index: int = _unit_manager.get_unit_index(initiator)
	var initiator_coord: Vector2i = _unit_manager.get_coord(initiator_index)
	var partner_indices: Array[int]= _evaluator.collect_partner_indices(trigger, initiator_index, initiator_coord)

	if partner_indices.is_empty():
		if _evaluator.can_proceed_without_partner(trigger):
			return start_dialogue(trigger.get_dialogue_id(), initiator_index, initiator_index)
		return CommandResult.precondition_failed("No valid partner found for dialogue at %s" % coord)

	return start_dialogue(trigger.get_dialogue_id(), initiator_index, partner_indices[0])

func handle_dialogue_request(id_or_path: String, p2: Variant = &"", p3: int = -1) -> void:
	# Handle flexible arguments: (id_or_path, unit_index) OR (id_or_path, flag_id, unit_index)
	var flag_id: StringName = &""
	var unit_index: int = -1
	
	if p2 is int:
		unit_index = p2
	elif p2 is String or p2 is StringName:
		flag_id = StringName(p2)
		unit_index = p3

	# If unit_index is still -1, use the selected unit
	var initiator_idx: int = unit_index if unit_index >= 0 else (_unit_manager.get_selected_index() if _unit_manager else -1)

	# Try finding by ID first
	var trigger: DialogueTrigger = _trigger_manager.get_trigger(StringName(id_or_path))
	if trigger:
		start_dialogue(trigger.get_dialogue_id(), initiator_idx, initiator_idx)
		return

	# If not an ID, maybe it's a direct resource path
	_start_direct_dialogue(id_or_path, initiator_idx, flag_id)

func _start_direct_dialogue(resource_path: String, initiator_index: int, flag_id: StringName = &"") -> void:
	var dialogue_resource = _load_dialogue_resource(resource_path)
	if dialogue_resource == null:
		push_error("Failed to load dialogue resource at '%s'" % resource_path)
		return

	if _is_dialogue_active:
		return

	_is_dialogue_active = true
	_hide_hud_before_dialogue()

	# Set up dialogue variables/state
	_setup_dialogue_state(initiator_index, initiator_index)

	# Use 'start' as the label for all direct requests for now
	var start_label = "start"
	var balloon = DialogueManager.show_dialogue_balloon(dialogue_resource, start_label, [_dialogue_state])
	if balloon:
		balloon.tree_exited.connect(_on_dialogue_finished)
	else:
		_on_dialogue_finished()

func set_autoplay_enabled(enabled: bool) -> void:
	_autoplay_enabled = enabled

func set_autoplay_delay(delay: float) -> void:
	_autoplay_delay = delay

func set_text_speed(speed: float) -> void:
	_text_speed = speed

func skip_active_dialogue() -> void:
	if is_instance_valid(_active_balloon) and _active_balloon.has_method("skip_typing"):
		_active_balloon.skip_typing()
	elif is_instance_valid(_active_balloon) and _active_balloon.has_method("next"):
		_active_balloon.next()

func is_dialogue_active() -> bool:
	return _is_dialogue_active

func has_active_dialogue_with(initiator: Unit, target: Unit) -> bool:
	if not is_instance_valid(initiator) or not is_instance_valid(target):
		return false
	var coord: Vector2i = target.get_grid_location()
	var trigger: DialogueTrigger = get_trigger_at(coord)
	if trigger == null:
		return false
	return _evaluator.is_trigger_available(trigger, _active_flag) and trigger.matches_initiator(initiator) and trigger.matches_partner(target)

func start_dialogue(dialogue_id: StringName, initiator_index: int, target_index: int) -> CommandResult:
	if _is_dialogue_active:
		return CommandResult.failed("Dialogue already in progress")

	var trigger: DialogueTrigger = _trigger_manager.get_trigger(dialogue_id)
	if trigger == null:
		return CommandResult.failed("Dialogue trigger '%s' not found" % dialogue_id)

	var resource_path: String = trigger.get_resource_path()
	if resource_path.is_empty():
		return CommandResult.failed("Dialogue resource path is empty for trigger '%s'" % dialogue_id)

	var dialogue_resource = _load_dialogue_resource(resource_path)
	if dialogue_resource == null:
		return CommandResult.failed("Failed to load dialogue resource at '%s'" % resource_path)

	_active_flag = dialogue_id
	_is_dialogue_active = true
	_pending_trigger = trigger

	_hide_hud_before_dialogue()

	dialogue_started.emit(_active_flag)
	if EventBus: EventBus.dialogue_started.emit(_active_flag)

	# Set up dialogue variables/state
	_setup_dialogue_state(initiator_index, target_index)

	var start_label = "start"
	var balloon : = DialogueManager.show_dialogue_balloon(dialogue_resource, start_label, [_dialogue_state])
	_active_balloon = balloon
	if balloon:
		balloon.tree_exited.connect(_on_dialogue_finished)
	else:
		_on_dialogue_finished()

	return CommandResult.success()

func _load_dialogue_resource(path: String) -> Resource:
	if _dialogue_resource_cache.has(path):
		return _dialogue_resource_cache[path]

	if FileAccess.file_exists(path):
		var res: Resource = load(path)
		_dialogue_resource_cache[path] = res
		return res
	return null

func _on_dialogue_finished() -> void:
	_is_dialogue_active = false
	if _pending_trigger:
		_pending_trigger.mark_seen()
		if _save_manager:
			_mark_dialogue_seen_globally(_active_flag)

	_show_hud_after_dialogue()
	dialogue_finished.emit(_active_flag)
	if EventBus: EventBus.dialogue_finished.emit(_active_flag)
	_active_flag = StringName("")
	_pending_trigger = null

func _hide_hud_before_dialogue() -> void:
	if _hud:
		_hud_visible_before = _hud.visible
		_hud.hide()
	if _hud_controller:
		_hud_controller_visible_before = _hud_controller.visible
		_hud_controller.hide()

func _show_hud_after_dialogue() -> void:
	if _hud and _hud_visible_before:
		_hud.show()
	if _hud_controller and _hud_controller_visible_before:
		_hud_controller.show()

func _setup_dialogue_state(initiator_index: int, target_index: int) -> void:
	if not _unit_manager: return

	var initiator: Unit = _unit_manager.get_unit(initiator_index)
	var target: Unit = _unit_manager.get_unit(target_index)

	_dialogue_state.initiator_name = initiator.unit_name if is_instance_valid(initiator) else "Someone"
	_dialogue_state.partner_name = target.unit_name if is_instance_valid(target) else "Someone"
	_dialogue_state.level_id = String(_current_level_id)

	# Populate flags from SaveManager
	if _save_manager:
		var flags: Dictionary = _save_manager.get_global_flags()
		flags.merge(_save_manager.get_level_flags(String(_current_level_id)), true)
		_dialogue_state.flags = flags

	# Populate character states
	_dialogue_state.characters = _get_character_states()

func _get_character_states() -> Dictionary:
	var chars := {}
	if not _unit_manager: return chars

	for unit in _unit_manager.get_units():
		if not is_instance_valid(unit): continue

		var stats := {
			"willpower": unit.willpower,
			"max_willpower": unit.max_willpower,
			"faction": unit.faction
		}

		# Add attributes
		for attr_idx: GameConstants.AttributeIndex in GameConstants.COMBAT_ATTRIBUTE_INDICES:
			var attr_name := GameConstants.get_attribute_name(attr_idx)
			stats[attr_name] = unit.get_attribute(attr_idx)

		chars[unit.unit_name] = stats
	return chars

func _mark_dialogue_seen_globally(flag_id: StringName) -> void:
	var seen = _save_manager.get_value(SEEN_DIALOGUES_KEY, [])
	if not seen.has(String(flag_id)):
		seen.append(String(flag_id))
		_save_manager.set_value(SEEN_DIALOGUES_KEY, seen)

func _resolve_level_identifier(level: Level) -> StringName:
	if level == null: return StringName("unknown")
	if not level.level_id.is_empty(): return StringName(level.level_id)
	return StringName(level.resource_path.get_file().get_basename())

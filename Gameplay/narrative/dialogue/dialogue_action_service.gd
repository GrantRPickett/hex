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
var _save_manager: Node
var _dialog_path: NodePath = DEFAULT_DIALOG_PATH

var _trigger_manager := DialogueTriggerManager.new()
var _evaluator := DialogueTriggerEvaluator.new()

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
	_setup_config_sync()

func _setup_config_sync() -> void:
	# Note: Autoloads might not be available if this is called in a weird context,
	# but usually DialogueActionService is created within the session.
	var config = Engine.get_main_loop().root.get_node_or_null("GameConfig")
	if config:
		_autoplay_enabled = config.get_value(config.Paths.DIALOGUE_AUTO_ADVANCE, false)
		# Convert speed multiplier to delay (higher speed = lower delay)
		# 1.0 speed = 2.0s delay, 2.0 speed = 1.0s delay
		var auto_speed = config.get_value(config.Paths.DIALOGUE_AUTO_SPEED, 1.0)
		_autoplay_delay = GameConstants.UI.DIALOGUE_DEFAULT_AUTO_DELAY / max(GameConstants.UI.DIALOGUE_MIN_SPEED_MULTIPLIER, auto_speed)
		
		# Text typing speed
		_text_speed = config.get_value(config.Paths.DIALOGUE_TEXT_SPEED, GameConstants.UI.DIALOGUE_DEFAULT_TEXT_SPEED)
		
		if not config.config_changed.is_connected(_on_config_changed):
			config.config_changed.connect(_on_config_changed)

func _on_config_changed(path: String, value) -> void:
	# We don't have access to config.Paths constants directly here easily 
	# without a hard reference, so we check strings or rely on the instance
	if path == "dialogue/auto_advance_enabled":
		_autoplay_enabled = bool(value)
	elif path == "dialogue/auto_advance_speed":
		_autoplay_delay = GameConstants.UI.DIALOGUE_DEFAULT_AUTO_DELAY / max(GameConstants.UI.DIALOGUE_MIN_SPEED_MULTIPLIER, float(value))
	elif path == "dialogue/text_speed":
		_text_speed = float(value)

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

func append_dialogue_actions(actions: Array[Dictionary], unit: Unit, _um: UnitManager) -> void:
	_evaluator.set_grid_axis(_get_grid_axis())
	_evaluator.append_dialogue_actions(actions, unit, _trigger_manager.get_all_triggers(), _active_flag)

func get_trigger_at(coord: Vector2i) -> DialogueTrigger:
	return _trigger_manager.get_trigger_at(coord)

func trigger_at_coord(coord: Vector2i, initiator_unit: Unit = null) -> CommandResult:
	var trigger = get_trigger_at(coord)
	if trigger == null: return CommandResult.failed("No dialogue trigger at coord %s" % coord)
	if not _evaluator.is_trigger_available(trigger, _active_flag):
		return CommandResult.precondition_failed("Dialogue already seen and not repeatable")

	var initiator = initiator_unit if initiator_unit else _unit_manager.get_selected_unit()
	if initiator == null: return CommandResult.failed("No initiator unit provided or selected")
	if not trigger.matches_initiator(initiator):
		return CommandResult.precondition_failed("Unit %s cannot initiate this dialogue" % initiator.unit_name)

	var initiator_index = _unit_manager.get_unit_index(initiator)
	var initiator_coord = _unit_manager.get_coord(initiator_index)
	var partner_indices = _evaluator.collect_partner_indices(trigger, initiator_index, initiator_coord)

	if partner_indices.is_empty():
		if _evaluator.can_proceed_without_partner(trigger):
			return start_dialogue(trigger.get_dialogue_id(), initiator_index, initiator_index)
		return CommandResult.precondition_failed("No valid partner found for dialogue at %s" % coord)

	return start_dialogue(trigger.get_dialogue_id(), initiator_index, partner_indices[0])

func set_autoplay_enabled(enabled: bool) -> void:
	_autoplay_enabled = enabled

func is_autoplay_enabled() -> bool:
	return _autoplay_enabled

func start_dialogue(dialogue_id: StringName, initiator_index: int, target_index: int) -> CommandResult:
	var normalized_id := dialogue_id if dialogue_id is StringName else StringName(dialogue_id)
	if normalized_id.is_empty(): return CommandResult.invalid_payload("Missing dialogue id")

	var trigger: DialogueTrigger = _trigger_manager.get_trigger(normalized_id)
	if trigger == null: return CommandResult.invalid_payload("Unknown dialogue id")
	if not _evaluator.is_trigger_available(trigger, _active_flag):
		return CommandResult.precondition_failed("Dialogue already completed")

	var initiator := _unit_manager.get_unit(initiator_index)
	var target := _unit_manager.get_unit(target_index)
	if initiator == null or target == null: return CommandResult.invalid_payload("Units unavailable")

	var is_self_dialogue = (initiator_index == target_index)
	if not is_self_dialogue and not trigger.matches_partner(target):
		return CommandResult.precondition_failed("Partner mismatch")

	if not is_self_dialogue and trigger.requires_adjacent:
		if not _evaluator.are_coords_adjacent(_unit_manager.get_coord(initiator_index), _unit_manager.get_coord(target_index)):
			return CommandResult.precondition_failed("Units must be adjacent")

	var dialogue_resource := trigger.get_dialogue_resource(_dialogue_resource_cache)
	if dialogue_resource == null: return CommandResult.failed("Dialogue resource missing")

	_pending_trigger = trigger
	_active_flag = trigger.get_dialogue_id()
	if trigger.requires_initiator_action() and initiator.res.has_action_available():
		initiator.res.consume_action()

	dialogue_started.emit(_active_flag)
	var dialogue_manager := _get_dialogue_manager()
	if dialogue_manager:
		_enter_dialogue_mode()
		var callable := Callable(self , "_on_dialogue_ended")
		if dialogue_manager.dialogue_ended.is_connected(callable):
			dialogue_manager.dialogue_ended.disconnect(callable)
		dialogue_manager.dialogue_ended.connect(callable, CONNECT_ONE_SHOT)
		var balloon = dialogue_manager.show_dialogue_balloon(dialogue_resource)
		_configure_balloon(balloon)
	else:
		_finalize_dialogue_completion()
	return CommandResult.success()

func is_dialogue_active() -> bool:
	return _is_dialogue_active

func has_active_dialogue_with(initiator: Unit, partner: Unit) -> bool:
	if initiator == null or partner == null: return false
	for trigger in _trigger_manager.get_all_triggers():
		if not _evaluator.is_trigger_available(trigger, _active_flag): continue
		if trigger.matches_initiator(initiator) and trigger.matches_partner(partner): return true
		if trigger.allows_partner_initiation() and trigger.matches_partner(initiator) and trigger.matches_initiator(partner): return true
	return false

func _get_dialogue_manager() -> Node:
	var tree := Engine.get_main_loop()
	if tree is SceneTree:
		var root := (tree as SceneTree).root
		if root: return root.get_node_or_null(_dialog_path)
	return null

func _resolve_level_identifier(level: Level) -> StringName:
	if level == null: return StringName("")
	if level.resource_path != "": return StringName(level.resource_path)
	return StringName(level.display_name)

func _enter_dialogue_mode() -> void:
	if _is_dialogue_active: return
	_is_dialogue_active = true
	if is_instance_valid(_hud):
		_hud_visible_before = _hud.visible
		_hud.visible = false
	if is_instance_valid(_hud_controller):
		_hud_controller_visible_before = _hud_controller.visible
		_hud_controller.visible = false

func _exit_dialogue_mode() -> void:
	if not _is_dialogue_active: return
	_is_dialogue_active = false
	if is_instance_valid(_hud): _hud.visible = _hud_visible_before
	if is_instance_valid(_hud_controller): _hud_controller.visible = _hud_controller_visible_before

func _on_dialogue_ended(_dialogue_id) -> void:
	_finalize_dialogue_completion()

func _finalize_dialogue_completion() -> void:
	print_debug("[DialogueActionService] _finalize_dialogue_completion called. active_flag=", _active_flag)
	if _pending_trigger:
		if not _pending_trigger.repeatable:
			_trigger_manager.mark_seen(_pending_trigger)
		if _pending_trigger.has_journal():
			journal_entry_unlocked.emit(
				_pending_trigger.get_journal_entry_id(),
				_pending_trigger.get_journal_section_id(),
				_pending_trigger.get_journal_topic_id(),
				_pending_trigger.get_journal_notes(),
				_pending_trigger.get_journal_flag_name()
			)
	dialogue_finished.emit(_active_flag)
	_active_flag = StringName("")
	_exit_dialogue_mode()
	_pending_trigger = null

func skip_active_dialogue() -> void:
	var dialogue_manager := _get_dialogue_manager()
	if dialogue_manager and is_instance_valid(dialogue_manager):
		var callable := Callable(self , "_on_dialogue_ended")
		if dialogue_manager.dialogue_ended.is_connected(callable):
			dialogue_manager.dialogue_ended.disconnect(callable)
		_finalize_dialogue_completion()

func handle_dialogue_request(dialogue_resource_path: String) -> void:
	print_debug("[DialogueActionService] handle_dialogue_request called for: ", dialogue_resource_path)
	var dialogue_manager := _get_dialogue_manager()
	# Set _active_flag to something derived from the path so it can be tracked
	_active_flag = StringName(dialogue_resource_path.get_file().trim_suffix(".dialogue"))

	if dialogue_manager:
		var dialogue_resource = load(dialogue_resource_path)
		if dialogue_resource:
			print_debug("[DialogueActionService] Showing dialogue balloon for: ", dialogue_resource_path)
			_enter_dialogue_mode()
			var callable := Callable(self , "_on_dialogue_ended")
			if dialogue_manager.dialogue_ended.is_connected(callable):
				dialogue_manager.dialogue_ended.disconnect(callable)
			dialogue_manager.dialogue_ended.connect(callable, CONNECT_ONE_SHOT)
			
			# Prepare outcome state for the dialogue to use
			var context = {}
			if _state and _state.task_controller:
				context["is_victory"] = _state.task_controller.is_task_reached()
				context["is_failure"] = _state.task_controller.is_game_over()
			
			var balloon = dialogue_manager.show_dialogue_balloon(dialogue_resource, "start", [context])
			_configure_balloon(balloon)
		else:
			print_debug("[DialogueActionService] Failed to load dialogue resource: ", dialogue_resource_path)
			_finalize_dialogue_completion()
	else:
		print_debug("[DialogueActionService] DialogueManager not found at: ", _dialog_path)
		_finalize_dialogue_completion()

func _configure_balloon(balloon: Node) -> void:
	if not is_instance_valid(balloon):
		return
	
	# Try to find the DialogueLabel component in the balloon
	var label = balloon.find_child("DialogueLabel", true, false)
	if label:
		# Apply text typing speed
		if "seconds_per_step" in label:
			label.seconds_per_step = GameConstants.UI.DIALOGUE_BASE_TEXT_STEP / max(GameConstants.UI.DIALOGUE_MIN_SPEED_MULTIPLIER, _text_speed)
		
		# Setup autoplay if enabled
		if _autoplay_enabled and label.has_signal("finished_typing"):
			if not label.finished_typing.is_connected(_on_label_finished_typing):
				label.finished_typing.connect(_on_label_finished_typing.bind(balloon))

func _on_label_finished_typing(balloon: Node) -> void:
	if not _autoplay_enabled or not is_instance_valid(balloon):
		return
	
	# Wait for the autoplay delay
	var tree = Engine.get_main_loop()
	if tree is SceneTree:
		await tree.create_timer(_autoplay_delay).timeout
		
		if not is_instance_valid(balloon):
			return
			
		# Advance if it's waiting for input and doesn't have responses
		if "is_waiting_for_input" in balloon and balloon.is_waiting_for_input:
			if "dialogue_line" in balloon and balloon.dialogue_line.responses.is_empty():
				print_debug("[DialogueActionService] Autoplay advancing dialogue...")
				if balloon.has_method("next"):
					balloon.next(balloon.dialogue_line.next_id)

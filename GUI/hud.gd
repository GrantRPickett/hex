class_name Hud
extends CanvasLayer

signal action_executed(action_type: String)
signal action_refresh_requested
signal menu_requested(menu_type: String, data: Dictionary)

const UI_MARGIN := 20.0
const PANEL_PADDING := 10.0
const DEFAULT_PANEL_SIZE := Vector2(200, 80)
const UNIT_PANEL_SIZE := Vector2(200, 100)
const ACTIONS_PANEL_SIZE := Vector2(220, 220)
const PREVIEW_PANEL_SIZE := Vector2(200, 120)
const TASK_PANEL_SIZE := Vector2(200, 120)
const TERRAIN_PANEL_SIZE := Vector2(200, 100)
const BUTTON_MIN_SIZE := Vector2(160, 30)
const HINT_TEXT_COLOR := Color(1, 1, 0.8)
const WARNING_DURATION := 2.5
const WARNING_COLOR := Color(1, 0.2, 0.2) # Red
const WARNING_FONT_SIZE := 18
var _warning_overlay: Control

var _current_unit: Unit
var _current_unit_index: int = -1
var _terrain_map
var _unit_manager: UnitManager
var _turn_controller: TurnController
var _input_controller: InputController # Reference to InputController for command routing
var _task_manager: TaskManager
var _animation_service
var _command_refresh_in_progress := false

func _ready() -> void:
	print_debug("[Hud] _ready called. Inside tree: ", is_inside_tree())
	show() # Ensure we are visible as a CanvasLayer
	if not has_node("ActionsPanel"): # A good indicator that UI is pre-built
		_create_default_ui()

func setup(state: GameState, _config: GameSessionBuilder.Config) -> void:
	print_debug("[Hud] setup called")
	_unit_manager = state.unit_manager
	_turn_controller = state.turn_controller
	_input_controller = state.input_controller
	_task_manager = state.task_manager
	print_debug("Info.setup: input_controller set=", _input_controller != null)

func set_animation_service(service) -> void:
	_animation_service = service

func on_action_selected(action: Dictionary) -> void:
	var action_type: String = action.get("type", "unknown")
	print_debug("Info._on_action_button_pressed: action=%s" % [action_type])

	if not _sync_selected_unit():
		print_debug("Info._on_action_button_pressed: no current unit or invalid index")
		return

	if not await _resolve_tentative_move_if_needed():
		return

	var success := await _execute_action(action)
	print_debug("Info._on_action_button_pressed: execution result success=%s" % success)

	if success:
		action_executed.emit(action_type)

func on_command_executed(_command_name: String, result: CommandResult) -> void:
	if result == null or result.is_failure():
		return
	if _command_refresh_in_progress:
		return
	_command_refresh_in_progress = true
	var tree := get_tree()
	if tree:
		await tree.process_frame
	_command_refresh_in_progress = false
	if not is_inside_tree():
		return
	_refresh_actions_after_command()

func _refresh_actions_after_command() -> void:
	var has_selection := _sync_selected_unit()
	if has_selection and _turn_controller and _unit_manager and _terrain_map:
		var has_movement = _current_unit.movement.has_move_available()
		var available_actions = UnitActionManager.get_available_actions(_current_unit, _terrain_map, _unit_manager)
		var has_actions = not available_actions.is_empty() and _current_unit.res.has_action_available()

		if not has_movement and not has_actions:
			_turn_controller.complete_player_activation(_current_unit_index)
			print_debug("DBG action handler: turn completed (no movement, no actions remaining)")

	action_refresh_requested.emit()

func _sync_selected_unit() -> bool:
	if _unit_manager == null:
		_current_unit = null
		_current_unit_index = -1
		return false
	_current_unit = _unit_manager.get_selected_unit()
	_current_unit_index = _unit_manager.get_selected_index()
	return _current_unit != null and _current_unit_index >= 0

func _resolve_tentative_move_if_needed() -> bool:
	if _current_unit == null or not _current_unit.movement.has_tentative_move():
		return true
	print_debug("Info.on_action_selected: resolving tentative move first")
	if _input_controller:
		_input_controller._execute_command("confirm_move")
		await _await_tentative_resolution()
	if _current_unit == null or _current_unit.movement.has_tentative_move():
		print_debug("Info.on_action_selected: tentative move still pending; aborting action")
		return false
	return true

func _create_default_ui() -> void:
	pass # All panels are now created by HUDComponentFactory

func _create_panel(p_name: String, p_pos: Vector2, p_size: Vector2) -> Panel:
	var p = Panel.new()
	p.name = p_name
	p.position = p_pos
	p.size = p_size
	return p

func _create_vbox(p_name: String, parent: Control, padding: float) -> VBoxContainer:
	var vb = VBoxContainer.new()
	vb.name = p_name
	vb.position = Vector2(padding, padding)
	vb.size = parent.size - Vector2(padding * 2, padding * 2)
	parent.add_child(vb)
	return vb

func _create_label(p_name: String, parent: Node) -> Label:
	var l = Label.new()
	l.name = p_name
	parent.add_child(l)
	return l

func show_warning_message(text: String) -> void:
	if text.is_empty():
		return
	if not is_inside_tree():
		return
	if not is_instance_valid(_warning_overlay):
		_warning_overlay = Control.new()
		_warning_overlay.name = "WarningOverlay"
		_warning_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_warning_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(_warning_overlay)
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", WARNING_FONT_SIZE)
	label.add_theme_color_override("font_color", WARNING_COLOR)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.modulate = Color(1, 1, 1, 0)
	_warning_overlay.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	if _animation_service:
		_animation_service.request_warning_flash(label)
	else:
		var tree := get_tree()
		if tree:
			label.modulate = Color(label.modulate.r, label.modulate.g, label.modulate.b, 1.0)
			var timer := tree.create_timer(WARNING_DURATION)
			timer.timeout.connect(func():
				if is_instance_valid(label):
					label.queue_free()
			)

func _execute_action(action: Dictionary) -> bool:
	var action_type = action.get("type", "unknown")
	print_debug("Info._execute_action: starting execution for action=%s" % action_type)

	if action_type == "open_attack_menu":
		menu_requested.emit("attack_menu", action)
		return true

	if action_type == GameConstants.Commands.MOVE_AND_INTERACT_TYPE:
		return await _execute_move_and_interact_action(action)

	if not _input_controller:
		print_debug("Info._execute_action: InputController is missing")
		return false

	var result = _try_execute_mapped_command(action_type, action)
	if _command_success(result):
		print_debug("Info._execute_action: Command execution successful")
		return true
	if result is CommandResult:
		print_debug("Info._execute_action: Command execution failed: ", result.get_error_message())
		return false

	print_debug("Info._execute_action: no matching command found or direct execution fallback for action=%s" % action_type)
	return false

func _try_execute_mapped_command(action_type: String, action: Dictionary) -> CommandResult:
	match action_type:
		GameConstants.Commands.WAIT:
			return _run_input_command(GameConstants.Commands.WAIT)
		GameConstants.Interactions.ATTACK:
			return _execute_attack_command(action)
		GameConstants.Interactions.AID:
			return _execute_aid_command(action)
		GameConstants.Interactions.VISIT:
			return _run_input_command(GameConstants.Commands.VISIT, action)
		GameConstants.Interactions.EXPLORE:
			return _run_input_command(GameConstants.Commands.EXPLORE, action)
		GameConstants.Interactions.TRAPPED:
			return _run_input_command(GameConstants.Commands.TRAPPED, action)
		GameConstants.Interactions.CONVINCE:
			return _execute_convince_command(action)
		GameConstants.Interactions.LOOT, GameConstants.Interactions.GATHER:
			return _execute_loot_command(action)
		GameConstants.Interactions.SKILL:
			return _execute_skill_command(action)
		GameConstants.Interactions.TALK:
			return _execute_talk_command(action)
	return null

func _run_input_command(command_name: String, payload = null) -> CommandResult:
	if _input_controller == null:
		return null
	return _input_controller._execute_command(command_name, payload)

func _command_success(result) -> bool:
	return result is CommandResult and not result.is_failure()

func _execute_attack_command(action: Dictionary) -> CommandResult:
	if _unit_manager == null:
		return null
	var target = action.get("target")
	if not target:
		return null
	var target_idx = _unit_manager.get_unit_index(target)
	return _execute_attack_payload(target_idx, action.get("attribute_index", 0))

func _execute_attack_payload(target_idx: int, attribute_index: int) -> CommandResult:
	if target_idx < 0:
		return null
	return _run_input_command(GameConstants.Commands.ATTACK, {
		"attacker_index": _current_unit_index,
		"target_index": target_idx,
		"attribute_index": attribute_index
	})

func _execute_aid_command(action: Dictionary) -> CommandResult:
	if _unit_manager == null:
		return null
	var target = action.get("target")
	if not target:
		return null
	var target_idx = _unit_manager.get_unit_index(target)
	if target_idx < 0:
		return null
	return _run_input_command(GameConstants.Commands.AID, {
		"helper_index": _current_unit_index,
		"target_index": target_idx,
		"attribute_index": action.get("attribute_index", 0)
	})

func _execute_convince_command(action: Dictionary) -> CommandResult:
	if _unit_manager == null:
		return null
	var target = action.get("target")
	if not target:
		return null
	var target_idx = _unit_manager.get_unit_index(target)
	return _execute_convince_payload(target_idx)

func _execute_convince_payload(target_idx: int) -> CommandResult:
	if target_idx < 0:
		return null
	return _run_input_command(GameConstants.Commands.CONVINCE, {
		"initiator_index": _current_unit_index,
		"target_index": target_idx
	})

func _execute_loot_command(action: Dictionary) -> CommandResult:
	var coord: Vector2i = action.get("loot_coord", GameConstants.INVALID_COORD)
	if coord == GameConstants.INVALID_COORD and _current_unit:
		coord = _current_unit.get_grid_location()
	return _execute_loot_payload(coord)

func _execute_loot_payload(coord: Vector2i) -> CommandResult:
	if _current_unit == null or coord == GameConstants.INVALID_COORD:
		return null
	return _run_input_command(GameConstants.Commands.LOOT, {
		"looter_index": _current_unit_index,
		"loot_coord": coord
	})

func _execute_skill_command(action: Dictionary) -> CommandResult:
	var skill = action.get("skill")
	if not skill:
		return null
	return _run_input_command(GameConstants.Commands.USE_SKILL, {
		"unit_index": _current_unit_index,
		"skill": skill
	})

func _execute_talk_command(action: Dictionary) -> CommandResult:
	var target_idx = int(action.get("target_index", -1))
	var dialogue_id = action.get("dialogue_id", "")
	if target_idx < 0 or dialogue_id.is_empty():
		return null
	return _run_input_command(GameConstants.Commands.TALK, {
		"initiator_index": action.get("initiator_index", _current_unit_index),
		"target_index": target_idx,
		"dialogue_id": dialogue_id
	})

func _await_tentative_resolution() -> void:
	if not is_instance_valid(self ):
		return
	for _i in range(5):
		if _current_unit == null or not _current_unit.movement.has_tentative_move():
			return
		await get_tree().process_frame

func _execute_move_and_interact_action(action: Dictionary) -> bool:
	if _input_controller == null:
		return false
	var move_coord: Vector2i = action.get("target_move_coord", GameConstants.INVALID_COORD)
	if move_coord == GameConstants.INVALID_COORD:
		return false
	if not await _move_unit_to_coord(move_coord):
		return false

	var interact_type: String = action.get("interact_action_type", "")
	match interact_type:
		GameConstants.Interactions.ATTACK:
			var target_idx = int(action.get("interact_target_uid", -1))
			var attr_idx = action.get("attribute_index", 0)
			return _command_success(_execute_attack_payload(target_idx, attr_idx))
		GameConstants.Interactions.LOOT, GameConstants.Interactions.GATHER:
			var loot_coord: Vector2i = action.get("interact_target_coord", _current_unit.get_grid_location() if _current_unit else GameConstants.INVALID_COORD)
			return _command_success(_execute_loot_payload(loot_coord))
		GameConstants.Interactions.TRAPPED:
			return _command_success(_run_input_command(GameConstants.Interactions.TRAPPED, action))
		GameConstants.Interactions.EXPLORE:
			return _command_success(_run_input_command(GameConstants.Interactions.EXPLORE, action))
		GameConstants.Interactions.VISIT:
			return _command_success(_run_input_command(GameConstants.Interactions.VISIT, action))
		GameConstants.Interactions.CONVINCE:
			var target_idx = int(action.get("interact_target_uid", -1))
			return _command_success(_execute_convince_payload(target_idx))
		_:
			return false

func _move_unit_to_coord(target_coord: Vector2i) -> bool:
	if _input_controller == null or _unit_manager == null:
		return false
	var current_coord = _unit_manager.get_coord(_current_unit_index)
	if current_coord == target_coord:
		return true
	var move_result = _input_controller._execute_command(GameConstants.Commands.MOVE_TO_COORD, {"coord": target_coord})
	if move_result == null or move_result.is_failure():
		return false
	await get_tree().process_frame
	_current_unit = _unit_manager.get_selected_unit()
	if _current_unit == null:
		return false
	if not _current_unit.movement.has_tentative_move():
		return _unit_manager.get_coord(_current_unit_index) == target_coord
	var tentative_coord = _current_unit.movement.get_tentative_grid_coord()
	if tentative_coord != target_coord:
		_input_controller._execute_command(GameConstants.Commands.CANCEL_MOVE)
		await _await_tentative_resolution()
		_current_unit = _unit_manager.get_selected_unit()
		return _unit_manager.get_coord(_current_unit_index) == target_coord
	var confirm_result = _input_controller._execute_command(GameConstants.Commands.CONFIRM_MOVE)
	if confirm_result == null or confirm_result.is_failure():
		return false
	await _await_tentative_resolution()
	_current_unit = _unit_manager.get_selected_unit()
	return _current_unit != null and _unit_manager.get_coord(_current_unit_index) == target_coord

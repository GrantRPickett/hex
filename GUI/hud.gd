class_name Hud
extends CanvasLayer

signal action_executed(action_type: int)
signal action_refresh_requested
signal menu_requested(menu_type: String, data: PlayerAction)

const WARNING_DURATION := 2.5
const WARNING_COLOR := GameConstants.Colors.WARNING
const WARNING_FONT_SIZE := 18

var _unit_manager: UnitManager
var _turn_controller: TurnController
var _input_controller: InputController
var _task_manager: TaskManager
var _animation_service
var _action_executor: HudActionExecutor

var _current_unit: Unit
var _current_unit_index: int = -1
var _terrain_map
var _warning_overlay: Control
var _command_refresh_in_progress := false
var _processing_action := false

# Initialization & Setup

func _ready() -> void:
	show()
	if not has_node("ActionsPanel"):
		_create_default_ui()

func setup(state: GameState, _config: GameSessionBuilder.Config) -> void:
	_unit_manager = state.unit_manager
	_turn_controller = state.turn_controller
	_input_controller = state.input_controller
	_task_manager = state.task_manager
	_action_executor = HudActionExecutor.new(self, _unit_manager, _input_controller)

func set_animation_service(service) -> void:
	_animation_service = service

func _create_default_ui() -> void:
	pass # Panels created by HUDComponentFactory

# Action & Command Handling

func on_action_selected(action: PlayerAction) -> void:
	if _processing_action: return

	if not _sync_selected_unit(): return
	if not await _resolve_tentative_move_if_needed(): return

	_processing_action = true
	var success = await _action_executor.execute_action(action, _current_unit, _current_unit_index)
	if success:
		action_executed.emit(action.type)
	_processing_action = false

func on_command_executed(_command_id: GameConstants.Commands.CommandID, result: CommandResult) -> void:
	if result == null or result.is_failure() or _command_refresh_in_progress: return

	_command_refresh_in_progress = true
	if get_tree(): await get_tree().process_frame
	_command_refresh_in_progress = false

	if is_inside_tree(): _refresh_actions_after_command()

func _refresh_actions_after_command() -> void:
	if _sync_selected_unit() and _turn_controller and _unit_manager and _terrain_map:
		var has_movement = _current_unit.movement.has_move_available()
		var available = PlayerActionManager.get_available_actions(_current_unit, _terrain_map, _unit_manager)
		var has_actions: bool = not available.is_empty() and _current_unit.res.has_action_available()

		if not has_movement and not has_actions:
			_turn_controller.complete_player_activation(_current_unit_index)

	action_refresh_requested.emit()

func _sync_selected_unit() -> bool:
	if not _unit_manager: return false
	_current_unit = _unit_manager.get_selected_unit()
	_current_unit_index = _unit_manager.get_selected_index()
	return _current_unit != null and _current_unit_index >= 0

func _resolve_tentative_move_if_needed() -> bool:
	if not _current_unit or not _current_unit.movement.has_tentative_move(): return true
	if _input_controller:
		_input_controller.execute_command(GameConstants.Commands.CommandID.CONFIRM_MOVE)
		await _await_tentative_resolution()
	return _current_unit != null and not _current_unit.movement.has_tentative_move()

func _await_tentative_resolution() -> void:
	for i in range(5):
		if not _current_unit or not _current_unit.movement.has_tentative_move(): return
		if get_tree(): await get_tree().process_frame

# UI Feedback

func show_warning_message(text: String) -> void:
	if text.is_empty() or not is_inside_tree(): return

	if not is_instance_valid(_warning_overlay):
		_warning_overlay = Control.new()
		_warning_overlay.name = "WarningOverlay"
		_warning_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_warning_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(_warning_overlay)

	var label = _create_warning_label(text)
	_warning_overlay.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

	if _animation_service:
		_animation_service.request_warning_flash(label)
	else:
		_fallback_warning_flash(label)

func _create_warning_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", WARNING_FONT_SIZE)
	label.add_theme_color_override("font_color", WARNING_COLOR)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.modulate = GameConstants.Colors.WHITE_TRANSPARENT
	return label

func _fallback_warning_flash(label: Label) -> void:
	label.modulate.a = 1.0
	var timer = get_tree().create_timer(WARNING_DURATION)
	timer.timeout.connect(func(): if is_instance_valid(label): label.queue_free())

# Legacy/Helper Panel Methods (Mostly Unused now)

func _create_panel(p_name: String, p_pos: Vector2, p_size: Vector2) -> Panel:
	var p: Panel = Panel.new()
	p.name = p_name
	p.position = p_pos
	p.size = p_size
	return p

func _create_vbox(p_name: String, parent: Control, padding: float) -> VBoxContainer:
	var vb: VBoxContainer = VBoxContainer.new()
	vb.name = p_name
	vb.position = Vector2(padding, padding)
	vb.size = parent.size - Vector2(padding * 2, padding * 2)
	parent.add_child(vb)
	return vb

func _create_label(p_name: String, parent: Node) -> Label:
	var l: Label = Label.new()
	l.name = p_name
	parent.add_child(l)
	return l

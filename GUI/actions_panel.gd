class_name ActionsPanel
extends CustomResizablePanel

const LocalizationStrings := preload("res://Resources/Localization/localization_strings.gd")

signal action_selected(action: Dictionary)
signal attribute_hovered(attribute_index: int) # -1 if exited

const BUTTON_MIN_SIZE := Vector2(160, 30)
const HINT_TEXT_COLOR := Color(1, 1, 0.8)

@onready var actions_container: VBoxContainer = %ActionsContainer
@onready var hint_label: Label = %HintLabel

# State cache for Back button
var _cached_unit: Unit
var _cached_terrain_map
var _cached_unit_manager: UnitManager
var _attack_targets: Array[Unit] = []
var _reachable_attack_targets: Array[Unit] = []
var _current_attack_target: Unit
var _last_nav_target: Control
var _auto_battle_mode := false
var _actions_container_missing_logged := false
var _no_unit_selected_logged := false
var _enemy_unit_selected_logged := false
var _no_actions_logged := false
var _no_attacker_logged := false
var _no_targets_logged := false
var _attributes_missing_logged := false

func _ready() -> void:
	print_debug("ActionsPanel._ready() called - Panel is initializing")
	# ... (keep existing debugs if desired, skipping for brevity in replacement) ...

	min_width = 220
	min_height = 50
	super._ready()
	focus_mode = Control.FOCUS_ALL

	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	if hint_label:
		hint_label.text = LocalizationStrings.get_text("hud.actions_hint")
		hint_label.visible = false
		hint_label.modulate = Color(1, 1, 1, 0)
		hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hint_label.add_theme_color_override("font_color", HINT_TEXT_COLOR)
		hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hint_label.custom_minimum_size = Vector2(0, 18)

	queue_redraw()

func update_actions(unit: Unit, terrain_map, unit_manager: UnitManager) -> void:
	_cached_unit = unit
	_cached_terrain_map = terrain_map
	_cached_unit_manager = unit_manager

	_clear_actions()

	if not is_instance_valid(unit):
		if not _no_unit_selected_logged:
			_no_unit_selected_logged = true
			push_warning("[ActionsPanel] No unit selected; showing hint only.")
		_show_hint("No unit selected")
		return
	_no_unit_selected_logged = false

	var unit_index = unit_manager.get_unit_index(unit)
	if not unit_manager.is_player_controlled(unit_index):
		if not _enemy_unit_selected_logged:
			_enemy_unit_selected_logged = true
			push_warning("[ActionsPanel] Selected unit is not player-controlled; showing hint only.")
		_show_hint("Enemy unit selected")
		return
	_enemy_unit_selected_logged = false

	var available_actions = UnitActionManager.get_available_actions(unit, terrain_map, unit_manager)
	if available_actions.is_empty():
		if not _no_actions_logged:
			_no_actions_logged = true
			push_warning("[ActionsPanel] No available actions for unit %s." % unit.unit_name)
		_show_hint("No actions available")
		return
	_no_actions_logged = false

	_show_actions_hint()

	for action in available_actions:
		var btn := Button.new()
		btn.text = action.label
		btn.custom_minimum_size = BUTTON_MIN_SIZE
		btn.disabled = not action.available
		if action.has("hint"):
			btn.tooltip_text = str(action.hint)
		btn.pressed.connect(func(): action_selected.emit(action))
		actions_container.add_child(btn)

	force_fit_content()

func set_auto_battle_mode(active: bool) -> void:
	_auto_battle_mode = active
	if is_instance_valid(actions_container):
		actions_container.modulate = Color(1, 1, 1, 0.6) if active else Color(1, 1, 1, 1)
	if is_instance_valid(hint_label):
		hint_label.visible = not active and not hint_label.text.is_empty()

func show_attack_menu(attacker: Unit, target: Unit, targets: Array = [], reachable_targets: Array = []) -> void:
	print_debug("ActionsPanel: show_attack_menu called, attacker=", attacker.unit_name if attacker else "null", " target=", target.unit_name if target else "null")
	_attack_targets.clear()
	_reachable_attack_targets.clear()
	for candidate in targets:
		if candidate and candidate is Unit and not _attack_targets.has(candidate):
			_attack_targets.append(candidate)
	for reachable in reachable_targets:
		if reachable and reachable is Unit and not _reachable_attack_targets.has(reachable):
			_reachable_attack_targets.append(reachable)
	if _attack_targets.is_empty() and target:
		_attack_targets.append(target)
	_current_attack_target = target if target and _attack_targets.has(target) else (_attack_targets[0] if not _attack_targets.is_empty() else null)
	_render_attack_menu(attacker)

func get_current_attack_target() -> Unit:
	return _current_attack_target

func _render_attack_menu(attacker: Unit) -> void:
	_clear_actions()
	if not hint_label:
		return
	hint_label.text = "Select a target and attribute"
	hint_label.visible = not _auto_battle_mode
	hint_label.modulate = Color(1, 1, 1, 1)
	attribute_hovered.emit(-1)

	if not attacker:
		if not _no_attacker_logged:
			_no_attacker_logged = true
			push_warning("[ActionsPanel] Cannot render attack menu; attacker missing.")
		_show_hint("No attacker selected")
		_add_back_button()
		force_fit_content()
		return
	_no_attacker_logged = false

	if _attack_targets.is_empty():
		if not _no_targets_logged:
			_no_targets_logged = true
			push_warning("[ActionsPanel] Cannot render attack menu; no valid targets.")
		_show_hint("No valid targets")
		_add_back_button()
		force_fit_content()
		return
	_no_targets_logged = false

	var targets_label := Label.new()
	targets_label.text = "Select Target"
	targets_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	actions_container.add_child(targets_label)

	var target_group := ButtonGroup.new()
	for target in _attack_targets:
		var target_ref := target
		var btn := Button.new()
		btn.toggle_mode = true
		_register_focus_target(btn)
		btn.button_group = target_group
		btn.button_pressed = target_ref == _current_attack_target
		btn.text = _format_target_button_text(target_ref)
		btn.custom_minimum_size = BUTTON_MIN_SIZE
		btn.pressed.connect(func():
			if target_ref == _current_attack_target:
				return
			_current_attack_target = target_ref
			_render_attack_menu(attacker)
		)
		actions_container.add_child(btn)

	var attrs_label := Label.new()
	attrs_label.text = "Select Attribute"
	attrs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	actions_container.add_child(attrs_label)

	_add_attribute_buttons(attacker)
	_add_back_button()
	force_fit_content()

func _add_attribute_buttons(attacker: Unit) -> void:
	var target = _current_attack_target
	if not target:
		var empty_label := Label.new()
		empty_label.text = "Select a target to continue"
		actions_container.add_child(empty_label)
		return

	var attrs = attacker.get_attributes()
	if not attrs:
		if not _attributes_missing_logged:
			_attributes_missing_logged = true
			push_warning("[ActionsPanel] Cannot render attribute buttons; attacker attributes missing.")
		_show_hint("No attributes available")
		return
	_attributes_missing_logged = false

	for i in range(UnitAttributes.ATTRIBUTE_NAMES.size()):
		var attr_name = UnitAttributes.ATTRIBUTE_NAMES[i]
		var val = attrs.get_attribute(attr_name)
		var btn := Button.new()
		btn.text = "%s (%d)" % [attr_name.capitalize(), val]
		_register_focus_target(btn)
		btn.custom_minimum_size = BUTTON_MIN_SIZE
		var attr_index := i
		btn.pressed.connect(func():
			action_selected.emit({
				"type": "attack",
				"target": target,
				"attribute_index": attr_index
			})
		)
		btn.mouse_entered.connect(func(): attribute_hovered.emit(attr_index))
		btn.mouse_exited.connect(func(): attribute_hovered.emit(-1))
		actions_container.add_child(btn)

func _add_back_button() -> void:
	var back_btn := Button.new()
	_register_focus_target(back_btn)
	back_btn.text = "Back"
	back_btn.custom_minimum_size = BUTTON_MIN_SIZE
	back_btn.pressed.connect(_on_back_pressed)
	back_btn.mouse_entered.connect(func(): attribute_hovered.emit(-1))
	actions_container.add_child(back_btn)

func _format_target_button_text(target: Unit) -> String:
	if target == null:
		return "Unknown Target"
	var suffix := ""
	if _reachable_attack_targets.has(target):
		suffix = " (Move)"
	return "%s%s" % [target.unit_name, suffix]

func _on_back_pressed() -> void:
	if is_instance_valid(_cached_unit):
		update_actions(_cached_unit, _cached_terrain_map, _cached_unit_manager)

func _clear_actions() -> void:
	if not is_instance_valid(actions_container):
		if not _actions_container_missing_logged:
			_actions_container_missing_logged = true
			push_warning("[ActionsPanel] actions_container is missing; cannot clear actions.")
		return
	_actions_container_missing_logged = false
	for child in actions_container.get_children():
		if child != hint_label:
			child.queue_free()

func _show_hint(msg: String) -> void:
	if is_instance_valid(hint_label):
		hint_label.text = msg
		hint_label.visible = not _auto_battle_mode

func _show_actions_hint() -> void:
	if is_instance_valid(hint_label):
		hint_label.visible = not _auto_battle_mode
		hint_label.modulate = Color(1, 1, 1, 1)

func enable_navigation_mode() -> void:
	focus_mode = Control.FOCUS_ALL
	if _last_nav_target and is_instance_valid(_last_nav_target):
		_last_nav_target.grab_focus()
	elif not focus_first_button():
		grab_focus()

func disable_navigation_mode() -> void:
	if has_focus():
		release_focus()
	if _last_nav_target and is_instance_valid(_last_nav_target):
		_last_nav_target.release_focus()

func focus_first_button() -> bool:
	if not is_instance_valid(actions_container):
		return false
	for child in actions_container.get_children():
		if child is Button and child.focus_mode != Control.FOCUS_NONE:
			child.grab_focus()
			return true
	return false

func _register_focus_target(control: Control) -> void:
	if control == null:
		return
	if control.focus_mode == Control.FOCUS_NONE:
		control.focus_mode = Control.FOCUS_ALL
	control.focus_entered.connect(func(): _last_nav_target = control)

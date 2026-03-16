class_name ActionsPanel
extends CustomResizablePanel

signal action_selected(action: UnitAction)
signal attribute_hovered(attribute_index: int) # -1 if exited

const BUTTON_MIN_SIZE := Vector2(160, 30)
const HINT_TEXT_COLOR := GameConstants.Colors.HINT_TEXT
const ActionLabelFormatter := preload("res://Gameplay/turn/action_label_formatter.gd")

@onready var actions_container: VBoxContainer = %ActionsContainer
@onready var hint_label: RichTextLabel = %HintLabel

# State cache
var _cached_unit: Unit
var _cached_terrain
var _cached_unit_manager: UnitManager
var _active_action: UnitAction # The action being configured in a sub-menu
var _turn_enabled := true
var _attack_targets: Array[Target] = []
var _reachable_attack_targets: Array[Target] = []
var _current_attack_target: Target
var _move_info_by_target: Dictionary = {}
var _last_nav_target: Control
var _auto_battle_mode := false
var _loc := load(FilePaths.Resources.LOCALIZATION_STRINGS) as GDScript
var _pending_update = null

# Logging flags to reduce noise
var _no_unit_selected_logged := false
var _enemy_unit_selected_logged := false
var _no_actions_logged := false

# Initialization & Lifecycle

func _ready() -> void:
	LocaleService.locale_changed.connect(_on_locale_changed)
	if _pending_update:
		update_actions(_pending_update.unit, _pending_update.terrain_map, _pending_update.unit_manager)
		_pending_update = null

	min_width = 280
	min_height = 50
	super._ready()
	focus_mode = Control.FOCUS_ALL
	_setup_hint_label()

func _setup_hint_label() -> void:
	if not hint_label: return
	hint_label.text = _loc.get_text("hud.actions_hint")
	hint_label.visible = false
	hint_label.modulate = GameConstants.Colors.WHITE_TRANSPARENT
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_label.add_theme_color_override("font_color", HINT_TEXT_COLOR)
	hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_label.custom_minimum_size = Vector2(0, 18)

func _on_locale_changed() -> void:
	if is_instance_valid(_cached_unit):
		update_actions(_cached_unit, _cached_terrain, _cached_unit_manager, _turn_enabled)

# Core Update Logic

func update_actions(unit: Unit, terrain_map, unit_manager: UnitManager, turn_enabled: bool = true) -> void:
	if _should_defer_update(unit, terrain_map, unit_manager, turn_enabled): return

	_cached_unit = unit
	_cached_terrain = terrain_map
	_cached_unit_manager = unit_manager
	_turn_enabled = turn_enabled
	_active_action = null
	_current_attack_target = null

	show()
	_clear_actions()

	if _handle_invalid_states(unit, unit_manager): return

	var available_actions: Array[UnitAction] = UnitActionManager.get_available_actions(unit, terrain_map, unit_manager)
	if _handle_no_actions(unit, available_actions): return

	_show_actions_hint()
	for action in available_actions: _add_action_button(unit, action)
	force_fit_content()

func _should_defer_update(unit: Unit, terrain_map, unit_manager: UnitManager, turn_enabled: bool) -> bool:
	if is_node_ready(): return false
	_pending_update = {"unit": unit, "terrain_map": terrain_map, "unit_manager": unit_manager, "turn_enabled": turn_enabled}
	return true

func _handle_invalid_states(unit: Unit, unit_manager: UnitManager) -> bool:
	if not is_instance_valid(unit):
		if not _no_unit_selected_logged:
			_no_unit_selected_logged = true
			push_warning("[ActionsPanel] No unit selected.")
		_show_hint(_loc.get_text(_loc.HUD_NO_UNIT_SELECTED))
		return true
	_no_unit_selected_logged = false

	if unit_manager:
		var unit_index: int = unit_manager.get_unit_index(unit)
		if not unit_manager.is_player_controlled(unit_index):
			if not _enemy_unit_selected_logged:
				_enemy_unit_selected_logged = true
				push_warning("[ActionsPanel] Enemy unit selected.")
			_show_hint(_loc.get_text(_loc.HUD_ENEMY_UNIT_SELECTED))
			return true
	_enemy_unit_selected_logged = false
	return false

func _handle_no_actions(unit: Unit, available_actions: Array) -> bool:
	if not available_actions.is_empty():
		_no_actions_logged = false
		return false
	if not _no_actions_logged:
		_no_actions_logged = true
		push_warning("[ActionsPanel] No actions for %s." % (unit.unit_name if unit else "null"))
	_show_hint(_loc.get_text(_loc.HUD_NO_ACTIONS_AVAILABLE))
	return true

func _add_action_button(unit: Unit, action: UnitAction) -> Button:
	if not is_instance_valid(actions_container): return null
	var btn := Button.new()
	btn.text = _get_action_label(action)
	btn.custom_minimum_size = BUTTON_MIN_SIZE
	btn.disabled = not action.available or not _turn_enabled
	btn.tooltip_text = _get_action_hint(action)
	btn.mouse_entered.connect(func(): if EventBus: EventBus.ui_hover_triggered.emit())
	_register_focus_target(btn)
	btn.pressed.connect(func():
		if EventBus: EventBus.ui_button_pressed.emit()
		if action.needs_attribute: show_attribute_menu(unit, action, action.target_move_data)
		else: action_selected.emit(action)
	)
	actions_container.add_child(btn)
	return btn

func _needs_attribute_grid(action_type: int) -> bool:
	return action_type == UnitAction.Type.ATTACK or \
		   action_type == UnitAction.Type.AID or \
		   action_type == UnitAction.Type.SKILL or \
		   action_type == UnitAction.Type.CONVINCE or \
		   action_type == UnitAction.Type.OPEN_ATTACK_MENU

# Attribute & Target Menus

func show_attribute_menu(unit: Unit, action: UnitAction, move_info: Dictionary = {}) -> void:
	if not _prepare_attribute_menu(unit, action, move_info): return
	_active_action = action

	var lists = ActionTargetHandler.populate_target_lists(action)
	_attack_targets = lists.attack_targets
	_reachable_attack_targets = lists.reachable_attack_targets

	if _attack_targets.size() > 1:
		_add_target_selector(unit, action, _attack_targets)
		return
	elif _attack_targets.size() == 1:
		_current_attack_target = _attack_targets[0]

	# Decide if we need an attribute grid or just emit the target action
	if _needs_attribute_grid(action.type):
		_add_label(_loc.get_text(_loc.HUD_SELECT_ATTRIBUTE_TITLE))
		if _build_attribute_grid(unit, action):
			_add_back_button()
			force_fit_content()
	elif _current_attack_target:
		_emit_target_action(action, _current_attack_target)

func _prepare_attribute_menu(_unit: Unit, action: UnitAction, move_info: Dictionary) -> bool:
	_clear_actions()
	_move_info_by_target = move_info
	if not hint_label or not actions_container: return false

	if _needs_attribute_grid(action.type):
		var raw_text: String = _loc.get_text(_loc.HUD_SELECT_ATTRIBUTE).format({"action": _get_action_label(action)})
		hint_label.text = GameConstants.colorize_attributes(raw_text)
	else:
		hint_label.text = _loc.get_text(_loc.HUD_SELECT_TARGET)

	hint_label.visible = not _auto_battle_mode
	hint_label.modulate = Color.WHITE
	attribute_hovered.emit(-1)
	return true

func _add_target_selector(unit: Unit, action: UnitAction, targets: Array[Target]) -> void:
	_add_label(_loc.get_text(_loc.HUD_SELECT_TARGET))
	if not _current_attack_target or not targets.has(_current_attack_target):
		_current_attack_target = targets[0]

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_container.add_child(grid)

	var target_group := ButtonGroup.new()
	for target in targets:
		var btn := Button.new()
		btn.toggle_mode = true
		btn.button_group = target_group
		btn.button_pressed = target == _current_attack_target
		btn.text = ActionTargetHandler.format_target_button_text(target, _reachable_attack_targets, _move_info_by_target, _loc, targets)

		btn.custom_minimum_size = Vector2(100, 30)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_register_focus_target(btn)
		btn.mouse_entered.connect(func(): if EventBus: EventBus.ui_hover_triggered.emit())
		btn.pressed.connect(func():
			if EventBus: EventBus.ui_button_pressed.emit()
			_current_attack_target = target

			if _needs_attribute_grid(action.type):
				show_attribute_menu(unit, action, _move_info_by_target)
			else:
				_emit_target_action(action, target)
		)
		grid.add_child(btn)
	_add_back_button()

func _emit_target_action(action: UnitAction, target: Target) -> void:
	var final: UnitAction = action.clone()
	final.target = target
	final.task_id = action.target_to_task.get(target, "")

	if _move_info_by_target.has(target):
		var m = _move_info_by_target[target]
		final.type = UnitAction.Type.MOVE_AND_INTERACT
		final.action_id = GameConstants.ActionIds.MOVE_AND_INTERACT

		# m could be a Dictionary with 'coord' or a raw coordinate key in some legacy cases
		# but our providers now use consistent Dictionary value with 'coord'
		if m is Dictionary:
			final.target_move_coord = m.get("coord", target.get_grid_location())
			final.movement_cost = int(m.get("cost", 0))
		else:
			# Fallback if m is just cost or something else
			final.target_move_coord = target.get_grid_location()
			final.movement_cost = int(m)

		# Set action cost based on type
		var itype = action.type
		if itype == UnitAction.Type.OPEN_ATTACK_MENU:
			itype = UnitAction.Type.ATTACK
		final.interact_action_type = itype
		final.action_cost = 1 # Default

		if target is Unit and _cached_unit_manager:
			final.interact_target_uid = _cached_unit_manager.get_unit_index(target)
			final.interact_target_coord = target.get_grid_location()
		elif target is Location or target is Loot:
			final.interact_target_coord = target.get_grid_location()
	else:
		# Direct interaction without move
		final.interact_target_coord = target.get_grid_location()
		if target is Unit and _cached_unit_manager:
			final.interact_target_uid = _cached_unit_manager.get_unit_index(target)

	action_selected.emit(final)

func _build_attribute_grid(unit: Unit, action: UnitAction) -> bool:
	if not unit:
		_show_hint(_loc.get_text(_loc.HUD_NO_ATTRIBUTES_AVAILABLE))
		return false

	var is_aid = action.type == UnitAction.Type.AID or action.interact_action_type == UnitAction.Type.AID
	if is_aid: return _build_aid_attribute_grid(unit, action)
	return _build_standard_attribute_grid(unit, action)

func _build_aid_attribute_grid(unit: Unit, action: UnitAction) -> bool:
	var grid = _create_grid(3) # Keep 3 columns

	for attr_idx: GameConstants.AttributeIndex in GameConstants.COMBAT_ATTRIBUTE_INDICES:
		var val := unit.get_attribute(attr_idx)
		var base := unit.get_base_attribute_from_target(attr_idx)
		var attr_bonus := val - base
		var aid_bonus := int(floor(val / 2.0))

		var display_name := GameConstants.get_attribute_name(attr_idx).capitalize()
		var btn_text := "%s (+%d)" % [display_name, aid_bonus]
		# If the base attribute itself has a bonus, maybe show it?
		# But AID bonus is the important one here. Let's keep it simple but accurate.
		if attr_bonus != 0:
			btn_text = "%s:%d (+%d)" % [display_name, val, aid_bonus]

		var btn := _create_grid_button(grid, btn_text)

		var color :Color= GameConstants.get_attribute_color(attr_idx)
		btn.add_theme_color_override("font_color", color)
		btn.add_theme_color_override("font_hover_color", color.lightened(0.2))
		btn.add_theme_color_override("font_pressed_color", color.darkened(0.2))
		btn.add_theme_color_override("font_focus_color", color)

		btn.mouse_entered.connect(func(): attribute_hovered.emit(attr_idx))
		btn.mouse_exited.connect(func(): attribute_hovered.emit(-1))
		btn.pressed.connect(func(): _emit_attribute_action(action, attr_idx, display_name, UnitAction.Type.AID))
	return true

func _build_standard_attribute_grid(unit: Unit, action: UnitAction) -> bool:
	var grid = _create_grid(3) # 3 columns, 2 rows for 6 attributes

	for attr_idx: GameConstants.AttributeIndex in GameConstants.COMBAT_ATTRIBUTE_INDICES:
		var val := unit.get_attribute(attr_idx)
		var base := unit.get_base_attribute_from_target(attr_idx)
		var bonus := val - base

		var display_name := GameConstants.get_attribute_name(attr_idx).capitalize()
		var btn_text := "%s (%d)" % [display_name, val]
		if bonus > 0:
			btn_text = "%s (%d+%d)" % [display_name, base, bonus]
		elif bonus < 0:
			btn_text = "%s (%d%d)" % [display_name, base, bonus]

		var btn := _create_grid_button(grid, btn_text)

		var color :Color= GameConstants.get_attribute_color(attr_idx)
		btn.add_theme_color_override("font_color", color)
		btn.add_theme_color_override("font_hover_color", color.lightened(0.2))
		btn.add_theme_color_override("font_pressed_color", color.darkened(0.2))
		btn.add_theme_color_override("font_focus_color", color)

		btn.mouse_entered.connect(func(): attribute_hovered.emit(attr_idx))
		btn.mouse_exited.connect(func(): attribute_hovered.emit(-1))
		btn.pressed.connect(func():
			var itype = UnitAction.Type.ATTACK
			if action.type == UnitAction.Type.CONVINCE or action.label_params.get("is_convince", false): itype = UnitAction.Type.CONVINCE
			elif action.type == UnitAction.Type.AID: itype = UnitAction.Type.AID
			elif action.type == UnitAction.Type.EXPLORE: itype = UnitAction.Type.EXPLORE
			elif action.type == UnitAction.Type.VISIT: itype = UnitAction.Type.VISIT
			elif action.type == UnitAction.Type.TRAPPED: itype = UnitAction.Type.TRAPPED
			elif action.type == UnitAction.Type.GATHER: itype = UnitAction.Type.GATHER

			_emit_attribute_action(action, attr_idx, display_name, itype)
		)
	return true

func _emit_attribute_action(action: UnitAction, idx: int, p_name: String, interact_type: UnitAction.Type) -> void:
	var final: UnitAction = action.clone()
	final.attribute_index = idx
	final.attribute_name = p_name
	final.target = _current_attack_target

	if _move_info_by_target.has(_current_attack_target):
		var m = _move_info_by_target[_current_attack_target]
		final.type = UnitAction.Type.MOVE_AND_INTERACT
		final.action_id = GameConstants.ActionIds.MOVE_AND_INTERACT

		if m is Dictionary:
			final.target_move_coord = m.get("coord", _current_attack_target.get_grid_location())
			final.movement_cost = int(m.get("cost", 0))
		else:
			final.target_move_coord = _current_attack_target.get_grid_location()
			final.movement_cost = int(m)

		final.action_cost = 1
		final.interact_action_type = interact_type

		if _current_attack_target is Unit and _cached_unit_manager:
			final.interact_target_uid = _cached_unit_manager.get_unit_index(_current_attack_target)
			final.interact_target_coord = _current_attack_target.get_grid_location()
		elif _current_attack_target is Location or _current_attack_target is Loot:
			final.interact_target_coord = _current_attack_target.get_grid_location()
			# Locations and Loot don't have UIDs in the same way, but task_manager uses coords

	action_selected.emit(final)

# UI Helpers

func _create_grid(cols: int) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = cols
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_container.add_child(grid)
	return grid

func _create_grid_button(grid: Control, txt: String) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.custom_minimum_size = BUTTON_MIN_SIZE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.mouse_entered.connect(func(): if EventBus: EventBus.ui_hover_triggered.emit())
	_register_focus_target(btn)
	grid.add_child(btn)
	return btn

func _add_label(txt: String) -> void:
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.text = GameConstants.colorize_attributes(txt)
	actions_container.add_child(l)

func _add_back_button() -> void:
	var btn := Button.new()
	btn.text = _loc.get_text(_loc.HUD_ACTION_BACK)
	btn.custom_minimum_size = BUTTON_MIN_SIZE
	btn.pressed.connect(func():
		if EventBus: EventBus.ui_button_pressed.emit()
		if is_instance_valid(_cached_unit): update_actions(_cached_unit, _cached_terrain, _cached_unit_manager)
	)
	btn.mouse_entered.connect(func():
		if EventBus: EventBus.ui_hover_triggered.emit()
		attribute_hovered.emit(-1)
	)
	_register_focus_target(btn)
	actions_container.add_child(btn)

func _clear_actions() -> void:
	if not actions_container: return
	if hint_label and hint_label.get_parent() == actions_container: actions_container.remove_child(hint_label)
	for child in actions_container.get_children(): child.queue_free()
	if hint_label: actions_container.add_child(hint_label)
	_update_hint_visibility()

func _update_hint_visibility() -> void:
	if not hint_label: return
	var should_be_visible = not _auto_battle_mode and actions_container.get_child_count() <= 1
	if hint_label.visible != should_be_visible:
		hint_label.visible = should_be_visible

func _show_hint(msg: String) -> void:
	if hint_label: hint_label.text = msg
	_update_hint_visibility()

func _show_actions_hint() -> void:
	if hint_label: hint_label.modulate = Color.WHITE
	_update_hint_visibility()

# Navigation & Focus

func enable_navigation_mode() -> void:
	focus_mode = Control.FOCUS_ALL
	if is_instance_valid(_last_nav_target): _last_nav_target.grab_focus()
	elif not _focus_first(): grab_focus()

func disable_navigation_mode() -> void:
	if has_focus(): release_focus()
	if is_instance_valid(_last_nav_target): _last_nav_target.release_focus()

func _focus_first() -> bool:
	if not actions_container: return false
	for child in actions_container.get_children():
		if child is Button and child.focus_mode != Control.FOCUS_NONE:
			child.grab_focus()
			return true
	return false

func _register_focus_target(c: Control) -> void:
	if not c: return
	if c.focus_mode == Control.FOCUS_NONE: c.focus_mode = Control.FOCUS_ALL
	c.focus_entered.connect(func(): _last_nav_target = c)

# External Interface

func set_auto_battle_mode(active: bool) -> void:
	_auto_battle_mode = active
	if actions_container: actions_container.modulate = GameConstants.Colors.WHITE_SEMI_TRANSPARENT if active else Color.WHITE
	if hint_label: hint_label.visible = not active and not hint_label.text.is_empty()

func get_current_attack_target() -> Target: return _current_attack_target
func get_active_action() -> UnitAction: return _active_action
func _get_action_label(a: UnitAction) -> String: return ActionLabelFormatter.get_label(a, ActionTargetHandler.get_target_name(a.target, _loc))
func _get_action_hint(a: UnitAction) -> String: return ActionLabelFormatter.get_hint(a)
func _get_target_name(t: Target) -> String: return ActionTargetHandler.get_target_name(t, _loc)

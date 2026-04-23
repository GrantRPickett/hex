class_name ActionsPanel
extends CustomResizablePanel

signal action_selected(action: PlayerAction)
signal attribute_hovered(attribute_index: int) # -1 if exited
signal target_objects_hovered(targets: Array[Target])
signal target_unit_unhovered()

const BUTTON_MIN_SIZE := Vector2(160, 30)
const HINT_TEXT_COLOR: Color = GameColors.HINT_TEXT # Default if GameColors fails
const ActionLabelFormatter := preload("res://Gameplay/turn/action_label_formatter.gd")

@onready var actions_container: VBoxContainer = %ActionsContainer
@onready var hint_label: RichTextLabel = %HintLabel

# State cache
var _cached_unit: Unit
var _cached_terrain
var _cached_unit_manager: UnitManager
var _cached_combat_system: CombatSystem
var _active_action: PlayerAction # The action being configured in a sub-menu
var _turn_enabled := true
var _attack_targets: Array[Target] = []
var _reachable_attack_targets: Array[Target] = []
var _current_attack_target: Target
var _move_info_by_target: Dictionary = {}
var _last_nav_target: Control
var _auto_battle_mode := false
var _loc := load(FilePaths.Resources.LOCALIZATION_STRINGS) as GDScript
var _pending_update = null

const UNOPPOSED_TYPES := [
	GameConstants.ActionType.GATHER,
	GameConstants.ActionType.VISIT,
	GameConstants.ActionType.CONVINCE,
	GameConstants.ActionType.AID,
	GameConstants.ActionType.WAIT,
]

# Logging flags to reduce noise
var _no_unit_selected_logged := false
var _enemy_unit_selected_logged := false
var _no_actions_logged := false

# Initialization & Lifecycle

func _ready() -> void:
	LocaleService.locale_changed.connect(_on_locale_changed)
	if _pending_update:
		update_actions(_pending_update.unit, _pending_update.terrain_map, _pending_update.unit_manager, _pending_update.combat_system, _pending_update.turn_enabled)
		_pending_update = null

	min_width = 280
	min_height = 50
	super._ready()
	focus_mode = Control.FOCUS_ALL
	_setup_hint_label()
	_connect_accessibility()

func _connect_accessibility() -> void:
	var manager = get_node_or_null("/root/AccessibilityManager")
	if manager:
		manager.high_contrast_changed.connect(_on_high_contrast_changed)
		_on_high_contrast_changed(manager.is_high_contrast_enabled())

func _on_high_contrast_changed(enabled: bool) -> void:
	if not hint_label: return
	var colors = get_node_or_null("/root/GameColors")
	var target_color = colors.WARNING if (enabled and colors) else HINT_TEXT_COLOR
	hint_label.add_theme_color_override("font_color", target_color)

func _setup_hint_label() -> void:
	if not hint_label: return
	hint_label.text = _loc.get_text("hud.actions_hint")
	hint_label.visible = false
	hint_label.modulate = GameColors.WHITE_TRANSPARENT
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_label.add_theme_color_override("font_color", HINT_TEXT_COLOR)
	hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_label.custom_minimum_size = Vector2(0, 18)

func _on_locale_changed() -> void:
	if is_instance_valid(_cached_unit):
		update_actions(_cached_unit, _cached_terrain, _cached_unit_manager, _cached_combat_system, _turn_enabled)

# Core Update Logic

func update_actions(unit: Unit, terrain_map, unit_manager: UnitManager, combat_system: CombatSystem = null, turn_enabled: bool = true) -> void:
	if _should_defer_update(unit, terrain_map, unit_manager, combat_system, turn_enabled): return

	_cached_unit = unit
	_cached_terrain = terrain_map
	_cached_unit_manager = unit_manager
	_cached_combat_system = combat_system
	_turn_enabled = turn_enabled
	_active_action = null
	_current_attack_target = null

	show()
	_clear_actions()

	if _handle_invalid_states(unit, unit_manager): return

	var available_actions: Array[PlayerAction] = PlayerActionManager.get_available_actions(unit, terrain_map, unit_manager)
	if _handle_no_actions(unit, available_actions): return

	_show_actions_hint()
	for action in available_actions: _add_action_button(unit, action)
	force_fit_content()

func _should_defer_update(unit: Unit, terrain_map, unit_manager: UnitManager, combat_system: CombatSystem, turn_enabled: bool) -> bool:
	if is_node_ready(): return false
	_pending_update = {"unit": unit, "terrain_map": terrain_map, "unit_manager": unit_manager, "combat_system": combat_system, "turn_enabled": turn_enabled}
	return true

func _handle_invalid_states(unit: Unit, unit_manager: UnitManager) -> bool:
	if not is_instance_valid(unit):
		if not _no_unit_selected_logged:
			_no_unit_selected_logged = true
			GameLogger.warning(GameLogger.Category.UI, "[ActionsPanel] No unit selected.")
		_show_hint(_loc.get_text(_loc.HUD_NO_UNIT_SELECTED))
		return true
	_no_unit_selected_logged = false

	if unit_manager:
		var unit_index: int = unit_manager.get_unit_index(unit)
		if not unit_manager.is_player_controlled(unit_index):
			if not _enemy_unit_selected_logged:
				_enemy_unit_selected_logged = true
				GameLogger.warning(GameLogger.Category.UI, "[ActionsPanel] Enemy unit selected.")
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
		GameLogger.warning(GameLogger.Category.UI, "[ActionsPanel] No actions for %s." % (unit.unit_name if unit else "null"))
	_show_hint(_loc.get_text(_loc.HUD_NO_ACTIONS_AVAILABLE))
	return true

func _add_action_button(unit: Unit, action: PlayerAction) -> Button:
	if not is_instance_valid(actions_container): return null
	var btn := Button.new()
	var suffix := _get_action_suffix(action)
	btn.text = _get_action_label(action, "", suffix)
	btn.custom_minimum_size = BUTTON_MIN_SIZE
	btn.disabled = not action.available or not _turn_enabled
	btn.tooltip_text = _get_action_hint(action)
	btn.mouse_entered.connect(func():
		var targets: Array[Target] = []
		if action.target_object is Target:
			targets.append(action.target_object)
		for t in action.reachable_targets:
			if t is Target and not targets.has(t):
				targets.append(t)
		# Also check action.targets just in case
		for t in action.targets:
			if t is Target and not targets.has(t):
				targets.append(t)
		
		if not targets.is_empty():
			target_objects_hovered.emit(targets)
	)
	btn.mouse_exited.connect(func(): target_unit_unhovered.emit())
	#btn.mouse_entered.connect(func(): if EventBus: EventBus.ui_hover_triggered.emit())
	_register_focus_target(btn)
	btn.pressed.connect(func():
		if EventBus: EventBus.ui_button_pressed.emit()
		if action.needs_attribute: show_attribute_menu(unit, action, action.target_move_data)
		else: action_selected.emit(action)
	)
	actions_container.add_child(btn)
	return btn

## Checks if all 6 combat attributes yield the same quality symbol for the given target.
## Returns the shared symbol string if uniform, or "" if attrs differ.
## Only applies to unopposed action types (GATHER, CONVINCE, VISIT).
## Opposed types (ATTACK, EXPLORE, TRAPPED) always return "" to force the attribute grid.
func _get_uniform_attr_symbol(unit: Unit, action: PlayerAction, target: Target) -> String:
	if not unit or not _cached_combat_system or not target: return ""

	var itype := _get_interaction_str(action)

	var first_symbol: String = ""
	for attr_idx: GameConstants.AttributeIndex in GameConstants.COMBAT_ATTRIBUTE_INDICES:
		var forecast = _cached_combat_system.get_preview_forecast(unit, target, attr_idx, itype)
		var symbol = _cached_combat_system.get_quality_symbol(forecast.quality if forecast else GameConstants.Combat.AttackQuality.IDLE)
		if first_symbol.is_empty():
			first_symbol = symbol
		elif symbol != first_symbol:
			return ""
	return first_symbol

## Returns the best attribute index (highest quality, ties broken by attr value).
func _get_best_attr_index(unit: Unit, action: PlayerAction, target: Target) -> GameConstants.AttributeIndex:
	var itype := _get_interaction_str(action)

	var best_idx: GameConstants.AttributeIndex = GameConstants.AttributeIndex.GRIT
	var best_quality: int = -1
	var best_val: int = -1

	for attr_idx: GameConstants.AttributeIndex in GameConstants.COMBAT_ATTRIBUTE_INDICES:
		var forecast = _cached_combat_system.get_preview_forecast(unit, target, attr_idx, itype)
		var q: int = forecast.quality if forecast else GameConstants.Combat.AttackQuality.IDLE
		var val: int = unit.get_attribute(attr_idx)
		if q > best_quality or (q == best_quality and val > best_val):
			best_quality = q
			best_val = val
			best_idx = attr_idx
	return best_idx

## Returns '!', '…', '?', or 'X' suffix based on action state and risk.
func _get_action_suffix(action: PlayerAction, target: Target = null) -> String:
	if action.type == GameConstants.ActionType.WAIT:
		return ""

	# If it has near/far info, and we are NOT looking for a specific target suffix,
	# the formatter handles group indicators (e.g., "1 near★").
	# Return empty for the "overall" action button to avoid "Convince★ (1 near★)".
	if target == null and (action.ui_label_params.has("near") or action.ui_label_params.has("far")):
		return ""

	var active_target = target if target else action.target_object

	var _is_opposed := action.type not in UNOPPOSED_TYPES and action.type != GameConstants.ActionType.SKILL

	if active_target and _cached_combat_system and _cached_unit:
		var itype := _get_interaction_str(action)

		var symbol = _cached_combat_system.get_target_status_symbol(_cached_unit, active_target, itype)
		return symbol

	# If attrs don't matter (needs_attribute but all produce same icon), show the quality icon directly
	if action.needs_attribute and _cached_unit and active_target and _cached_combat_system:
		var uniform := _get_uniform_attr_symbol(_cached_unit, action, active_target)
		if not uniform.is_empty():
			return uniform

	if not action.needs_attribute:
		return GameConstants.UI.Indicators.SUCCESS

	return ""

func _needs_attribute_grid(action_type: int) -> bool:
	return action_type == GameConstants.ActionType.FIGHT or \
		   action_type == GameConstants.ActionType.AID or \
		   action_type == GameConstants.ActionType.SKILL or \
		   action_type == GameConstants.ActionType.CONVINCE or \
		   action_type == GameConstants.ActionType.OPEN_ATTACK_MENU or \
		   action_type == GameConstants.ActionType.GATHER or \
		   action_type == GameConstants.ActionType.TRAPPED or \
		   action_type == GameConstants.ActionType.EXPLORE or \
		   action_type == GameConstants.ActionType.VISIT

# Attribute & Target Menus

func show_attribute_menu(unit: Unit, action: PlayerAction, move_info: Dictionary = {}) -> void:
	if not _prepare_attribute_menu(unit, action, move_info): return
	_active_action = action

	var lists = ActionTargetHandler.populate_target_lists(action)
	_attack_targets = lists.attack_targets
	_reachable_attack_targets = lists.reachable_attack_targets

	# If we have multiple targets and haven't chosen one yet, show the selector
	if _attack_targets.size() > 1 and _current_attack_target == null:
		hint_label.text = _loc.get_text(_loc.HUD_SELECT_TARGET)
		_add_target_selector(unit, action, _attack_targets)
		return

	# If no target chosen but we have exactly one, auto-select it
	if _current_attack_target == null and _attack_targets.size() == 1:
		_current_attack_target = _attack_targets[0]

	# Check setting for auto-attribute selection
	var mode: int = int(GameConfig.get_value(GameConfig.Paths.GAMEPLAY_ALWAYS_BEST_ATTR_MODE, 0))
	var is_opposed := action.type not in UNOPPOSED_TYPES and action.type != GameConstants.ActionType.SKILL
	
	var should_auto_select := false
	if mode == 2: # Always
		should_auto_select = true
	elif mode == 1 and is_opposed: # Opposed Only
		should_auto_select = true

	# Decide if we need an attribute grid or just emit the target action
	if _needs_attribute_grid(action.type):
		if should_auto_select and _current_attack_target and _cached_combat_system:
			var best_attr := _get_best_attr_index(unit, action, _current_attack_target)
			var itype := _get_interaction_str(action)
			var forecast = _cached_combat_system.get_preview_forecast(unit, _current_attack_target, best_attr, itype)
			var f_dict = forecast.to_dict() if forecast else {}
			_emit_attribute_action(action, best_attr, GameConstants.get_attribute_name(best_attr), action.type, f_dict)
			return

		# Shortcut: if all attributes give the same outcome, skip the grid
		if _current_attack_target and _cached_combat_system:
			var uniform := _get_uniform_attr_symbol(unit, action, _current_attack_target)
			if not uniform.is_empty():
				var best_attr := _get_best_attr_index(unit, action, _current_attack_target)
				var itype := _get_interaction_str(action)

				var forecast = _cached_combat_system.get_preview_forecast(unit, _current_attack_target, best_attr, itype)
				var f_dict = forecast.to_dict() if forecast else {}
				_emit_attribute_action(action, best_attr, GameConstants.get_attribute_name(best_attr), action.type, f_dict)
				return
		var raw_text: String = _loc.get_text(_loc.HUD_SELECT_ATTRIBUTE).format({"action": _get_action_label(action)})
		hint_label.text = GameConstants.colorize_attributes(raw_text)
		if _build_attribute_grid(unit, action):
			_add_back_button(false)
			force_fit_content()
	elif _current_attack_target:
		_emit_target_action(action, _current_attack_target)

func _prepare_attribute_menu(_unit: Unit, _action: PlayerAction, move_info: Dictionary) -> bool:
	_clear_actions()
	_move_info_by_target = move_info
	if not hint_label or not actions_container: return false

	hint_label.visible = not _auto_battle_mode
	hint_label.modulate = GameColors.WHITE
	attribute_hovered.emit(-1)
	return true

func _add_target_selector(unit: Unit, action: PlayerAction, targets: Array[Target]) -> void:
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
		# Suffix: risky → ?, useless → X, attribute grid follows → …, direct fire → !
		btn.text = _apply_target_suffix(btn.text, action, target)

		btn.custom_minimum_size = Vector2(100, 30)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_register_focus_target(btn)
		btn.mouse_entered.connect(func(): if target is Target: 
			var targets_list: Array[Target] = [target]
			target_objects_hovered.emit(targets_list))
		btn.mouse_exited.connect(func(): target_unit_unhovered.emit())
		#btn.mouse_entered.connect(func(): if EventBus: EventBus.ui_hover_triggered.emit())
		btn.pressed.connect(func():
			if EventBus: EventBus.ui_button_pressed.emit()
			_current_attack_target = target

			if _needs_attribute_grid(action.type):
				show_attribute_menu(unit, action, _move_info_by_target)
			else:
				_emit_target_action(action, target)
		)
		grid.add_child(btn)
	_add_back_button(true)

func _emit_target_action(action: PlayerAction, target: Target) -> void:
	var final: PlayerAction = PlayerActionManager.create_move_and_interact_action(action, target, _move_info_by_target, _cached_unit_manager)
	action_selected.emit(final)

func _build_attribute_grid(unit: Unit, action: PlayerAction) -> bool:
	if not unit:
		_show_hint(_loc.get_text(_loc.HUD_NO_ATTRIBUTES_AVAILABLE))
		return false

	var is_aid = action.type == GameConstants.ActionType.AID or action.command_payload.get(GameConstants.Payload.INTERACT_ACTION_TYPE) == GameConstants.ActionType.AID
	if is_aid: return _build_aid_attribute_grid(unit, action)
	return _build_standard_attribute_grid(unit, action)

func _build_aid_attribute_grid(unit: Unit, action: PlayerAction) -> bool:
	var grid = _create_grid(3)
	for attr_idx: GameConstants.AttributeIndex in GameConstants.COMBAT_ATTRIBUTE_INDICES:
		var btn := _create_grid_button(grid, _format_aid_attr_label(unit, attr_idx))
		_apply_attribute_button_style(btn, attr_idx)
		var display_name := tr("attr." + GameConstants.get_attribute_name(attr_idx).to_lower())
		btn.pressed.connect(func(): _emit_attribute_action(action, attr_idx, display_name, GameConstants.ActionType.AID))
	return true

func _build_standard_attribute_grid(unit: Unit, action: PlayerAction) -> bool:
	var grid = _create_grid(3)
	var itype := _get_interaction_str(action)
	for attr_idx: GameConstants.AttributeIndex in GameConstants.COMBAT_ATTRIBUTE_INDICES:
		var label := _format_standard_attr_label(unit, attr_idx)
		label += _get_attribute_forecast_suffix(attr_idx, itype)
		var btn := _create_grid_button(grid, label)
		_apply_attribute_button_style(btn, attr_idx)
		btn.pressed.connect(_on_standard_attribute_pressed.bind(action, attr_idx))
	return true

## Shared style for all attribute grid buttons: colors + hover signals.
func _apply_attribute_button_style(btn: Button, attr_idx: GameConstants.AttributeIndex) -> void:
	var color: Color = GameConstants.get_attribute_color(attr_idx)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_hover_color", color.lightened(0.2))
	btn.add_theme_color_override("font_pressed_color", color.darkened(0.2))
	btn.add_theme_color_override("font_focus_color", color)
	btn.mouse_entered.connect(func():
		attribute_hovered.emit(attr_idx)
		if is_instance_valid(_current_attack_target) and _current_attack_target is Target:
			var targets_list: Array[Target] = [_current_attack_target]
			target_objects_hovered.emit(targets_list)
	)
	btn.mouse_exited.connect(func():
		attribute_hovered.emit(-1)
		target_unit_unhovered.emit()
	)

## Format "Attr(val)", "Attr(base+bonus)", or "Attr(base-bonus)" for standard grid.
func _format_standard_attr_label(unit: Unit, attr_idx: GameConstants.AttributeIndex) -> String:
	var val := unit.get_attribute(attr_idx)
	var base := unit.get_base_attribute_from_target(attr_idx)
	var bonus := val - base
	var display_name := tr("attr." + GameConstants.get_attribute_name(attr_idx).to_lower())
	if bonus > 0:
		return "%s(%d+%d)" % [display_name, base, bonus]
	elif bonus < 0:
		return "%s(%d%d)" % [display_name, base, bonus]
	return "%s(%d)" % [display_name, val]

## Format "Attr (+aid_bonus)" or "Attr:val (+aid_bonus)" for AID grid.
func _format_aid_attr_label(unit: Unit, attr_idx: GameConstants.AttributeIndex) -> String:
	var val := unit.get_attribute(attr_idx)
	var base := unit.get_base_attribute_from_target(attr_idx)
	var attr_bonus := val - base
	var aid_bonus := _cached_combat_system.get_aid_bonus(unit, attr_idx) if _cached_combat_system else 0
	var display_name := tr("attr." + GameConstants.get_attribute_name(attr_idx).to_lower())
	if attr_bonus != 0:
		return "%s:%d (+%d)" % [display_name, val, aid_bonus]
	return "%s (+%d)" % [display_name, aid_bonus]

## Quality symbol for an attribute at the current attack target, or INEFFECTIVE if no forecast.
func _get_attribute_forecast_suffix(attr_idx: GameConstants.AttributeIndex, itype: String) -> String:
	if not _cached_combat_system or not _cached_unit or not is_instance_valid(_current_attack_target):
		return GameConstants.UI.Indicators.INEFFECTIVE
	var forecast = _cached_combat_system.get_preview_forecast(_cached_unit, _current_attack_target, attr_idx, itype)
	if not forecast:
		return GameConstants.UI.Indicators.INEFFECTIVE
	# Calculate quality based on the forecast and interaction type
	var quality = _cached_combat_system.get_attack_quality(forecast)
	return _cached_combat_system.get_quality_symbol(quality)

## Pressed handler for standard attribute buttons.
## action.type is already the ActionType enum; only is_convince needs special-casing.
func _on_standard_attribute_pressed(action: PlayerAction, attr_idx: GameConstants.AttributeIndex) -> void:
	var itype := _get_interaction_str(action)
	var f_results: Dictionary = {}
	if _current_attack_target and _cached_combat_system:
		var forecast = _cached_combat_system.get_preview_forecast(
			_cached_unit, _current_attack_target, attr_idx, itype)
		if forecast:
			# Calculate quality first before converting to dict
			_cached_combat_system.get_attack_quality(forecast)
			f_results = forecast.to_dict()
	var interact_type: GameConstants.ActionType = action.type
	if action.ui_label_params.get("is_convince", false):
		interact_type = GameConstants.ActionType.CONVINCE
	_emit_attribute_action(action, attr_idx, GameConstants.get_attribute_name(attr_idx), interact_type, f_results)

func _emit_attribute_action(action: PlayerAction, idx: int, p_name: String, interact_type: GameConstants.ActionType, forecast: Dictionary = {}) -> void:
	var final: PlayerAction = PlayerActionManager.create_move_and_interact_action(action, _current_attack_target, _move_info_by_target, _cached_unit_manager, idx, p_name)
	# Override interact_type if provided (ActionsPanel calculates this locally based on button context)
	final.command_payload[GameConstants.Payload.INTERACT_ACTION_TYPE] = interact_type
	if not forecast.is_empty():
		final.command_payload[GameConstants.Payload.FORECAST_RESULTS] = forecast
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
	#btn.mouse_entered.connect(func(): if EventBus: EventBus.ui_hover_triggered.emit())
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

func _add_back_button(to_main_menu: bool = false) -> void:
	var btn := Button.new()
	btn.text = _loc.get_text(_loc.HUD_ACTION_BACK)
	btn.custom_minimum_size = BUTTON_MIN_SIZE
	btn.pressed.connect(func():
		if EventBus: EventBus.ui_button_pressed.emit()
		if not to_main_menu and _attack_targets.size() > 1 and _current_attack_target != null:
			_current_attack_target = null
			show_attribute_menu(_cached_unit, _active_action, _move_info_by_target)
		elif is_instance_valid(_cached_unit):
			update_actions(_cached_unit, _cached_terrain, _cached_unit_manager, _cached_combat_system, _turn_enabled)
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
	if hint_label: hint_label.modulate = GameColors.WHITE
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
	if actions_container: actions_container.modulate = GameColors.WHITE_SEMI_TRANSPARENT if active else GameColors.WHITE
	if hint_label: hint_label.visible = not active and not hint_label.text.is_empty()

func clear_context() -> void:
	_cached_unit = null
	_cached_terrain = null
	_cached_unit_manager = null
	_cached_combat_system = null
	_active_action = null
	_current_attack_target = null
	_move_info_by_target.clear()
	_clear_actions()
	if hint_label:
		hint_label.text = ""
		hint_label.visible = false
	_no_unit_selected_logged = false
	_enemy_unit_selected_logged = false
	_no_actions_logged = false
	hide()

func get_current_attack_target() -> Target: return _current_attack_target
func get_active_action() -> PlayerAction: return _active_action
func _get_action_label(a: PlayerAction, target_name: String = "", suffix: String = "") -> String:
	var final_target = target_name
	if final_target.is_empty():
		final_target = ActionTargetHandler.get_target_name(a.target_object, _loc)
	return ActionLabelFormatter.get_label(a, final_target, suffix)
func _get_action_hint(a: PlayerAction) -> String: return ActionLabelFormatter.get_hint(a)
func _get_target_name(t: Target) -> String: return ActionTargetHandler.get_target_name(t, _loc)

func _apply_target_suffix(base_text: String, action: PlayerAction, target: Target) -> String:
	var suffix := _get_action_suffix(action, target)
	# format_target_button_text already has (x,y) if needed, so we insert suffix before it if it exists
	if base_text.contains("("):
		var parts := base_text.split("(", true, 1)
		return "%s%s(%s" % [parts[0].strip_edges(), suffix, parts[1]]
	return base_text + suffix

func _get_interaction_str(action: PlayerAction) -> String:
	if not action: return ""
	return GameConstants.get_interaction_from_type(action.type)

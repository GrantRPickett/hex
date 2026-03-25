class_name ActionsPanel
extends CustomResizablePanel

signal action_selected(action: PlayerAction)
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
	btn.mouse_entered.connect(func(): if EventBus: EventBus.ui_hover_triggered.emit())
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

	# Only bypass the grid for unopposed actions — opposed ones have meaningful attribute deltas
	const UNOPPOSED_TYPES := [
		GameConstants.ActionType.GATHER,
		GameConstants.ActionType.CONVINCE,
		GameConstants.ActionType.VISIT,
	]
	if action.type not in UNOPPOSED_TYPES:
		return ""

	var is_convince := action.type == GameConstants.ActionType.CONVINCE
	var task: Task = null
	if not action.target_to_task.is_empty() and action.target_to_task.has(target):
		var tm: TaskManager = unit.get_task_manager()
		if tm: task = tm.get_task_by_id(str(action.target_to_task[target]))

	var first_symbol: String = ""
	for attr_idx: GameConstants.AttributeIndex in GameConstants.COMBAT_ATTRIBUTE_INDICES:
		var symbol: String
		if task:
			symbol = _cached_combat_system.get_quality_symbol(_cached_combat_system.get_task_quality(unit, task, attr_idx))
		elif target:
			symbol = _cached_combat_system.get_quality_symbol(_cached_combat_system.get_attack_quality(unit, target, attr_idx, is_convince))
		else:
			return ""
		if first_symbol.is_empty():
			first_symbol = symbol
		elif symbol != first_symbol:
			return ""
	return first_symbol

## Returns the best attribute index (highest quality, ties broken by attr value).
func _get_best_attr_index(unit: Unit, action: PlayerAction, target: Target) -> GameConstants.AttributeIndex:
	var is_convince := action.type == GameConstants.ActionType.CONVINCE
	var task: Task = null
	if not action.target_to_task.is_empty() and action.target_to_task.has(target):
		var tm: TaskManager = unit.get_task_manager()
		if tm: task = tm.get_task_by_id(str(action.target_to_task[target]))

	var best_idx: GameConstants.AttributeIndex = GameConstants.AttributeIndex.GRIT
	var best_quality: int = -1
	var best_val: int = -1
	for attr_idx: GameConstants.AttributeIndex in GameConstants.COMBAT_ATTRIBUTE_INDICES:
		var q: int
		if task:
			q = _cached_combat_system.get_task_quality(unit, task, attr_idx)
		elif target:
			q = _cached_combat_system.get_attack_quality(unit, target, attr_idx, is_convince)
		else:
			q = GameConstants.Combat.AttackQuality.INEFFECTIVE
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

	if active_target and _cached_combat_system and _cached_unit:
		if action.type == GameConstants.ActionType.ATTACK or action.type == GameConstants.ActionType.CONVINCE:
			var is_convince := action.type == GameConstants.ActionType.CONVINCE
			var symbol = _cached_combat_system.get_target_status_symbol(_cached_unit, active_target, is_convince)
			GameLogger.debug(GameLogger.Category.UI, "[ActionSuffix] Combat action suffix for %s -> %s: %s" % [action.action_id, active_target.unit_name if active_target is Unit else "unknown", symbol])
			return symbol

		# Task-based target (Loot, Location): resolve task and get quality symbol
		if not action.target_to_task.is_empty() and action.target_to_task.has(active_target):
			var task_id := str(action.target_to_task[active_target])
			var task_manager: TaskManager = _cached_unit.get_task_manager()
			if task_manager:
				var task: Task = task_manager.get_task_by_id(task_id)
				if task:
					return _cached_combat_system.get_target_status_symbol(_cached_unit, active_target, false, task)

	# If attrs don't matter (needs_attribute but all produce same icon), show the quality icon directly
	if action.needs_attribute and _cached_unit and active_target and _cached_combat_system:
		var uniform := _get_uniform_attr_symbol(_cached_unit, action, active_target)
		if not uniform.is_empty():
			return uniform

	if not action.needs_attribute:
		return GameConstants.UI.Indicators.SUCCESS

	return ""

func _needs_attribute_grid(action_type: int) -> bool:
	return action_type == GameConstants.ActionType.ATTACK or \
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

	# Decide if we need an attribute grid or just emit the target action
	if _needs_attribute_grid(action.type):
		# Shortcut: if all attributes give the same outcome, skip the grid
		if _current_attack_target and _cached_combat_system:
			var uniform := _get_uniform_attr_symbol(unit, action, _current_attack_target)
			if not uniform.is_empty():
				var best_attr := _get_best_attr_index(unit, action, _current_attack_target)
				_emit_attribute_action(action, best_attr, GameConstants.get_attribute_name(best_attr), action.type)
				return
		var raw_text: String = _loc.get_text(_loc.HUD_SELECT_ATTRIBUTE).format({"action": _get_action_label(action)})
		hint_label.text = GameConstants.colorize_attributes(raw_text)
		if _build_attribute_grid(unit, action):
			_add_back_button()
			force_fit_content()
	elif _current_attack_target:
		_emit_target_action(action, _current_attack_target)

func _prepare_attribute_menu(_unit: Unit, _action: PlayerAction, move_info: Dictionary) -> bool:
	_clear_actions()
	_move_info_by_target = move_info
	if not hint_label or not actions_container: return false

	hint_label.visible = not _auto_battle_mode
	hint_label.modulate = Color.WHITE
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
	var grid = _create_grid(3) # Keep 3 columns

	for attr_idx: GameConstants.AttributeIndex in GameConstants.COMBAT_ATTRIBUTE_INDICES:
		var val := unit.get_attribute(attr_idx)
		var base := unit.get_base_attribute_from_target(attr_idx)
		var attr_bonus := val - base
		var aid_bonus := _cached_combat_system.get_aid_bonus(unit, attr_idx) if _cached_combat_system else 0

		var internal_name := GameConstants.get_attribute_name(attr_idx)
		var display_name := tr("attr." + internal_name.to_lower())
		var btn_text := "%s (+%d)" % [display_name, aid_bonus]
		if attr_bonus != 0:
			btn_text = "%s:%d (+%d)" % [display_name, val, aid_bonus]

		var btn := _create_grid_button(grid, btn_text)

		var color: Color = GameConstants.get_attribute_color(attr_idx)
		btn.add_theme_color_override("font_color", color)
		btn.add_theme_color_override("font_hover_color", color.lightened(0.2))
		btn.add_theme_color_override("font_pressed_color", color.darkened(0.2))
		btn.add_theme_color_override("font_focus_color", color)

		btn.mouse_entered.connect(func(): attribute_hovered.emit(attr_idx))
		btn.mouse_exited.connect(func(): attribute_hovered.emit(-1))
		btn.pressed.connect(func(): _emit_attribute_action(action, attr_idx, display_name, GameConstants.ActionType.AID))
	return true

func _build_standard_attribute_grid(unit: Unit, action: PlayerAction) -> bool:
	var grid = _create_grid(3) # 3 columns, 2 rows for 6 attributes

	for attr_idx: GameConstants.AttributeIndex in GameConstants.COMBAT_ATTRIBUTE_INDICES:
		var val := unit.get_attribute(attr_idx)
		var base := unit.get_base_attribute_from_target(attr_idx)
		var bonus := val - base

		var internal_name := GameConstants.get_attribute_name(attr_idx)
		var display_name := tr("attr." + internal_name.to_lower())
		var btn_text := "%s(%d)" % [display_name, val]
		if bonus > 0:
			btn_text = "%s(%d+%d)" % [display_name, base, bonus]
		elif bonus < 0:
			btn_text = "%s(%d%d)" % [display_name, base, bonus]

		# For attributes, we can be more precise with the forecast
		var suffix := GameConstants.UI.Indicators.INEFFECTIVE
		if _cached_combat_system and _cached_unit and _current_attack_target:
			var is_convince: bool = _active_action and _active_action.type == GameConstants.ActionType.CONVINCE

			if _current_attack_target:
				var quality = _cached_combat_system.get_attack_quality(_cached_unit, _current_attack_target, attr_idx, is_convince)
				suffix = _cached_combat_system.get_quality_symbol(quality)
			elif _active_action and _active_action.target_to_task.has(_current_attack_target):
				var tid = _active_action.target_to_task[_current_attack_target]
				var task_manager = _cached_unit.get_task_manager()
				var task = task_manager.get_task_by_id(str(tid))
				if task:
					var quality = _cached_combat_system.get_task_quality(_cached_unit, task, attr_idx)
					suffix = _cached_combat_system.get_quality_symbol(quality)

			# For debugging, we still want the forecast values (only for unit combat)
			if _current_attack_target is Unit:
				var forecast = _cached_combat_system.get_combat_forecast(_cached_unit, _current_attack_target, attr_idx)
				GameLogger.debug(GameLogger.Category.UI, "[ActionSuffix] Attribute %s forecast: damage=%d, counter=%d -> suffix=%s" % [
					internal_name,
					forecast.get("damage_to_target", 0),
					forecast.get("counter_damage_to_self", 0),
					suffix
				])

		btn_text = "%s%s" % [btn_text, suffix]

		var btn := _create_grid_button(grid, btn_text)

		var color: Color = GameConstants.get_attribute_color(attr_idx)
		btn.add_theme_color_override("font_color", color)
		btn.add_theme_color_override("font_hover_color", color.lightened(0.2))
		btn.add_theme_color_override("font_pressed_color", color.darkened(0.2))
		btn.add_theme_color_override("font_focus_color", color)

		btn.mouse_entered.connect(func(): attribute_hovered.emit(attr_idx))
		btn.mouse_exited.connect(func(): attribute_hovered.emit(-1))
		btn.pressed.connect(func():
			var itype = GameConstants.ActionType.ATTACK
			if action.type == GameConstants.ActionType.CONVINCE or action.ui_label_params.get("is_convince", false): itype = GameConstants.ActionType.CONVINCE
			elif action.type == GameConstants.ActionType.AID: itype = GameConstants.ActionType.AID
			elif action.type == GameConstants.ActionType.EXPLORE: itype = GameConstants.ActionType.EXPLORE
			elif action.type == GameConstants.ActionType.VISIT: itype = GameConstants.ActionType.VISIT
			elif action.type == GameConstants.ActionType.TRAPPED: itype = GameConstants.ActionType.TRAPPED
			elif action.type == GameConstants.ActionType.GATHER: itype = GameConstants.ActionType.GATHER

			# We still pass internal_name under the hood so logic like `player_action.gd` operates safely.
			_emit_attribute_action(action, attr_idx, internal_name, itype)
		)
	return true

func _emit_attribute_action(action: PlayerAction, idx: int, p_name: String, interact_type: GameConstants.ActionType) -> void:
	var final: PlayerAction = PlayerActionManager.create_move_and_interact_action(action, _current_attack_target, _move_info_by_target, _cached_unit_manager, idx, p_name)
	# Override interact_type if provided (ActionsPanel calculates this locally based on button context)
	final.command_payload[GameConstants.Payload.INTERACT_ACTION_TYPE] = interact_type
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
		if _attack_targets.size() > 1 and _current_attack_target != null:
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
class_name ActionsPanel
extends CustomResizablePanel

# Localization is loaded dynamically to avoid parser issues with FilePaths

signal action_selected(action: Dictionary)
signal attribute_hovered(attribute_index: int) # -1 if exited

const BUTTON_MIN_SIZE := Vector2(160, 30)
const HINT_TEXT_COLOR := Color(1, 1, 0.8)

@onready var actions_container: VBoxContainer = %ActionsContainer
@onready var hint_label: Label = %HintLabel

# State cache for Back button
var _cached_unit: Unit
var _cached_terrain
var _cached_unit_manager: UnitManager
var _turn_enabled := true
var _attack_targets: Array[Target] = []
var _reachable_attack_targets: Array[Target] = []
var _current_attack_target: Target
var _move_info_by_target: Dictionary = {}
var _last_nav_target: Control
var _auto_battle_mode := false
var _actions_container_missing_logged := false
var _no_unit_selected_logged := false
var _enemy_unit_selected_logged := false
var _no_actions_logged := false

var _pending_update = null
var _loc := load(FilePaths.Resources.LOCALIZATION_STRINGS) as GDScript
var _action_hint_keys := {
	GameConstants.ActionIds.LOCATION_OPPOSED: _loc.HUD_HINT_EXPLORE_LOCATION,
	GameConstants.ActionIds.LOCATION_UNOPPOSED: _loc.HUD_HINT_VISIT_LOCATION,
	GameConstants.ActionIds.UNIT_UNOPPOSED: _loc.HUD_HINT_TALK,
	GameConstants.ActionIds.ITEM_OPPOSED: _loc.HUD_HINT_TRAPPED,
	GameConstants.ActionIds.ITEM_UNOPPOSED: _loc.HUD_HINT_LOOT,
	GameConstants.ActionIds.WAIT: _loc.HUD_HINT_WAIT,
	GameConstants.ActionIds.MOVE: _loc.HUD_HINT_MOVE,
	GameConstants.ActionIds.SKILL: _loc.HUD_HINT_SKILL,
	GameConstants.Commands.UNDO: _loc.HUD_HINT_UNDO,
	GameConstants.Interactions.AID: _loc.HUD_HINT_AID
}

func _ready() -> void:
	print_debug("ActionsPanel._ready() called - Panel is initializing")
	LocaleService.locale_changed.connect(_on_locale_changed)
	if _pending_update:
		update_actions(_pending_update.unit, _pending_update.terrain_map, _pending_update.unit_manager)
		_pending_update = null

func _on_locale_changed() -> void:
	if is_instance_valid(_cached_unit):
		update_actions(_cached_unit, _cached_terrain, _cached_unit_manager, _turn_enabled)

	min_width = 280
	min_height = 50
	super._ready()
	focus_mode = Control.FOCUS_ALL

	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	if hint_label:
		hint_label.text = _loc.get_text("hud.actions_hint")
		hint_label.visible = false
		hint_label.modulate = Color(1, 1, 1, 0)
		hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hint_label.add_theme_color_override("font_color", HINT_TEXT_COLOR)
		hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hint_label.custom_minimum_size = Vector2(0, 18)

	queue_redraw()

func update_actions(unit: Unit, terrain_map, unit_manager: UnitManager, turn_enabled: bool = true) -> void:
	if is_instance_valid(unit) and unit.is_inside_tree():
		print_debug("[ActionsPanel] update_actions called for: ", unit.unit_name, " (enabled=", turn_enabled, ")")

	if _should_defer_update(unit, terrain_map, unit_manager, turn_enabled):
		return

	_cached_unit = unit
	_cached_terrain = terrain_map
	_cached_unit_manager = unit_manager
	_turn_enabled = turn_enabled


	show() # Ensure we are visible
	_clear_actions()

	if _handle_missing_unit(unit):
		return

	if _handle_enemy_unit(unit_manager, unit):
		return

	var available_actions = UnitActionManager.get_available_actions(unit, terrain_map, unit_manager)
	if _handle_no_actions(unit, available_actions):
		return

	_show_actions_hint()

	for action in available_actions:
		_add_action_button(unit, action)

	force_fit_content()

func _should_defer_update(unit: Unit, terrain_map, unit_manager: UnitManager, turn_enabled: bool) -> bool:
	if is_node_ready():
		return false
	_pending_update = {
		"unit": unit,
		"terrain_map": terrain_map,
		"unit_manager": unit_manager,
		"turn_enabled": turn_enabled
	}
	return true

func _handle_missing_unit(unit: Unit) -> bool:
	if is_instance_valid(unit):
		_no_unit_selected_logged = false
		return false
	if not _no_unit_selected_logged:
		_no_unit_selected_logged = true
		push_warning("[ActionsPanel] No unit selected; showing hint only.")
	_show_hint(_loc.get_text(_loc.HUD_NO_UNIT_SELECTED))
	return true

func _handle_enemy_unit(unit_manager: UnitManager, unit: Unit) -> bool:
	if unit_manager == null or not is_instance_valid(unit):
		return false
	var unit_index = unit_manager.get_unit_index(unit)
	if unit_manager.is_player_controlled(unit_index):
		_enemy_unit_selected_logged = false
		return false
	if not _enemy_unit_selected_logged:
		_enemy_unit_selected_logged = true
		push_warning("[ActionsPanel] Selected unit is not player-controlled; showing hint only.")
	_show_hint(_loc.get_text(_loc.HUD_ENEMY_UNIT_SELECTED))
	return true

func _handle_no_actions(unit: Unit, available_actions: Array) -> bool:
	if not available_actions.is_empty():
		_no_actions_logged = false
		return false
	if not _no_actions_logged:
		_no_actions_logged = true
		var unit_name := unit.unit_name if is_instance_valid(unit) else "Unknown"
		push_warning("[ActionsPanel] No available actions for unit %s." % unit_name)
	_show_hint(_loc.get_text(_loc.HUD_NO_ACTIONS_AVAILABLE))
	return true

func _add_action_button(unit: Unit, action: Dictionary) -> Button:
	if not is_instance_valid(actions_container):
		if not _actions_container_missing_logged:
			_actions_container_missing_logged = true
			push_warning("[ActionsPanel] actions_container is missing; cannot add actions.")
		return null
	_actions_container_missing_logged = false
	var btn := Button.new()
	btn.text = _get_action_label(action)
	btn.custom_minimum_size = BUTTON_MIN_SIZE
	btn.disabled = not action.get("available", true) or not _turn_enabled
	btn.tooltip_text = _get_action_hint(action)
	_register_focus_target(btn)
	var action_ref: Dictionary = action
	btn.pressed.connect(func():
		if action_ref.get("needs_attribute", false):
			show_attribute_menu(unit, action_ref)
		else:
			action_selected.emit(action_ref)
	)
	actions_container.add_child(btn)
	return btn

func set_auto_battle_mode(active: bool) -> void:
	_auto_battle_mode = active
	if is_instance_valid(actions_container):
		actions_container.modulate = Color(1, 1, 1, 0.6) if active else Color(1, 1, 1, 1)
	if is_instance_valid(hint_label):
		hint_label.visible = not active and not hint_label.text.is_empty()

func show_attack_menu(attacker: Unit, target: Target, targets: Array = [], reachable_targets: Array = [], move_info: Dictionary = {}) -> void:
	var action := {
		"type": "attack",
		"label": _loc.get_text(_loc.HUD_ACTION_ATTACK),
		"target": target,
		"targets": targets,
		"reachable_targets": reachable_targets,
		"needs_attribute": true
	}
	show_attribute_menu(attacker, action, move_info)
func show_attribute_menu(unit: Unit, action: Dictionary, move_info: Dictionary = {}) -> void:
	print_debug("ActionsPanel: show_attribute_menu called, attacker=", unit.unit_name if unit else "null", " target=", _get_target_name(action.get("target")))

	if not _prepare_attribute_menu(unit, action, move_info):
		return

	var targets := _populate_target_lists(action)
	if targets.size() > 1:
		_add_target_selector(unit, action, targets)
	elif targets.size() == 1 and (_current_attack_target == null or not targets.has(_current_attack_target)):
		_current_attack_target = targets[0]
	elif targets.is_empty():
		_current_attack_target = null

	var attrs_label := Label.new()
	attrs_label.text = _loc.get_text(_loc.HUD_SELECT_ATTRIBUTE_TITLE)
	attrs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	actions_container.add_child(attrs_label)

	if not _build_attribute_grid(unit, action):
		return

	_add_back_button()
	force_fit_content()

func _prepare_attribute_menu(unit: Unit, action: Dictionary, move_info: Dictionary) -> bool:
	_clear_actions()
	_move_info_by_target = move_info
	if not is_instance_valid(hint_label) or not is_instance_valid(actions_container):
		return false
	hint_label.text = _loc.get_text(_loc.HUD_SELECT_ATTRIBUTE).format({"action": _get_action_label(action)})
	hint_label.visible = not _auto_battle_mode
	hint_label.modulate = Color(1, 1, 1, 1)
	attribute_hovered.emit(-1)
	return true

func _populate_target_lists(action: Dictionary) -> Array[Target]:
	_attack_targets.clear()
	_reachable_attack_targets.clear()
	var targets: Array = action.get("targets", []).duplicate()
	if targets.is_empty() and action.has("target"):
		var fallback = action.get("target")
		if fallback:
			targets.append(fallback)
	for candidate in targets:
		if candidate and candidate is Target and not _attack_targets.has(candidate):
			_attack_targets.append(candidate)
	var reachable: Array = action.get("reachable_targets", [])
	for candidate in reachable:
		if candidate and candidate is Target and not _reachable_attack_targets.has(candidate):
			_reachable_attack_targets.append(candidate)
	return _attack_targets

func _add_target_selector(unit: Unit, action: Dictionary, targets: Array[Target]) -> void:
	if targets.is_empty():
		return
	var targets_label := Label.new()
	targets_label.text = _loc.get_text("hud.location_label")
	targets_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	actions_container.add_child(targets_label)
	if not _current_attack_target or not targets.has(_current_attack_target):
		_current_attack_target = targets[0]
	var target_grid := GridContainer.new()
	target_grid.columns = 2
	target_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_container.add_child(target_grid)
	var target_group := ButtonGroup.new()
	for target_obj in targets:
		var target_ref: Target = target_obj
		var btn := Button.new()
		btn.toggle_mode = true
		_register_focus_target(btn)
		btn.button_group = target_group
		btn.button_pressed = target_ref == _current_attack_target
		btn.text = _format_target_button_text(target_ref)
		btn.custom_minimum_size = Vector2(100, 30)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func():
			if target_ref == _current_attack_target:
				return
			_current_attack_target = target_ref
			show_attribute_menu(unit, action, _move_info_by_target)
		)
		target_grid.add_child(btn)

func _build_attribute_grid(unit: Unit, action: Dictionary) -> bool:
	var attrs = unit.inv.get_attributes() if unit and unit.inv else null
	if not attrs:
		_show_hint(_loc.get_text(_loc.HUD_NO_ATTRIBUTES_AVAILABLE))
		_add_back_button()
		return false
	
	var is_aid = action.get("type") == GameConstants.Interactions.AID or action.get("interact_action_type") == GameConstants.Interactions.AID
	
	var grid := GridContainer.new()
	grid.columns = 3 if is_aid else 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_container.add_child(grid)
	
	if is_aid:
		var pairs = ["pair.body", "pair.mind", "pair.spirit"]
		for i in range(3):
			var pair_idx = i
			var pair = CombatSystem.PAIRS[pair_idx]
			var val_a = attrs.get_attribute(pair[0])
			var val_b = attrs.get_attribute(pair[1])
			var max_val = max(val_a, val_b)
			var bonus = int(floor(max_val / 2.0))
			
			var btn := Button.new()
			var pair_name = tr(pairs[i])
			btn.text = "%s (+%d)" % [pair_name, bonus]
			btn.custom_minimum_size = BUTTON_MIN_SIZE
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_register_focus_target(btn)
			
			btn.pressed.connect(func():
				var final_action = action.duplicate(true)
				final_action["attribute_index"] = pair_idx * 2 # Map to first attr of pair
				final_action["target"] = _current_attack_target
				if _move_info_by_target.has(_current_attack_target):
					var m_data = _move_info_by_target[_current_attack_target]
					final_action["type"] = GameConstants.Commands.MOVE_AND_INTERACT_TYPE
					final_action["action_id"] = GameConstants.ActionIds.MOVE_AND_INTERACT
					final_action["target_move_coord"] = m_data.coord
					final_action["movement_cost"] = int(m_data.cost)
					final_action["action_cost"] = 1
					final_action["interact_action_type"] = GameConstants.Interactions.AID
				action_selected.emit(final_action)
			)
			grid.add_child(btn)
		return true

	var attribute_order: Array[int] = [0, 2, 4, 1, 3, 5]
	for attr_index: int in attribute_order:
		var attr_name: String = Target.COMBAT_ATTRIBUTE_NAMES[attr_index]
		var val: int = attrs.get_attribute(attr_name)
		var btn := Button.new()
		btn.text = _loc.get_text(_loc.HUD_ATTRIBUTE_VALUE).format({"attribute": attr_name.capitalize(), "value": val})
		btn.custom_minimum_size = BUTTON_MIN_SIZE
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_register_focus_target(btn)
		btn.mouse_entered.connect(func(): attribute_hovered.emit(attr_index))
		btn.mouse_exited.connect(func(): attribute_hovered.emit(-1))
		btn.pressed.connect(func():
			var final_action = action.duplicate(true)
			final_action["attribute_index"] = attr_index
			final_action["attribute_name"] = attr_name
			final_action["target"] = _current_attack_target
			if _move_info_by_target.has(_current_attack_target):
				var m_data = _move_info_by_target[_current_attack_target]
				final_action["type"] = GameConstants.Commands.MOVE_AND_INTERACT_TYPE
				final_action["action_id"] = GameConstants.ActionIds.MOVE_AND_INTERACT
				final_action["target_move_coord"] = m_data.coord
				final_action["movement_cost"] = int(m_data.cost)
				final_action["action_cost"] = 1
				var interact_type = action.get("interact_action_type", GameConstants.Interactions.ATTACK)
				var act_type = action.get("type", "")
				if act_type == "convince" or action.get("label_params", {}).get("is_convince", false):
					interact_type = GameConstants.Interactions.CONVINCE
				elif act_type == GameConstants.Interactions.AID:
					interact_type = GameConstants.Interactions.AID
				
				final_action["interact_action_type"] = interact_type
			action_selected.emit(final_action)
		)
		grid.add_child(btn)
	return true

func get_current_attack_target() -> Target:
	return _current_attack_target
func _render_attack_menu(_attacker: Unit) -> void:
	# Deprecated by show_attribute_menu
	pass

func _add_attribute_buttons(_attacker: Unit) -> void:
	# Deprecated by show_attribute_menu
	pass

func _add_back_button() -> void:
	var back_btn := Button.new()
	_register_focus_target(back_btn)
	back_btn.text = _loc.get_text(_loc.HUD_ACTION_BACK)
	back_btn.custom_minimum_size = BUTTON_MIN_SIZE
	back_btn.pressed.connect(_on_back_pressed)
	back_btn.mouse_entered.connect(func(): attribute_hovered.emit(-1))
	actions_container.add_child(back_btn)

func _format_target_button_text(target: Target) -> String:
	if target == null:
		return _loc.get_text(_loc.HUD_TARGET_UNKNOWN)
	var suffix := ""
	if _reachable_attack_targets.has(target) or _move_info_by_target.has(target):
		suffix = _loc.get_text(_loc.HUD_TARGET_MOVE_SUFFIX)
	return "%s%s" % [_get_target_name(target), suffix]

func _get_target_name(target: Target) -> String:
	if not target: return _loc.get_text(_loc.HUD_TARGET_NA)
	if target is Unit:
		return target.unit_name
	if target is Location:
		return TranslationServer.translate(StringName(target.loc_name))
	if target is Loot:
		return _loc.get_text(_loc.HUD_TARGET_TRAPPED_LOOT)
	return _loc.get_text(_loc.HUD_TARGET_GENERIC)

func _on_back_pressed() -> void:
	if is_instance_valid(_cached_unit):
		update_actions(_cached_unit, _cached_terrain, _cached_unit_manager)

func _clear_actions() -> void:
	if not is_instance_valid(actions_container):
		if not _actions_container_missing_logged:
			_actions_container_missing_logged = true
			push_warning("[ActionsPanel] actions_container is missing; cannot clear actions.")
		return
	_actions_container_missing_logged = false
	# Ensure hint_label is not freed
	if is_instance_valid(hint_label):
		if hint_label.get_parent() == actions_container:
			actions_container.remove_child(hint_label)

	# Clear all other children
	for child in actions_container.get_children():
		child.queue_free()

	# Restore hint label if it was removed
	if is_instance_valid(hint_label) and hint_label.get_parent() == null:
		actions_container.add_child(hint_label)

	_update_hint_visibility()

func _update_hint_visibility() -> void:
	if is_instance_valid(hint_label):
		hint_label.visible = not _auto_battle_mode and actions_container.get_child_count() <= 1

func _show_hint(msg: String) -> void:
	if is_instance_valid(hint_label):
		hint_label.text = msg
	_update_hint_visibility()

func _show_actions_hint() -> void:
	if is_instance_valid(hint_label):
		hint_label.modulate = Color(1, 1, 1, 1)
	_update_hint_visibility()

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

func _get_action_label(action: Dictionary) -> String:
	var aid = action.get("action_id", "")
	if aid == "":
		return action.get("label", _loc.get_text(_loc.HUD_ACTION_UNKNOWN))

	var params = action.get("label_params", {}).duplicate()


	# Special case: move_and_interact
	if aid == GameConstants.ActionIds.MOVE_AND_INTERACT:
		var interaction_id = action.get("interaction_id", "")
		var sub_label = _loc.get_text(interaction_id)

		# If it's a social attack on a neutral, use "Convince"
		if interaction_id == GameConstants.ActionIds.UNIT_OPPOSED:
			var target = action.get("target")
			if target and target.get("faction") == Unit.Faction.NEUTRAL:
				sub_label = _loc.get_text("action_convince")

		return _loc.get_text("hud.action_move_and_interact").format({
			"action": sub_label,
			"target": _get_target_name(action.get("target")),
			"move": int(action.get("movement_cost", 0)),
			"action_point": int(action.get("action_cost", 1))
		})

	# Special case: UNIT_OPPOSED for social attacks
	if aid == GameConstants.ActionIds.UNIT_OPPOSED and params.get("is_convince", false):
		aid = "action_convince"

	# Handle composite counts
	if params.has("adjacent") or params.has("reachable"):
		var base_label = _loc.get_text(aid)
		var detail: Array[String] = []
		if params.get("adjacent", 0) > 0:
			var imm_key = "hud.action_label_" + str(params.get("imm_label", "adjacent"))
			detail.append(_loc.get_text("hud.action_format_adjacent").format({
				"count": params.adjacent,
				"label": _loc.get_text(imm_key)
			}))
		if params.get("reachable", 0) > 0:
			detail.append(_loc.get_text("hud.action_format_reachable").format({
				"count": params.reachable
			}))
		if not detail.is_empty():
			return _loc.get_text("hud.action_format_combined").format({
				"base": base_label,
				"details": _loc.get_text("hud.action_list_separator").join(detail)
			})
		return base_label

	# Standard localized string with params
	return _loc.get_text(aid).format(params)

func _get_action_hint(action: Dictionary) -> String:
	if action.has("hint"):
		return str(action.hint)

	var aid = action.get("action_id", "")
	if aid == "":
		return ""

	if _action_hint_keys.has(aid):
		return _loc.get_text(_action_hint_keys[aid])

	match aid:
		GameConstants.ActionIds.UNIT_OPPOSED:
			if action.get("label_params", {}).get("is_convince", false):
				return _loc.get_text(_loc.HUD_HINT_CONVINCE_NEUTRAL)
			if action.get("reachable", false):
				return _loc.get_text(_loc.HUD_ACTION_HINT_REACHABLE_FIGHT)
			return _loc.get_text(_loc.HUD_HINT_FIGHT)
		GameConstants.ActionIds.MOVE_AND_INTERACT:
			var interaction_id = action.get("interaction_id", "")
			if _action_hint_keys.has(interaction_id):
				return _loc.get_text(_action_hint_keys[interaction_id])
			if interaction_id == GameConstants.ActionIds.UNIT_OPPOSED:
				var target = action.get("target")
				if target and target.get("faction") == Unit.Faction.NEUTRAL:
					return _loc.get_text(_loc.HUD_HINT_CONVINCE_NEUTRAL)
				return _loc.get_text(_loc.HUD_ACTION_HINT_REACHABLE_FIGHT)
	return ""







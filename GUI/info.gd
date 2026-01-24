class_name Info
extends CanvasLayer

const UnitActionManager := preload("res://Gameplay/unit_action_manager.gd")
const CommandResult := preload("res://Gameplay/input_commands/command_result.gd")
const LocalizationStrings := preload("res://Resources/Localization/localization_strings.gd")

signal action_executed(action_type: String)

const UI_MARGIN := 20.0
const PANEL_PADDING := 10.0
const DEFAULT_PANEL_SIZE := Vector2(200, 80)
const UNIT_PANEL_SIZE := Vector2(200, 100)
const ACTIONS_PANEL_SIZE := Vector2(220, 220)
const PREVIEW_PANEL_SIZE := Vector2(200, 120)
const GOAL_PANEL_SIZE := Vector2(200, 120)
const TERRAIN_PANEL_SIZE := Vector2(200, 100)
const BUTTON_MIN_SIZE := Vector2(160, 30)
const HINT_TEXT_COLOR := Color(1, 1, 0.8)
const WARNING_DURATION := 2.5
const WARNING_COLOR := Color(1, 0.2, 0.2) # Red
const WARNING_FONT_SIZE := 18

var round_label: Label
var turn_label: Label
var active_unit_label: Label
var unit_details_container: VBoxContainer
var unit_panel: Panel
var unit_name_label: Label
var unit_stats_label: Label
var unit_moves_label: Label
var unit_stuck_label: Label
var preview_panel: Panel
var preview_label: Label
var actions_panel: Panel
var actions_container: VBoxContainer
var goal_panel: Panel
var goal_name_label: Label
var goal_type_label: Label
var goal_progress_label: Label
var goal_required_amount_label: Label
var terrain_panel: Panel
var terrain_type_label: Label
var terrain_effect_label: Label
var terrain_distance_label: Label
var _warning_overlay: Control

var _current_unit: Unit
var _current_unit_index: int = -1
var _terrain_map
var _unit_manager: UnitManager
var _turn_controller: TurnController
var _input_controller: InputController # Reference to InputController for command routing
var _goal_manager: GoalManager
var _actions_hint_label: Label

func _ready() -> void:
	if has_node("Panel"):
		_setup_existing_ui()
	else:
		_create_default_ui()

func setup(unit_manager: UnitManager, turn_controller: TurnController, input_controller: InputController = null, goal_manager: GoalManager = null) -> void:
	_unit_manager = unit_manager
	_turn_controller = turn_controller
	_input_controller = input_controller
	_goal_manager = goal_manager
	print_debug("Info.setup: input_controller set=", _input_controller != null)
	if _turn_controller:
		_turn_controller.turn_changed.connect(update_turn_details)

func update_turn_details(unit: Unit) -> void:
	if unit == null:
		active_unit_label.text = ""
		return

	var unit_name := unit.unit_name
	if unit_name.is_empty():
		unit_name = LocalizationStrings.get_text("hud.unit_name_fallback")
	var action_str = LocalizationStrings.get_text("hud.generic_yes") if unit.has_action_available() else LocalizationStrings.get_text("hud.generic_no")
	var moves_str = "%d/%d" % [unit.get_remaining_movement_points(), unit.get_max_movement_points()]
	active_unit_label.text = LocalizationStrings.get_text("hud.active_unit_summary").format({
		"unit": unit_name,
		"action": action_str,
		"move": moves_str,
	})


func _setup_existing_ui() -> void:
	round_label = $Panel/VBoxContainer/RoundLabel
	turn_label = $Panel/VBoxContainer/TurnLabel
	unit_details_container = $Panel/VBoxContainer/UnitDetailsContainer
	active_unit_label = $Panel/VBoxContainer/UnitDetailsContainer/ActiveUnitLabel
	unit_panel = $UnitPanel
	unit_name_label = $UnitPanel/VBoxContainer/NameLabel
	unit_stats_label = $UnitPanel/VBoxContainer/StatsLabel
	unit_moves_label = $UnitPanel/VBoxContainer/MovesLabel
	if unit_panel.has_node("VBoxContainer/StuckLabel"):
		unit_stuck_label = $UnitPanel/VBoxContainer/StuckLabel
	preview_panel = $PreviewPanel
	if preview_panel:
		preview_label = $PreviewPanel/Label
	if has_node("ActionsPanel"):
		actions_panel = $ActionsPanel
		if actions_panel.has_node("ScrollContainer/VBoxContainer"):
			actions_container = $ActionsPanel/ScrollContainer/VBoxContainer
		# Prepare (or create) a lightweight hint label under the actions panel
		if actions_panel and not actions_panel.has_node("ActionsHintLabel"):
			_actions_hint_label = Label.new()
			_actions_hint_label.name = "ActionsHintLabel"
			_actions_hint_label.text = LocalizationStrings.get_text("hud.actions_hint")
			_actions_hint_label.visible = false
			_actions_hint_label.modulate = Color(1, 1, 1, 0)
			_actions_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_actions_hint_label.add_theme_color_override("font_color", HINT_TEXT_COLOR)
			actions_panel.add_child(_actions_hint_label)
			# Position near panel header/top-left with small margin
			_actions_hint_label.position = Vector2(8, 8)
		else:
			_actions_hint_label = actions_panel.get_node_or_null("ActionsHintLabel") as Label

	if has_node("GoalPanel"):
		goal_panel = $GoalPanel
		if goal_panel.has_node("VBoxContainer/NameLabel"):
			goal_name_label = $GoalPanel/VBoxContainer/NameLabel
		if goal_panel.has_node("VBoxContainer/TypeLabel"):
			goal_type_label = $GoalPanel/VBoxContainer/TypeLabel
		if goal_panel.has_node("VBoxContainer/ProgressLabel"):
			goal_progress_label = $GoalPanel/VBoxContainer/ProgressLabel
		if goal_panel.has_node("VBoxContainer/RequiredAmountLabel"):
			goal_required_amount_label = $GoalPanel/VBoxContainer/RequiredAmountLabel

	if has_node("TerrainPanel"):
		terrain_panel = $TerrainPanel
		if terrain_panel.has_node("VBoxContainer/TypeLabel"):
			terrain_type_label = $TerrainPanel/VBoxContainer/TypeLabel
		if terrain_panel.has_node("VBoxContainer/EffectLabel"):
			terrain_effect_label = $TerrainPanel/VBoxContainer/EffectLabel
		if terrain_panel.has_node("VBoxContainer/DistanceLabel"):
			terrain_distance_label = $TerrainPanel/VBoxContainer/DistanceLabel

func update_round(round_num: int) -> void:
	if round_label:
		round_label.text = LocalizationStrings.get_text("hud.round_label").format({
			"round": round_num,
		})

func update_turn(is_player: bool) -> void:
	if turn_label:
		var side_text = LocalizationStrings.get_text("hud.turn_player") if is_player else LocalizationStrings.get_text("hud.turn_enemy")
		turn_label.text = LocalizationStrings.get_text("hud.turn_label").format({
			"side": side_text,
		})
		turn_label.modulate = Color.GREEN if is_player else Color.RED
	if unit_details_container:
		unit_details_container.visible = is_player


func update_unit_details(unit: Unit) -> void:
	if unit == null:
		if unit_panel:
			unit_panel.visible = false
		_current_unit = null
		return

	_current_unit = unit
	if unit_panel:
		unit_panel.visible = true

	if unit_name_label:
		unit_name_label.text = unit.unit_name if not unit.unit_name.is_empty() else LocalizationStrings.get_text("hud.unit_name_fallback")

	if unit_stats_label:
		unit_stats_label.text = LocalizationStrings.get_text("hud.unit_stats").format({
			"faction": unit.get_faction_name(),
			"current": unit.willpower,
			"max": unit.max_willpower,
		})

	if unit_moves_label:
		var moves = unit.get_remaining_movement_points()
		var max_moves = unit.get_max_movement_points()
		var can_act = unit.has_action_available()
		var action_text = LocalizationStrings.get_text("hud.generic_yes") if can_act else LocalizationStrings.get_text("hud.generic_no")
		unit_moves_label.text = LocalizationStrings.get_text("hud.movement_summary").format({
			"moves": moves,
			"max_moves": max_moves,
			"action": action_text,
		})

	# Update stuck status if label exists
	if unit_stuck_label and _terrain_map and _unit_manager:
		var is_stuck = UnitActionManager.is_unit_stuck(unit, _terrain_map, _unit_manager)
		var status_text = LocalizationStrings.get_text("hud.status_stuck") if is_stuck else LocalizationStrings.get_text("hud.status_ok")
		unit_stuck_label.text = status_text
		unit_stuck_label.modulate = Color.RED if is_stuck else Color.GREEN

func update_available_actions(unit: Unit, terrain_map, unit_manager: UnitManager, unit_index: int = -1) -> void:
	_current_unit = unit
	_terrain_map = terrain_map
	_unit_manager = unit_manager

	if unit_index < 0 and unit and unit_manager:
		_current_unit_index = unit_manager.get_unit_index(unit)
	else:
		_current_unit_index = unit_index

	if not actions_container:
		return

	# Clear previous action buttons but keep the hint label around for reuse
	for child in actions_container.get_children():
		if child == _actions_hint_label:
			continue
		child.queue_free()

	if not unit:
		if actions_panel:
			actions_panel.visible = false
			print_debug("Info.update_available_actions: no unit; hiding actions panel")
		if _actions_hint_label:
			_actions_hint_label.visible = false
		return

	var available_actions = UnitActionManager.get_available_actions(unit, terrain_map, unit_manager)
	print_debug("Info.update_available_actions: refreshing; actions=%d" % [available_actions.size()])

	if available_actions.is_empty():
		if actions_panel:
			actions_panel.visible = false
			print_debug("Info.update_available_actions: no available actions; hiding panel")
		if _actions_hint_label:
			_actions_hint_label.visible = false
		return

	if actions_panel:
		var was_hidden := not actions_panel.visible
		actions_panel.visible = true
		# Subtle highlight when the panel first opens to hint availability
		if was_hidden:
			var t := actions_panel.create_tween()
			t.tween_property(actions_panel, "modulate", Color(1, 1, 0.7, 1), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			t.tween_property(actions_panel, "modulate", Color(1, 1, 1, 1), 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			print_debug("Info.update_available_actions: panel opened; showing hint")
		_show_actions_hint(available_actions)
		if not was_hidden:
			print_debug("Info.update_available_actions: panel already visible; refreshing buttons")

	# Create buttons for each action (always rebuild to reflect latest data)
	for action in available_actions:
		var btn = Button.new()
		btn.text = action.label
		btn.custom_minimum_size = BUTTON_MIN_SIZE
		btn.disabled = not action.available
		if action.has("hint"):
			btn.tooltip_text = str(action.hint)
		btn.pressed.connect(_on_action_button_pressed.bind(action))
		actions_container.add_child(btn)

## Show a brief tooltip hint near the Actions panel

func _show_actions_hint(available_actions: Array) -> void:
	if not actions_panel:
		return
	if _actions_hint_label == null:
		# Create lazily if not present (e.g., dynamically built UI)
		_actions_hint_label = Label.new()
		_actions_hint_label.name = "ActionsHintLabel"
		_actions_hint_label.text = LocalizationStrings.get_text("hud.actions_hint")
		_actions_hint_label.visible = false
		_actions_hint_label.modulate = Color(1, 1, 1, 0)
		_actions_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_actions_hint_label.add_theme_color_override("font_color", HINT_TEXT_COLOR)
		_actions_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_actions_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_actions_hint_label.custom_minimum_size = Vector2(0, 18)
		if actions_container:
			actions_container.add_child(_actions_hint_label)
			_actions_hint_label.position = Vector2.ZERO
		else:
			actions_panel.add_child(_actions_hint_label)
	if actions_container:
		var current_parent = _actions_hint_label.get_parent()
		if current_parent != actions_container:
			if current_parent:
				current_parent.remove_child(_actions_hint_label)
			actions_container.add_child(_actions_hint_label)
		_actions_hint_label.position = Vector2.ZERO
		actions_container.move_child(_actions_hint_label, 0)

	# Ensure the hint stays visible (no auto-hide)
	_actions_hint_label.visible = true
	_actions_hint_label.modulate = Color(1, 1, 1, 1)
	print_debug("Info._show_actions_hint: showing persistent hint; buttons=%d" % [available_actions.size()])

func _on_action_button_pressed(action: Dictionary) -> void:
	var action_type: String = action.get("type", "unknown")
	print_debug("Info._on_action_button_pressed: action=%s" % [action_type])

	if _unit_manager:
		_current_unit = _unit_manager.get_selected_unit()
		_current_unit_index = _unit_manager.get_selected_index()

	if not _current_unit or _current_unit_index < 0:
		print_debug("Info._on_action_button_pressed: no current unit or invalid index")
		return

	# Handle tentative moves first
	if _current_unit.has_tentative_move():
		print_debug("Info._on_action_button_pressed: resolving tentative move first")
		if _input_controller:
			_input_controller._execute_command("confirm_move")
			await _await_tentative_resolution()

		if _current_unit == null or _current_unit.has_tentative_move():
			print_debug("Info._on_action_button_pressed: tentative move still pending; aborting action")
			return

	# Execute the action
	var success := _execute_action(action)
	print_debug("Info._on_action_button_pressed: execution result success=%s" % success)

	if success:
		action_executed.emit(action_type)

	_refresh_actions_after_command()

func _refresh_actions_after_command() -> void:
	update_unit_details(_current_unit)

	if _current_unit and _turn_controller and _current_unit_index >= 0:
		var has_movement = _current_unit.has_move_available()
		var available_actions = UnitActionManager.get_available_actions(_current_unit, _terrain_map, _unit_manager)
		var has_actions = not available_actions.is_empty() and _current_unit.has_action_available()

		if not has_movement and not has_actions:
			_turn_controller.complete_player_activation(_current_unit_index)
			print_debug("DBG action handler: turn completed (no movement, no actions remaining)")
		elif has_actions:
			update_available_actions(_current_unit, _terrain_map, _unit_manager, _current_unit_index)
		else:
			if actions_panel:
				actions_panel.visible = false

func show_combat_preview(attacker: Unit, defender: Unit) -> void:
	if not preview_panel:
		return
	preview_panel.visible = true
	if preview_label:
		var dist = attacker.distance_to_target(defender)
		var in_range = dist <= attacker.action_range
		var target_name = defender.unit_name if not defender.unit_name.is_empty() else LocalizationStrings.get_text("hud.enemy_fallback")
		var lines_buffer: Array[String] = []
		lines_buffer.append(LocalizationStrings.get_text("hud.combat_preview.target").format({"name": target_name}))
		lines_buffer.append(LocalizationStrings.get_text("hud.combat_preview.faction").format({"faction": defender.get_faction_name()}))
		lines_buffer.append(LocalizationStrings.get_text("hud.combat_preview.willpower").format({
			"current": defender.willpower,
			"max": defender.max_willpower,
		}))
		lines_buffer.append(LocalizationStrings.get_text("hud.combat_preview.range").format({
			"distance": dist,
			"max_range": attacker.action_range,
		}))
		var attack_text = LocalizationStrings.get_text("hud.generic_yes") if in_range else LocalizationStrings.get_text("hud.generic_no")
		lines_buffer.append(LocalizationStrings.get_text("hud.combat_preview.can_attack").format({"value": attack_text}))
		preview_label.text = "\n".join(lines_buffer)

func hide_combat_preview() -> void:
	if preview_panel:
		preview_panel.visible = false

func update_goal_details(goal_node: Goal) -> void:
	if goal_node == null:
		if goal_panel:
			goal_panel.visible = false
		return

	if not goal_panel:
		# If panel doesn't exist, create it (for programmatic UI)
		_create_goal_panel()

	goal_panel.visible = true

	var goal_index = -1
	if _goal_manager:
		goal_index = _goal_manager.get_goal_node_index(goal_node) # Assuming a method to get index from node

	if goal_name_label:
		var goal_name : String = goal_node.name if goal_node.name else ""
		if goal_name.is_empty():
			goal_name = LocalizationStrings.get_text("hud.goal_fallback_name")
		goal_name_label.text = LocalizationStrings.get_text("hud.goal_label").format({
			"name": goal_name,
		})

	if goal_type_label and _goal_manager and goal_index != -1:
		var type_text = LocalizationStrings.get_text("hud.goal_type").format({
			"type": _goal_manager.get_required_type(goal_index),
		})
		if _goal_manager.has_method("get_current_step_description"):
			var desc = _goal_manager.get_current_step_description(goal_index)
			if not desc.is_empty():
				type_text += "
%s" % desc
		goal_type_label.text = type_text

	if goal_progress_label and _goal_manager and goal_index != -1:
		var player_progress = _goal_manager.get_progress(goal_index, Unit.Faction.PLAYER)
		var enemy_progress = _goal_manager.get_progress(goal_index, Unit.Faction.ENEMY)
		goal_progress_label.text = LocalizationStrings.get_text("hud.goal_progress").format({
			"player": player_progress,
			"enemy": enemy_progress,
		})

	if goal_required_amount_label and _goal_manager and goal_index != -1:
		goal_required_amount_label.text = LocalizationStrings.get_text("hud.goal_required").format({
			"amount": _goal_manager.get_required_amount(goal_index),
		})

func update_terrain_details(terrain: TerrainTile, distance_str: String = "") -> void:
	if terrain == null:
		if terrain_panel:
			terrain_panel.visible = false
		return

	if not terrain_panel:
		_create_terrain_panel()

	terrain_panel.visible = true

	if terrain_type_label:
		# Infer name from script path or class name if available, fallback to localized name
		var type_name = LocalizationStrings.get_text("hud.terrain_fallback_name")
		var script_path = terrain.get_script().resource_path
		var file_name = script_path.get_file().get_basename()
		type_name = file_name.replace("_terrain", "").capitalize()
		terrain_type_label.text = LocalizationStrings.get_text("hud.terrain_type").format({
			"type": type_name,
		})

	if terrain_effect_label:
		var effect_parts: Array[String] = []
		if not terrain.passable:
			effect_parts.append(LocalizationStrings.get_text("hud.terrain_effect_impassable"))
		else:
			var cost = 1 + terrain.movement_penalty - terrain.movement_bonus
			effect_parts.append(LocalizationStrings.get_text("hud.terrain_effect_cost").format({"cost": cost}))
			if terrain.blocks_action_after_move:
				effect_parts.append(LocalizationStrings.get_text("hud.terrain_effect_ends_turn"))
			if not terrain.status_effect.is_empty():
				effect_parts.append(terrain.status_effect)
		var effects_combined = ", ".join(effect_parts)
		terrain_effect_label.text = LocalizationStrings.get_text("hud.terrain_effects").format({
			"effects": effects_combined,
		})

	if terrain_distance_label:
		terrain_distance_label.text = LocalizationStrings.get_text("hud.terrain_distance").format({
			"distance": distance_str,
		})

func _create_default_ui() -> void:
	var panel = _create_panel("Panel", Vector2(UI_MARGIN, UI_MARGIN), DEFAULT_PANEL_SIZE)
	add_child(panel)

	var vbox = _create_vbox("VBoxContainer", panel, PANEL_PADDING)

	round_label = _create_label("RoundLabel", vbox)
	round_label.text = LocalizationStrings.get_text("hud.round_label").format({"round": 1})

	turn_label = _create_label("TurnLabel", vbox)
	turn_label.text = LocalizationStrings.get_text("hud.turn_label").format({"side": LocalizationStrings.get_text("hud.turn_player")})

	unit_details_container = _create_vbox("UnitDetailsContainer", vbox, 0)
	active_unit_label = _create_label("ActiveUnitLabel", unit_details_container)

	unit_panel = _create_panel("UnitPanel", Vector2(UI_MARGIN, UI_MARGIN + DEFAULT_PANEL_SIZE.y + UI_MARGIN), UNIT_PANEL_SIZE)
	unit_panel.visible = false
	add_child(unit_panel)

	var unit_vbox = _create_vbox("VBoxContainer", unit_panel, PANEL_PADDING)
	unit_name_label = _create_label("NameLabel", unit_vbox)
	unit_stats_label = _create_label("StatsLabel", unit_vbox)
	unit_moves_label = _create_label("MovesLabel", unit_vbox)

	preview_panel = _create_panel("PreviewPanel", Vector2(UI_MARGIN, unit_panel.position.y + UNIT_PANEL_SIZE.y + UI_MARGIN), PREVIEW_PANEL_SIZE)
	preview_panel.visible = false
	add_child(preview_panel)

	preview_label = _create_label("Label", preview_panel)
	preview_label.position = Vector2(PANEL_PADDING, PANEL_PADDING)
	preview_label.size = PREVIEW_PANEL_SIZE - Vector2(PANEL_PADDING * 2, PANEL_PADDING * 2)

	# Actions panel (default/fallback UI)
	actions_panel = _create_panel("ActionsPanel", Vector2(UI_MARGIN + DEFAULT_PANEL_SIZE.x + UI_MARGIN, unit_panel.position.y), ACTIONS_PANEL_SIZE)
	actions_panel.visible = false
	add_child(actions_panel)

	var scroll := ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.position = Vector2(PANEL_PADDING, PANEL_PADDING)
	scroll.size = ACTIONS_PANEL_SIZE - Vector2(PANEL_PADDING * 2, PANEL_PADDING * 2)
	actions_panel.add_child(scroll)

	actions_container = VBoxContainer.new()
	actions_container.name = "VBoxContainer"
	scroll.add_child(actions_container)

	_actions_hint_label = _create_label("ActionsHintLabel", actions_panel)
	_actions_hint_label.text = LocalizationStrings.get_text("hud.actions_hint")
	_actions_hint_label.visible = false
	_actions_hint_label.modulate = Color(1, 1, 1, 0)
	_actions_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_actions_hint_label.add_theme_color_override("font_color", HINT_TEXT_COLOR)
	_actions_hint_label.position = Vector2(8, 8)

	_create_goal_panel()
	_create_terrain_panel()

func _create_terrain_panel() -> void:
	terrain_panel = _create_panel("TerrainPanel", Vector2(actions_panel.position.x, actions_panel.position.y + ACTIONS_PANEL_SIZE.y + UI_MARGIN), TERRAIN_PANEL_SIZE)
	terrain_panel.visible = false
	add_child(terrain_panel)

	var t_vbox = _create_vbox("VBoxContainer", terrain_panel, PANEL_PADDING)
	terrain_type_label = _create_label("TypeLabel", t_vbox)
	terrain_effect_label = _create_label("EffectLabel", t_vbox)
	terrain_distance_label = _create_label("DistanceLabel", t_vbox)

func _create_goal_panel() -> void:
	goal_panel = _create_panel("GoalPanel", Vector2(UI_MARGIN, preview_panel.position.y + PREVIEW_PANEL_SIZE.y + UI_MARGIN), GOAL_PANEL_SIZE)
	goal_panel.visible = false
	add_child(goal_panel)

	var goal_vbox = _create_vbox("VBoxContainer", goal_panel, PANEL_PADDING)
	goal_name_label = _create_label("NameLabel", goal_vbox)
	goal_type_label = _create_label("TypeLabel", goal_vbox)
	goal_progress_label = _create_label("ProgressLabel", goal_vbox)
	goal_required_amount_label = _create_label("RequiredAmountLabel", goal_vbox)

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
	var tween := label.create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.15)
	tween.tween_interval(1.2)
	tween.tween_property(label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(label.queue_free)

func _execute_action(action: Dictionary) -> bool:
	var action_type = action.get("type", "unknown")
	print_debug("Info._execute_action: starting execution for action=%s" % action_type)

	# Prefer InputController for supported commands to maintain Command Pattern
	if _input_controller:
		var result = null

		if action_type == "wait":
			print_debug("Info._execute_action: executing wait command")
			result = _input_controller._execute_command("wait")
		elif action_type == "attack":
			var target = action.get("target")
			if target:
				print_debug("Info._execute_action: executing attack command")
				var target_idx = _unit_manager.get_unit_index(target)
				var attr_idx = action.get("attribute_index", 0)
				result = _input_controller._execute_command("attack_unit", {
					"attacker_index": _current_unit_index,
					"target_index": target_idx,
					"attribute_index": attr_idx
				})
			else:
				print_debug("Info._execute_action: attack action missing target")
		elif action_type == "aid":
			var target = action.get("target")
			if target:
				print_debug("Info._execute_action: executing aid command")
				var target_idx = _unit_manager.get_unit_index(target)
				result = _input_controller._execute_command("aid_ally", {
					"unit_index": _current_unit_index,
					"target_index": target_idx
				})
			else:
				print_debug("Info._execute_action: aid action missing target")
		elif action_type == "goal":
			print_debug("Info._execute_action: executing goal command")
			result = _input_controller._execute_command("work_on_goal", {"unit_index": _current_unit_index})
		elif action_type == "loot":
			print_debug("Info._execute_action: executing loot command")
			var loot_coord = _current_unit.get_grid_location()
			result = _input_controller._execute_command("loot", {
				"looter_index": _current_unit_index,
				"loot_coord": loot_coord
			})

		if result is CommandResult:
			if result.is_failure():
				print_debug("Info._execute_action: Command execution failed: ", result.get_error_message())
				return false
			print_debug("Info._execute_action: Command execution successful")
			return true

		print_debug("Info._execute_action: no matching command found in InputController for action=%s" % action_type)
		# Add other commands here as they become available in InputController
	else:
		print_debug("Info._execute_action: InputController is missing")

	print_debug(
		"Info._execute_action: direct execution fallback for action=%s" % [action.get("type", "unknown")]
	)
	return false

func _await_tentative_resolution() -> void:
	if not is_instance_valid(self):
		return
	for _i in range(5):
		if _current_unit == null or not _current_unit.has_tentative_move():
			return
		await get_tree().process_frame

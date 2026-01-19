class_name Info
extends CanvasLayer

const UnitActionManager := preload("res://Gameplay/unit_action_manager.gd")
const CommandResult := preload("res://Gameplay/input_commands/command_result.gd")

signal action_executed(action_type: String)

var round_label: Label
var turn_label: Label
var unit_panel: Panel
var unit_name_label: Label
var unit_stats_label: Label
var unit_moves_label: Label
var unit_stuck_label: Label
var preview_panel: Panel
var preview_label: Label
var actions_panel: Panel
var actions_container: VBoxContainer

var _current_unit: Unit
var _current_unit_index: int = -1
var _terrain_map
var _unit_manager: UnitManager
var _turn_controller: TurnController
var _input_controller: Node  # Reference to InputController for command routing

func _ready() -> void:
	if has_node("Panel"):
		_setup_existing_ui()
	else:
		_create_default_ui()

func setup(unit_manager: UnitManager, turn_controller: TurnController, input_controller: Node = null) -> void:
	_unit_manager = unit_manager
	_turn_controller = turn_controller
	_input_controller = input_controller

func _setup_existing_ui() -> void:
	round_label = $Panel/VBoxContainer/RoundLabel
	turn_label = $Panel/VBoxContainer/TurnLabel
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

func update_round(round_num: int) -> void:
	if round_label:
		round_label.text = "Round: %d" % round_num

func update_turn(is_player: bool) -> void:
	if turn_label:
		turn_label.text = "Turn: %s" % ("Player" if is_player else "Enemy")
		turn_label.modulate = Color.GREEN if is_player else Color.RED

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
		unit_name_label.text = unit.unit_name if not unit.unit_name.is_empty() else "Unit"

	if unit_stats_label:
		unit_stats_label.text = "%s | WP: %d/%d" % [unit.get_faction_name(), unit.willpower, unit.max_willpower]

	if unit_moves_label:
		var moves = unit.get_remaining_movement_points()
		var max_moves = unit.get_max_movement_points()
		var can_act = unit.has_action_available()
		unit_moves_label.text = "Moves: %d/%d | Action: %s" % [moves, max_moves, "Yes" if can_act else "No"]

	# Update stuck status if label exists
	if unit_stuck_label and _terrain_map and _unit_manager:
		var is_stuck = UnitActionManager.is_unit_stuck(unit, _terrain_map, _unit_manager)
		unit_stuck_label.text = "Status: STUCK!" if is_stuck else "Status: OK"
		unit_stuck_label.modulate = Color.RED if is_stuck else Color.GREEN

func update_available_actions(unit: Unit, terrain_map, unit_manager: UnitManager, unit_index: int = -1) -> void:
	_current_unit = unit
	_current_unit_index = unit_index
	_terrain_map = terrain_map
	_unit_manager = unit_manager

	if not actions_container:
		return

	# Clear previous actions
	for child in actions_container.get_children():
		child.queue_free()

	if not unit:
		if actions_panel:
			actions_panel.visible = false
		return

	var available_actions = UnitActionManager.get_available_actions(unit, terrain_map, unit_manager)

	if available_actions.is_empty():
		if actions_panel:
			actions_panel.visible = false
		return

	if actions_panel:
		actions_panel.visible = true

	# Create buttons for each action
	for action in available_actions:
		var btn = Button.new()
		btn.text = action.label
		btn.custom_minimum_size = Vector2(160, 30)
		btn.disabled = not action.available
		btn.meta = action  # Store action data
		btn.pressed.connect(_on_action_button_pressed.bind(action))
		actions_container.add_child(btn)

func _on_action_button_pressed(action: Dictionary) -> void:
	if not _current_unit or _current_unit_index < 0:
		return

	# Route through command system instead of direct method calls
	if not _input_controller:
		# Fallback if InputController not provided (graceful degradation)
		_execute_action_directly(action)
		return

	var command_result: CommandResult
	match action.type:
		"attack":
			if action.has("targets") and not action.targets.is_empty():
				var target_idx = _unit_manager.get_unit_index(action.targets[0])
				if target_idx >= 0:
					var payload = {"attacker_index": _current_unit_index, "target_index": target_idx}
					command_result = _input_controller._execute_command("attack_unit", payload)
					if command_result.is_success():
						action_executed.emit("attack")
					else:
						_log_command_error("attack", command_result)
		"aid":
			if action.has("targets") and not action.targets.is_empty():
				var target_idx = _unit_manager.get_unit_index(action.targets[0])
				if target_idx >= 0:
					var payload = {"helper_index": _current_unit_index, "target_index": target_idx}
					command_result = _input_controller._execute_command("aid_ally", payload)
					if command_result.is_success():
						action_executed.emit("aid")
					else:
						_log_command_error("aid", command_result)
		"work_on_goal":
			if _current_unit._goal_manager:
				var goals = _current_unit._goal_manager.get_targets()
				for i in range(goals.size()):
					if goals[i] == _current_unit.get_grid_location():
						var goal_node = _current_unit._goal_manager.get_goal_node(i)
						if goal_node:
							var goal_idx = _unit_manager.get_goal_index(goal_node) if _unit_manager.has_method("get_goal_index") else i
							var payload = {"worker_index": _current_unit_index, "goal_index": goal_idx}
							command_result = _input_controller._execute_command("work_on_goal", payload)
							if command_result.is_success():
								action_executed.emit("work_on_goal")
							else:
								_log_command_error("work_on_goal", command_result)
						break
		"loot":
			if _current_unit._loot_manager and _current_unit._loot_manager.has_loot_at(_current_unit.global_position):
				var payload = {"looter_index": _current_unit_index}
				command_result = _input_controller._execute_command("loot", payload)
				if command_result.is_success():
					action_executed.emit("loot")
				else:
					_log_command_error("loot", command_result)
		"wait":
			# End turn - handled by game flow
			action_executed.emit("wait")

	# Refresh UI after action
	update_unit_details(_current_unit)

	if _current_unit and _turn_controller and _current_unit_index >= 0:
		var has_movement = _current_unit.has_move_available()
		var available_actions = UnitActionManager.get_available_actions(_current_unit, _terrain_map, _unit_manager)
		var has_actions = not available_actions.is_empty() and _current_unit.has_action_available()

		if not has_movement and not has_actions:
			# No more movement or actions, complete turn
			_turn_controller.complete_player_activation(_current_unit_index)
			print_debug("DBG action handler: turn completed (no movement, no actions remaining)")
		elif has_actions:
			# Still have actions, update the menu
			update_available_actions(_current_unit, _terrain_map, _unit_manager, _current_unit_index)
		else:
			# Clear the action menu if no actions left
			if actions_panel:
				actions_panel.visible = false

func show_combat_preview(attacker: Unit, defender: Unit) -> void:
	if not preview_panel:
		return
	preview_panel.visible = true
	if preview_label:
		var dist = attacker.global_position.distance_to(defender.global_position)
		var in_range = dist <= attacker.action_range
		var text = "Target: %s\n" % (defender.unit_name if not defender.unit_name.is_empty() else "Enemy")
		text += "Faction: %s\n" % defender.get_faction_name()
		text += "WP: %d/%d\n" % [defender.willpower, defender.max_willpower]
		text += "Range: %.1f / %.1f\n" % [dist, attacker.action_range]
		text += "Can Attack: %s" % ("Yes" if in_range else "No")
		preview_label.text = text

func hide_combat_preview() -> void:
	if preview_panel:
		preview_panel.visible = false

func _create_default_ui() -> void:
	var panel = Panel.new()
	panel.name = "Panel"
	panel.position = Vector2(20, 20)
	panel.size = Vector2(200, 80)
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.position = Vector2(10, 10)
	vbox.size = Vector2(180, 60)
	panel.add_child(vbox)

	round_label = Label.new()
	round_label.name = "RoundLabel"
	round_label.text = "Round: 1"
	vbox.add_child(round_label)

	turn_label = Label.new()
	turn_label.name = "TurnLabel"
	turn_label.text = "Turn: Player"
	vbox.add_child(turn_label)

	unit_panel = Panel.new()
	unit_panel.name = "UnitPanel"
	unit_panel.position = Vector2(20, 120)
	unit_panel.size = Vector2(200, 100)
	unit_panel.visible = false
	add_child(unit_panel)

	var unit_vbox = VBoxContainer.new()
	unit_vbox.name = "VBoxContainer"
	unit_vbox.position = Vector2(10, 10)
	unit_vbox.size = Vector2(180, 80)
	unit_panel.add_child(unit_vbox)

	unit_name_label = Label.new()
	unit_name_label.name = "NameLabel"
	unit_vbox.add_child(unit_name_label)

	unit_stats_label = Label.new()
	unit_stats_label.name = "StatsLabel"
	unit_vbox.add_child(unit_stats_label)

	unit_moves_label = Label.new()
	unit_moves_label.name = "MovesLabel"
	unit_vbox.add_child(unit_moves_label)

	preview_panel = Panel.new()
	preview_panel.name = "PreviewPanel"
	preview_panel.position = Vector2(20, 240)
	preview_panel.size = Vector2(200, 120)
	preview_panel.visible = false
	add_child(preview_panel)

	preview_label = Label.new()
	preview_label.name = "Label"
	preview_label.position = Vector2(10, 10)
	preview_label.size = Vector2(180, 100)
	preview_panel.add_child(preview_label)

## Execute action using fallback direct method calls (if InputController unavailable)
func _execute_action_directly(action: Dictionary) -> void:
	if not _current_unit:
		return

	match action.type:
		"attack":
			if action.has("targets") and not action.targets.is_empty():
				_current_unit.attack_unit(action.targets[0])
				_current_unit.consume_action()
				action_executed.emit("attack")
		"aid":
			if action.has("targets") and not action.targets.is_empty():
				_current_unit.aid_ally(action.targets[0])
				_current_unit.consume_action()
				action_executed.emit("aid")
		"work_on_goal":
			if _current_unit._goal_manager:
				var goals = _current_unit._goal_manager.get_targets()
				for i in range(goals.size()):
					if goals[i] == _current_unit.get_grid_location():
						var goal_node = _current_unit._goal_manager.get_goal_node(i)
						if goal_node:
							_current_unit.work_on_goal(goal_node)
							_current_unit.consume_action()
							action_executed.emit("work_on_goal")
						break
		"loot":
			if _current_unit._loot_manager and _current_unit._loot_manager.has_loot_at(_current_unit.global_position):
				_current_unit._loot_manager.try_pickup(_current_unit)
				_current_unit.consume_action()
				action_executed.emit("loot")


## Log command execution error for debugging
func _log_command_error(action_name: String, result) -> void:
	var error_msg = "Command failed for action '%s'" % action_name
	if result and result.has_method("get_description"):
		error_msg = "%s: %s" % [error_msg, result.get_description()]
	push_warning(error_msg)
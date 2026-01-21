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
var goal_panel: Panel
var goal_name_label: Label
var goal_type_label: Label
var goal_progress_label: Label
var goal_required_amount_label: Label
var terrain_panel: Panel
var terrain_type_label: Label
var terrain_effect_label: Label
var terrain_distance_label: Label

var _current_unit: Unit
var _current_unit_index: int = -1
var _terrain_map
var _unit_manager: UnitManager
var _turn_controller: TurnController
var _input_controller: Node # Reference to InputController for command routing
var _goal_manager: GoalManager

func _ready() -> void:
	if has_node("Panel"):
		_setup_existing_ui()
	else:
		_create_default_ui()

func setup(unit_manager: UnitManager, turn_controller: TurnController, input_controller: Node = null, goal_manager: GoalManager = null) -> void:
	_unit_manager = unit_manager
	_turn_controller = turn_controller
	_input_controller = input_controller
	_goal_manager = goal_manager

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
		btn.meta = action # Store action data
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


	# Handle generic interaction targets (Attack, Aid, Goal, Loot)
	var target: Target = null
	if action.has("target") and action.target is Target:
		target = action.target

	if target and (action.type == "attack" or action.type == "aid" or action.type == "work_on_goal" or action.type == "loot"):
		command_result = _input_controller._execute_command("interact", target)
		if command_result.is_success():
			action_executed.emit(action.type)
		else:
			_log_command_error(action.type, command_result)
	else:
		match action.type:
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
		goal_name_label.text = "Goal: %s" % goal_node.name if goal_node.name else "Goal"

	if goal_type_label and _goal_manager and goal_index != -1:
		var type_text = "Type: %s" % _goal_manager.get_required_type(goal_index)
		if _goal_manager.has_method("get_current_step_description"):
			var desc = _goal_manager.get_current_step_description(goal_index)
			if not desc.is_empty():
				type_text += "\n%s" % desc
		goal_type_label.text = type_text

	if goal_progress_label and _goal_manager and goal_index != -1:
		var player_progress = _goal_manager.get_progress(goal_index, Unit.Faction.PLAYER)
		var enemy_progress = _goal_manager.get_progress(goal_index, Unit.Faction.ENEMY)
		goal_progress_label.text = "P: %d / E: %d" % [player_progress, enemy_progress]

	if goal_required_amount_label and _goal_manager and goal_index != -1:
		goal_required_amount_label.text = "Required: %d" % _goal_manager.get_required_amount(goal_index)

func update_terrain_details(terrain: TerrainTile, distance_str: String = "") -> void:
	if terrain == null:
		if terrain_panel:
			terrain_panel.visible = false
		return

	if not terrain_panel:
		_create_terrain_panel()

	terrain_panel.visible = true

	if terrain_type_label:
		# Infer name from script path or class name if available, fallback to "Terrain"
		var type_name = "Terrain"
		var script_path = terrain.get_script().resource_path
		var file_name = script_path.get_file().get_basename()
		type_name = file_name.replace("_terrain", "").capitalize()
		terrain_type_label.text = "Type: %s" % type_name

	if terrain_effect_label:
		var effect_text = "Effects: "
		if not terrain.passable:
			effect_text += "Impassable"
		else:
			var cost = 1 + terrain.movement_penalty - terrain.movement_bonus
			effect_text += "Cost: %d" % cost
			if terrain.blocks_action_after_move:
				effect_text += ", Ends Turn"
			if not terrain.status_effect.is_empty():
				effect_text += ", %s" % terrain.status_effect
		terrain_effect_label.text = effect_text

	if terrain_distance_label:
		terrain_distance_label.text = "Dist: %s" % distance_str

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

	_create_goal_panel()
	_create_terrain_panel()

func _create_terrain_panel() -> void:
	terrain_panel = Panel.new()
	terrain_panel.name = "TerrainPanel"
	terrain_panel.position = Vector2(240, 380) # Position to the right
	terrain_panel.size = Vector2(200, 100)
	terrain_panel.visible = false
	add_child(terrain_panel)

	var t_vbox = VBoxContainer.new()
	t_vbox.name = "VBoxContainer"
	t_vbox.position = Vector2(10, 10)
	t_vbox.size = Vector2(180, 80)
	terrain_panel.add_child(t_vbox)

	terrain_type_label = Label.new()
	terrain_type_label.name = "TypeLabel"
	t_vbox.add_child(terrain_type_label)

	terrain_effect_label = Label.new()
	terrain_effect_label.name = "EffectLabel"
	t_vbox.add_child(terrain_effect_label)

	terrain_distance_label = Label.new()
	terrain_distance_label.name = "DistanceLabel"
	t_vbox.add_child(terrain_distance_label)

func _create_goal_panel() -> void:
	goal_panel = Panel.new()
	goal_panel.name = "GoalPanel"
	goal_panel.position = Vector2(20, 380) # Position below preview panel
	goal_panel.size = Vector2(200, 120)
	goal_panel.visible = false
	add_child(goal_panel)

	var goal_vbox = VBoxContainer.new()
	goal_vbox.name = "VBoxContainer"
	goal_vbox.position = Vector2(10, 10)
	goal_vbox.size = Vector2(180, 100)
	goal_panel.add_child(goal_vbox)

	goal_name_label = Label.new()
	goal_name_label.name = "NameLabel"
	goal_vbox.add_child(goal_name_label)

	goal_type_label = Label.new()
	goal_type_label.name = "TypeLabel"
	goal_vbox.add_child(goal_type_label)

	goal_progress_label = Label.new()
	goal_progress_label.name = "ProgressLabel"
	goal_vbox.add_child(goal_progress_label)

	goal_required_amount_label = Label.new()
	goal_required_amount_label.name = "RequiredAmountLabel"
	goal_vbox.add_child(goal_required_amount_label)


## Execute action using fallback direct method calls (if InputController unavailable)
func _execute_action_directly(action: Dictionary) -> void:
	if not _current_unit:
		return

	var target: Target = null
	if action.has("target") and action.target is Target:
		target = action.target

	if target and _current_unit.interact(target):
		action_executed.emit(action.type)
		return

	if action.type == "wait":
		action_executed.emit("wait")


## Log command execution error for debugging
func _log_command_error(action_name: String, result) -> void:
	var error_msg = "Command failed for action '%s'" % action_name
	if result and result.has_method("get_description"):
		error_msg = "%s: %s" % [error_msg, result.get_description()]
	push_warning(error_msg)
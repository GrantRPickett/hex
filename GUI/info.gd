class_name Info
extends CanvasLayer

var round_label: Label
var turn_label: Label
var unit_panel: Panel
var unit_name_label: Label
var unit_stats_label: Label
var unit_moves_label: Label
var preview_panel: Panel
var preview_label: Label

func _ready() -> void:
	if has_node("Panel"):
		_setup_existing_ui()
	else:
		_create_default_ui()

func _setup_existing_ui() -> void:
	round_label = $Panel/VBoxContainer/RoundLabel
	turn_label = $Panel/VBoxContainer/TurnLabel
	unit_panel = $UnitPanel
	unit_name_label = $UnitPanel/VBoxContainer/NameLabel
	unit_stats_label = $UnitPanel/VBoxContainer/StatsLabel
	unit_moves_label = $UnitPanel/VBoxContainer/MovesLabel
	preview_panel = $PreviewPanel
	if preview_panel:
		preview_label = $PreviewPanel/Label

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
		return

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

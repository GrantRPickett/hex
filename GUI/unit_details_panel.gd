class_name UnitDetailsPanel
extends ResizablePanel

const LocalizationStrings := preload("res://Resources/Localization/localization_strings.gd")

@onready var _vbox: VBoxContainer = %VBoxContainer
@onready var _name_label: Label = %NameLabel
@onready var _stats_label: Label = %StatsLabel
@onready var _moves_label: Label = %MovesLabel
@onready var _stuck_label: Label = %StuckLabel

func _init() -> void:
	name = "UnitDetailsPanel"

func _ready() -> void:
	pass

func update_details(unit: Unit, terrain_map, unit_manager: UnitManager) -> void:
	if unit == null:
		visible = false
		return

	visible = true

	if _name_label:
		_name_label.text = unit.unit_name if not unit.unit_name.is_empty() else LocalizationStrings.get_text("hud.unit_name_fallback")

	if _stats_label:
		_stats_label.text = LocalizationStrings.get_text("hud.unit_stats").format({
			"faction": unit.get_faction_name(),
			"current": unit.willpower,
			"max": unit.max_willpower,
		})

	if _moves_label:
		var moves = unit.get_remaining_movement_points()
		var max_moves = unit.get_max_movement_points()
		var can_act = unit.has_action_available()
		var action_text = LocalizationStrings.get_text("hud.generic_yes") if can_act else LocalizationStrings.get_text("hud.generic_no")
		_moves_label.text = LocalizationStrings.get_text("hud.movement_summary").format({
			"moves": moves,
			"max_moves": max_moves,
			"action": action_text,
		})

	if _stuck_label and terrain_map and unit_manager:
		var is_stuck = UnitActionManager.is_unit_stuck(unit, terrain_map, unit_manager)
		var status_text = LocalizationStrings.get_text("hud.status_stuck") if is_stuck else LocalizationStrings.get_text("hud.status_ok")
		_stuck_label.text = status_text
		_stuck_label.modulate = Color.RED if is_stuck else Color.GREEN
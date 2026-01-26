class_name RoundInfoPanel
extends ResizablePanel

const LocalizationStrings := preload("res://Resources/Localization/localization_strings.gd")

@onready var _round_label: Label = %RoundLabel
@onready var _turn_label: Label = %TurnLabel

func _init() -> void:
	name = "RoundInfoPanel"

func update_round(current_round: int) -> void:
	_round_label.text = LocalizationStrings.get_text("hud.round_label").format({
		"round": current_round,
	})

func update_turn(is_player_turn: bool) -> void:
	var side_text = LocalizationStrings.get_text("hud.turn_player") if is_player_turn else LocalizationStrings.get_text("hud.turn_enemy")
	_turn_label.text = LocalizationStrings.get_text("hud.turn_label").format({
		"side": side_text,
	})
	_turn_label.modulate = Color.GREEN if is_player_turn else Color.RED

func update_round(current_round: int) -> void:
	_round_label.text = LocalizationStrings.get_text("hud.round_label").format({
		"round": current_round,
	})

func update_turn(is_player_turn: bool) -> void:
	var side_text = LocalizationStrings.get_text("hud.turn_player") if is_player_turn else LocalizationStrings.get_text("hud.turn_enemy")
	_turn_label.text = LocalizationStrings.get_text("hud.turn_label").format({
		"side": side_text,
	})
	_turn_label.modulate = Color.GREEN if is_player_turn else Color.RED
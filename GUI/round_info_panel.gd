class_name RoundInfoPanel
extends CustomResizablePanel

const LocalizationStrings := preload("res://Resources/Localization/localization_strings.gd")

@onready var _round_label: Label = %RoundLabel
@onready var _turn_label: Label = %TurnLabel

func _init() -> void:
	name = "RoundInfoPanel"

var _pending_round = -1
var _pending_turn = -2 # -1 is a valid turn state internally sometimes, so use -2 for unset

func _ready() -> void:
	if _pending_round != -1:
		update_round(_pending_round)
		_pending_round = -1
	if _pending_turn != -2:
		update_turn(_pending_turn == 1)
		_pending_turn = -2

func update_round(current_round: int) -> void:
	if not is_node_ready():
		_pending_round = current_round
		return
	_round_label.text = LocalizationStrings.get_text("hud.round_label").format({
		"round": current_round,
	})

func update_turn(is_player_turn: bool) -> void:
	if not is_node_ready():
		_pending_turn = 1 if is_player_turn else 0
		return
	var side_text = LocalizationStrings.get_text("hud.turn_player") if is_player_turn else LocalizationStrings.get_text("hud.turn_enemy")
	_turn_label.text = LocalizationStrings.get_text("hud.turn_label").format({
		"side": side_text,
	})
	_turn_label.modulate = Color.GREEN if is_player_turn else Color.RED

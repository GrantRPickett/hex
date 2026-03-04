class_name RoundInfoPanel
extends CustomResizablePanel

const LocalizationStrings := preload(FilePaths.Resources.LOCALIZATION_STRINGS)

@onready var _round_label: Label = %RoundLabel
@onready var _turn_label: Label = %TurnLabel

func _init() -> void:
	name = "RoundInfoPanel"

var _pending_round = -1
var _pending_turn = -2 # -2 for unset

func _ready() -> void:
	if _pending_round != -1:
		update_round(_pending_round)
		_pending_round = -1
	if _pending_turn != -2:
		update_turn(_pending_turn)
		_pending_turn = -2

func update_round(current_round: int) -> void:
	if not is_node_ready():
		_pending_round = current_round
		return
	_round_label.text = LocalizationStrings.get_text("hud.round_label").format({
		"round": current_round,
	})

func update_turn(side: int) -> void:
	if not is_node_ready():
		_pending_turn = side
		return
		
	var side_text = ""
	var side_color = Color.WHITE
	
	match side:
		TurnSystem.Side.PLAYER:
			side_text = LocalizationStrings.get_text("hud.turn_player")
			side_color = Color.GREEN
		TurnSystem.Side.ENEMY:
			side_text = LocalizationStrings.get_text("hud.turn_enemy")
			side_color = Color.RED
		TurnSystem.Side.NEUTRAL:
			side_text = LocalizationStrings.get_text("hud.turn_neutral")
			side_color = Color.YELLOW
			
	_turn_label.text = LocalizationStrings.get_text("hud.turn_label").format({
		"side": side_text,
	})
	_turn_label.modulate = side_color

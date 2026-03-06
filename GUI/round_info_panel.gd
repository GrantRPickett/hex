class_name RoundInfoPanel
extends CustomResizablePanel

const LocalizationStrings := preload(FilePaths.Resources.LOCALIZATION_STRINGS)

@onready var _round_label: Label = %RoundLabel
@onready var _turn_label: Label = %TurnLabel
var _status_container: HBoxContainer
var _player_count_label: Label
var _enemy_count_label: Label
var _neutral_count_label: Label

func _init() -> void:
	name = "RoundInfoPanel"

var _pending_round = -1
var _pending_turn = -2 # -2 for unset

func _ready() -> void:
	var vbox = _turn_label.get_parent() if is_instance_valid(_turn_label) else null
	if vbox:
		_status_container = HBoxContainer.new()
		vbox.add_child(_status_container)

		_player_count_label = Label.new()
		_status_container.add_child(_player_count_label)
		_enemy_count_label = Label.new()
		_status_container.add_child(_enemy_count_label)
		_neutral_count_label = Label.new()
		_status_container.add_child(_neutral_count_label)

	if _pending_round != -1:
		update_round(_pending_round)
		_pending_round = -1
	if _pending_turn != -2:
		update_turn(_pending_turn)
		_pending_turn = -2

	# Initialize labels if they exist
	if _player_count_label:
		_player_count_label.modulate = Color.GREEN
	if _enemy_count_label:
		_enemy_count_label.modulate = Color.RED
	if _neutral_count_label:
		_neutral_count_label.modulate = Color.YELLOW


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

func update_turn_status(counts: Dictionary) -> void:
	if not is_node_ready():
		return

	if _player_count_label:
		_player_count_label.text = "%dP" % counts.get(TurnSystem.Side.PLAYER, 0)
	if _enemy_count_label:
		_enemy_count_label.text = "%dE" % counts.get(TurnSystem.Side.ENEMY, 0)
	if _neutral_count_label:
		_neutral_count_label.text = "%dN" % counts.get(TurnSystem.Side.NEUTRAL, 0)

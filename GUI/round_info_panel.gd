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
var _pending_counts = {}
var _turn_enabled := true

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
	if not _pending_counts.is_empty():
		update_turn_status(_pending_counts)
		_pending_counts = {}

	update_enabled(_turn_enabled)

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
	_round_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_ROUND_LABEL).format({
		"num": current_round,
	})

func update_turn(side: int) -> void:
	if not is_node_ready():
		_pending_turn = side
		return

	if not _turn_enabled:
		_pending_turn = side
		return

	var side_text = tr("hud.task.status_unknown")
	var side_color = Color.WHITE

	match side:
		TurnSystem.Side.PLAYER:
			side_text = LocalizationStrings.get_text(LocalizationStrings.HUD_TURN_PLAYER)
			side_color = Color.GREEN
		TurnSystem.Side.ENEMY:
			side_text = LocalizationStrings.get_text(LocalizationStrings.HUD_TURN_ENEMY)
			side_color = Color.RED
		TurnSystem.Side.NEUTRAL:
			side_text = LocalizationStrings.get_text(LocalizationStrings.HUD_TURN_NEUTRAL)
			side_color = Color.GOLD

	_turn_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_TURN_FORMAT).format({
		"name": side_text
	})
	_turn_label.modulate = side_color

func update_enabled(enabled: bool) -> void:
	_turn_enabled = enabled
	if not is_node_ready():
		return

	if not enabled:
		_turn_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_STATUS_BUSY)
		_turn_label.modulate = Color.GRAY
	else:
		if _pending_turn != -2:
			update_turn(_pending_turn)
			_pending_turn = -2
		else:
			# If no pending, we need to refresh from current state,
			# but panel doesn't store side. We'll trust next update_turn call.
			pass


func update_turn_status(counts: Dictionary) -> void:
	if not is_node_ready():
		_pending_counts = counts
		return

	if _player_count_label:
		var count = counts.get(TurnSystem.Side.PLAYER, 0)
		_player_count_label.text = "%dP" % count
		_player_count_label.visible = count > 0

	if _enemy_count_label:
		var count = counts.get(TurnSystem.Side.ENEMY, 0)
		_enemy_count_label.text = "%dE" % count
		_enemy_count_label.visible = count > 0

	if _neutral_count_label:
		var count = counts.get(TurnSystem.Side.NEUTRAL, 0)
		_neutral_count_label.text = "%dN" % count
		_neutral_count_label.visible = count > 0

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

var _pending_round: int = -1
var _pending_turn: int = -2 # -2 for unset
var _pending_counts: Dictionary = {}
var _turn_enabled := true

var _last_round: int = -1
var _last_side: int = -2
var _last_counts: Dictionary = {}

func _ready() -> void:
	LocaleService.locale_changed.connect(_on_locale_changed)
	
	if DisplaySettings:
		DisplaySettings.display_settings_changed.connect(_on_display_settings_changed)
	
	_update_layout()
	
	_status_container = %StatusContainer

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
	if not _player_count_label:
		_player_count_label = Label.new()
		_status_container.add_child(_player_count_label)
	if not _enemy_count_label:
		_enemy_count_label = Label.new()
		_status_container.add_child(_enemy_count_label)
	if not _neutral_count_label:
		_neutral_count_label = Label.new()
		_status_container.add_child(_neutral_count_label)

	_player_count_label.modulate = GameConstants.Colors.FACTION_PLAYER
	_enemy_count_label.modulate = GameConstants.Colors.FACTION_ENEMY
	_neutral_count_label.modulate = GameConstants.Colors.FACTION_NEUTRAL

func _on_locale_changed() -> void:
	if _last_round != -1:
		update_round(_last_round)
	if _last_side != -2:
		update_turn(_last_side)
	if not _last_counts.is_empty():
		update_turn_status(_last_counts)

func update_round(current_round: int) -> void:
	_last_round = current_round
	if not is_node_ready():
		_pending_round = current_round
		return
	_round_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_ROUND_LABEL).format({
		"num": current_round,
	})

func update_turn(side: int) -> void:
	_last_side = side
	if not is_node_ready():
		_pending_turn = side
		return

	if not _turn_enabled:
		_pending_turn = side
		return

	var side_text: String = tr("hud.task.status_unknown")
	var side_color = GameConstants.Colors.UI_WHITE

	match side:
		GameConstants.Side.PLAYER:
			side_text = LocalizationStrings.get_text(LocalizationStrings.HUD_TURN_PLAYER)
			side_color = GameConstants.Colors.FACTION_PLAYER
		GameConstants.Side.ENEMY:
			side_text = LocalizationStrings.get_text(LocalizationStrings.HUD_TURN_ENEMY)
			side_color = GameConstants.Colors.FACTION_ENEMY
		GameConstants.Side.NEUTRAL:
			side_text = LocalizationStrings.get_text(LocalizationStrings.HUD_TURN_NEUTRAL)
			side_color = GameConstants.Colors.FACTION_NEUTRAL_ALT

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
		_turn_label.modulate = GameConstants.Colors.UI_GRAY
	else:
		if _pending_turn != -2:
			update_turn(_pending_turn)
			_pending_turn = -2
		else:
			# If no pending, we need to refresh from current state,
			# but panel doesn't store side. We'll trust next update_turn call.
			pass


func update_turn_status(counts: Dictionary) -> void:
	_last_counts = counts
	if not is_node_ready():
		_pending_counts = counts
		return

	if _player_count_label:
		var count = counts.get(GameConstants.Side.PLAYER, 0)
		var short_label = LocalizationStrings.get_text(LocalizationStrings.HUD_FACTION_PLAYER_SHORT)
		_player_count_label.text = "%d%s" % [count, short_label]
		_player_count_label.visible = count > 0

	if _enemy_count_label:
		var count = counts.get(GameConstants.Side.ENEMY, 0)
		var short_label = LocalizationStrings.get_text(LocalizationStrings.HUD_FACTION_ENEMY_SHORT)
		_enemy_count_label.text = "%d%s" % [count, short_label]
		_enemy_count_label.visible = count > 0

	if _neutral_count_label:
		var count = counts.get(GameConstants.Side.NEUTRAL, 0)
		var short_label = LocalizationStrings.get_text(LocalizationStrings.HUD_FACTION_NEUTRAL_SHORT)
		_neutral_count_label.text = "%d%s" % [count, short_label]
		_neutral_count_label.visible = count > 0
func _on_display_settings_changed(_orientation: int, _resolution: Vector2i) -> void:
	_update_layout()

func _update_layout() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var is_portrait = viewport_size.y > viewport_size.x
	
	var font_size = 14 if is_portrait and viewport_size.x < 500 else 18
	
	if _round_label:
		_round_label.add_theme_font_size_override("font_size", font_size)
	if _turn_label:
		_turn_label.add_theme_font_size_override("font_size", font_size)
	
	if _status_container:
		_status_container.add_theme_constant_override("h_separation", 4 if is_portrait else 10)
		for label in [_player_count_label, _enemy_count_label, _neutral_count_label]:
			if label:
				label.add_theme_font_size_override("font_size", font_size - 2)

	# Ensure internal VBox is compact
	var vbox: = _turn_label.get_parent() if is_instance_valid(_turn_label) else null
	if vbox is VBoxContainer:
		vbox.add_theme_constant_override("separation", 2 if is_portrait else 4)

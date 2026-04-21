class_name MoralePanel
extends Control

const LocalizationStrings := preload(FilePaths.Resources.LOCALIZATION_STRINGS)
const MoraleServiceScript := preload("res://Gameplay/morale_service.gd")


signal morale_updated(player_willpower_ratio: float, enemy_willpower_ratio: float, neutral_willpower_ratio: float)
signal player_retreat_triggered
signal enemy_retreat_triggered
signal neutral_retreat_triggered

var _unit_manager: UnitManager
var _player_retreat_condition_met: bool = false
var _enemy_retreat_condition_met: bool = false
var _neutral_retreat_condition_met: bool = false
var _morale_service: Node

var _morale_advantage_bar: ProgressBar
var _player_ratio_label: Label
var _enemy_ratio_label: Label
var _neutral_ratio_label: Label
var _pending_data_change := false

func _ready() -> void:
	_ensure_controls_ready()
	LocaleService.locale_changed.connect(_on_locale_changed)
	if _player_ratio_label:
		_player_ratio_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_MORALE_PLAYER).format({"ratio": 0})
	if _enemy_ratio_label:
		_enemy_ratio_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_MORALE_ENEMY).format({"ratio": 0})
	if _neutral_ratio_label:
		_neutral_ratio_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_MORALE_NEUTRAL).format({"ratio": 0})

	if _morale_advantage_bar:
		_morale_advantage_bar.value = 0

	if _pending_data_change:
		_on_unit_data_changed()
		_pending_data_change = false

func _on_locale_changed() -> void:
	update_morale_display()

func setup(state: GameState, _config: GameSessionBuilder.Config) -> void:
	_unit_manager = state.unit_manager
	if not is_instance_valid(_unit_manager):
		GameLogger.warning(GameLogger.Category.UI, "MoralePanel: UnitManager is invalid during setup.")
		return

	if not _unit_manager.unit_removed.is_connected(_on_unit_data_changed):
		_unit_manager.unit_removed.connect(_on_unit_data_changed)
	if not _unit_manager.unit_spawn_requested.is_connected(_on_unit_data_changed):
		_unit_manager.unit_spawn_requested.connect(_on_unit_data_changed)

	for unit in _unit_manager.get_units():
		_connect_unit_signals(unit)

	_morale_service = MoraleServiceScript.new()
	_morale_service.setup(_unit_manager)

	reset_state()

func _connect_unit_signals(unit: Unit) -> void:
	if unit.has_signal("willpower_changed") and unit.willpower_changed.is_connected(_on_willpower_changed):
		unit.willpower_changed.disconnect(_on_willpower_changed)

	if unit.has_signal("willpower_changed"):
		unit.willpower_changed.connect(_on_willpower_changed)

func _on_unit_data_changed(_unit: Unit = null, _index: int = -1) -> void:
	if not is_node_ready():
		_pending_data_change = true
		return
	if _morale_service:
		_morale_service.recalculate_baselines()
	for u in _unit_manager.get_units():
		_connect_unit_signals(u)

	update_morale_display()

func _on_willpower_changed(_target: Target) -> void:
	update_morale_display()

func _ensure_controls_ready() -> void:
	if _player_ratio_label == null:
		_player_ratio_label = get_node_or_null("VBoxContainer/LabelsHBox/PlayerRatioLabel")
	if _enemy_ratio_label == null:
		_enemy_ratio_label = get_node_or_null("VBoxContainer/LabelsHBox/EnemyRatioLabel")
	if _neutral_ratio_label == null:
		_neutral_ratio_label = get_node_or_null("VBoxContainer/LabelsHBox/NeutralRatioLabel")
	if _morale_advantage_bar == null:
		_morale_advantage_bar = get_node_or_null("VBoxContainer/MoraleAdvantageBar")

func update_morale_display() -> void:
	if not _unit_manager:
		return

	var player_stats = _morale_service.get_willpower_stats(_unit_manager.get_player_units()) if _morale_service else {"current": 0, "max": 0}
	var enemy_stats = _morale_service.get_willpower_stats(_unit_manager.get_enemy_units()) if _morale_service else {"current": 0, "max": 0}
	var neutral_units := _unit_manager.get_neutral_units() if _unit_manager.has_method("get_neutral_units") else []
	var neutral_stats = _morale_service.get_willpower_stats(neutral_units) if _morale_service else {"current": 0, "max": 0}

	var player_max = _morale_service.get_initial_max_willpower(GameConstants.Faction.PLAYER) if _morale_service else 0
	var enemy_max = _morale_service.get_initial_max_willpower(GameConstants.Faction.ENEMY) if _morale_service else 0
	var neutral_max = _morale_service.get_initial_max_willpower(GameConstants.Faction.NEUTRAL) if _morale_service else 0

	# Use initial max willpower for stable ratios
	var player_ratio := _safe_ratio(player_stats.current, player_max)
	var enemy_ratio := _safe_ratio(enemy_stats.current, enemy_max)
	var neutral_ratio := _safe_ratio(neutral_stats.current, neutral_max)

	if is_visible_in_tree():
		_update_labels(player_ratio, enemy_ratio, neutral_ratio)
		_update_bars(player_ratio, player_max, enemy_ratio, enemy_max)

	morale_updated.emit(player_ratio, enemy_ratio, neutral_ratio)
	_check_all_retreats(player_stats.current, enemy_stats.current, neutral_stats.current)

func _safe_ratio(current: int, max_val: int) -> float:
	return float(current) / max_val if max_val > 0 else 0.0

func _update_labels(player_ratio: float, enemy_ratio: float, neutral_ratio: float) -> void:
	_ensure_controls_ready()
	var player_name = GameConstants.get_faction_name(GameConstants.Faction.PLAYER)
	var enemy_name = GameConstants.get_faction_name(GameConstants.Faction.ENEMY)
	var neutral_name = GameConstants.get_faction_name(GameConstants.Faction.NEUTRAL)

	if _player_ratio_label:
		var p_max = _morale_service.get_initial_max_willpower(GameConstants.Faction.PLAYER) if _morale_service else 0
		_player_ratio_label.text = tr("hud.morale_ratio_format").format({"faction": player_name, "ratio": int(player_ratio * 100)})
		_update_label_tooltip(_player_ratio_label, _unit_manager.get_player_units(), p_max)
	if _enemy_ratio_label:
		var e_max = _morale_service.get_initial_max_willpower(GameConstants.Faction.ENEMY) if _morale_service else 0
		_enemy_ratio_label.text = tr("hud.morale_ratio_format").format({"faction": enemy_name, "ratio": int(enemy_ratio * 100)})
		_update_label_tooltip(_enemy_ratio_label, _unit_manager.get_enemy_units(), e_max)
	if _neutral_ratio_label:
		var n_max = _morale_service.get_initial_max_willpower(GameConstants.Faction.NEUTRAL) if _morale_service else 0
		_neutral_ratio_label.text = tr("hud.morale_ratio_format").format({"faction": neutral_name, "ratio": int(neutral_ratio * 100)})
		var neutral_units := _unit_manager.get_neutral_units() if _unit_manager.has_method("get_neutral_units") else []
		_update_label_tooltip(_neutral_ratio_label, neutral_units, n_max)


func _update_label_tooltip(label: Label, units: Array, initial_max: int) -> void:
	var stats = _morale_service.get_willpower_stats(units) if _morale_service else {"current": 0, "max": 0}
	var threshold_pct: int = int(DifficultyService.get_retreat_threshold() * 100)
	var threshold_val: int = int(initial_max * (threshold_pct / 100.0))

	label.tooltip_text = tr("hud.morale_tooltip").format({
		"current": stats.current, "max": initial_max, "percent": threshold_pct, "threshold": threshold_val
	})


func _update_bars(player_ratio: float, player_max: int, enemy_ratio: float, enemy_max: int) -> void:
	if not _morale_advantage_bar:
		return
	var player_contribution = player_ratio * player_max
	var enemy_contribution = enemy_ratio * enemy_max
	var total = player_contribution + enemy_contribution
	var advantage_value := 0.0
	if total > 0:
		advantage_value = ((player_contribution - enemy_contribution) / total) * 100.0
	_morale_advantage_bar.value = advantage_value

func _check_all_retreats(_player_wp: int, _enemy_wp: int, _neutral_wp: int) -> void:
	if not _morale_service: return

	if not _player_retreat_condition_met and _morale_service.check_retreat_condition(GameConstants.Faction.PLAYER):
		_player_retreat_condition_met = true
		player_retreat_triggered.emit()
		_emit_retreat_event("Player", GameConstants.Faction.PLAYER)

	if not _enemy_retreat_condition_met and _morale_service.check_retreat_condition(GameConstants.Faction.ENEMY):
		_enemy_retreat_condition_met = true
		enemy_retreat_triggered.emit()
		_emit_retreat_event("Enemy", GameConstants.Faction.ENEMY)

	if not _neutral_retreat_condition_met and _morale_service.check_retreat_condition(GameConstants.Faction.NEUTRAL):
		_neutral_retreat_condition_met = true
		neutral_retreat_triggered.emit()
		_emit_retreat_event("Neutral", GameConstants.Faction.NEUTRAL)

func _emit_retreat_event(label: String, id: int) -> void:
	if get_node_or_null("/root/EventBus"):
		EventBus.faction_willpower_critical.emit(id)
	GameLogger.debug(GameLogger.Category.UI, "%s retreat triggered!" % label)


func faction_label_to_id(label: String) -> int:
	match label:
		"Player": return GameConstants.Faction.PLAYER
		"Enemy": return GameConstants.Faction.ENEMY
		"Neutral": return GameConstants.Faction.NEUTRAL
	return GameConstants.INVALID_INDEX


func reset_state(unit_manager: UnitManager = null) -> void:
	if unit_manager:
		_unit_manager = unit_manager
	_player_retreat_condition_met = false
	_enemy_retreat_condition_met = false
	_neutral_retreat_condition_met = false
	if _morale_service:
		_morale_service.reset_retreat_status()
	_ensure_controls_ready()
	if _player_ratio_label:
		_player_ratio_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_MORALE_PLAYER).format({"ratio": 0})
	if _enemy_ratio_label:
		_enemy_ratio_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_MORALE_ENEMY).format({"ratio": 0})
	if _neutral_ratio_label:
		_neutral_ratio_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_MORALE_NEUTRAL).format({"ratio": 0})

	if _morale_advantage_bar:
		_morale_advantage_bar.value = 0
	if _unit_manager:
		update_morale_display()

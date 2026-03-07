class_name MoralePanel
extends Control

const LocalizationStrings := preload(FilePaths.Resources.LOCALIZATION_STRINGS)


signal morale_updated(player_willpower_ratio: float, enemy_willpower_ratio: float, neutral_willpower_ratio: float)
signal player_retreat_triggered
signal enemy_retreat_triggered
signal neutral_retreat_triggered

var _unit_manager: UnitManager
var _initial_player_max_willpower: int = 0
var _initial_enemy_max_willpower: int = 0
var _initial_neutral_max_willpower: int = 0
var _player_retreat_condition_met: bool = false
var _enemy_retreat_condition_met: bool = false
var _neutral_retreat_condition_met: bool = false

var _morale_advantage_bar: ProgressBar
var _player_ratio_label: Label
var _enemy_ratio_label: Label
var _neutral_ratio_label: Label
var _pending_data_change := false

func _ready() -> void:
	_ensure_controls_ready()
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

func setup(state: GameState, _config: GameSessionBuilder.Config) -> void:
	_unit_manager = state.unit_manager
	if not _unit_manager.unit_removed.is_connected(_on_unit_data_changed):
		_unit_manager.unit_removed.connect(_on_unit_data_changed)
	if not _unit_manager.unit_spawn_requested.is_connected(_on_unit_data_changed):
		_unit_manager.unit_spawn_requested.connect(_on_unit_data_changed)

	for unit in _unit_manager.get_units():
		_connect_unit_signals(unit)

	reset_state()

func _connect_unit_signals(unit: Unit) -> void:
	if unit.has_signal("willpower_changed") and unit.willpower_changed.is_connected(_on_willpower_changed):
		unit.willpower_changed.disconnect(_on_willpower_changed)

	if unit.has_signal("willpower_changed"):
		unit.willpower_changed.connect(_on_willpower_changed)

func _on_unit_data_changed(_unit: Unit = null) -> void:
	if not is_node_ready():
		_pending_data_change = true
		return
	_recalculate_initial_max_willpower()
	for u in _unit_manager.get_units():
		_connect_unit_signals(u)

	update_morale_display()

func _on_willpower_changed(_unit: Unit) -> void:
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

	var player_stats = _get_willpower_stats(_unit_manager.get_player_units())
	var enemy_stats = _get_willpower_stats(_unit_manager.get_enemy_units())
	var neutral_units = _unit_manager.get_neutral_units() if _unit_manager.has_method("get_neutral_units") else []
	var neutral_stats = _get_willpower_stats(neutral_units)

	# Use initial max willpower for stable ratios
	var player_ratio := _safe_ratio(player_stats.current, _initial_player_max_willpower)
	var enemy_ratio := _safe_ratio(enemy_stats.current, _initial_enemy_max_willpower)
	var neutral_ratio := _safe_ratio(neutral_stats.current, _initial_neutral_max_willpower)

	if is_visible_in_tree():
		_update_labels(player_ratio, enemy_ratio, neutral_ratio)
		_update_bars(player_ratio, _initial_player_max_willpower, enemy_ratio, _initial_enemy_max_willpower)

	morale_updated.emit(player_ratio, enemy_ratio, neutral_ratio)
	_check_all_retreats(player_stats.current, enemy_stats.current, neutral_stats.current)

func _safe_ratio(current: int, max_val: int) -> float:
	return float(current) / max_val if max_val > 0 else 0.0

func _update_labels(player_ratio: float, enemy_ratio: float, neutral_ratio: float) -> void:
	_ensure_controls_ready()
	if _player_ratio_label:
		_player_ratio_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_MORALE_PLAYER).format({"ratio": int(player_ratio * 100)})
	if _enemy_ratio_label:
		_enemy_ratio_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_MORALE_ENEMY).format({"ratio": int(enemy_ratio * 100)})
	if _neutral_ratio_label:
		_neutral_ratio_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_MORALE_NEUTRAL).format({"ratio": int(neutral_ratio * 100)})


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

func _check_all_retreats(player_wp: int, enemy_wp: int, neutral_wp: int) -> void:
	_check_retreat_condition(player_wp, _initial_player_max_willpower, "_player_retreat_condition_met", player_retreat_triggered, "Player")
	_check_retreat_condition(enemy_wp, _initial_enemy_max_willpower, "_enemy_retreat_condition_met", enemy_retreat_triggered, "Enemy")
	_check_retreat_condition(neutral_wp, _initial_neutral_max_willpower, "_neutral_retreat_condition_met", neutral_retreat_triggered, "Neutral")


func _get_willpower_stats(units: Array) -> Dictionary:
	var current := 0
	var max_val := 0
	for unit in units:
		if is_instance_valid(unit):
			current += unit.willpower
			max_val += unit.max_willpower
	return {"current": current, "max": max_val}

func _check_retreat_condition(current_wp: int, initial_max_wp: int, condition_flag_name: String, trigger_signal: Signal, faction_label: String) -> void:
	if initial_max_wp <= 0:
		return

	var condition_met = get(condition_flag_name)
	if condition_met:
		return

	var retreat_threshold = initial_max_wp * 0.2
	if current_wp < retreat_threshold:
		set(condition_flag_name, true)
		trigger_signal.emit()
		print_debug("%s retreat triggered! Current WP: %d, Threshold: %f" % [faction_label, current_wp, retreat_threshold])

func _recalculate_initial_max_willpower() -> void:
	_initial_player_max_willpower = 0
	_initial_enemy_max_willpower = 0
	_initial_neutral_max_willpower = 0
	if _unit_manager == null:
		return
	for unit in _unit_manager.get_player_units():
		if is_instance_valid(unit):
			_initial_player_max_willpower += unit.max_willpower
	for unit in _unit_manager.get_enemy_units():
		if is_instance_valid(unit):
			_initial_enemy_max_willpower += unit.max_willpower
	if _unit_manager.has_method("get_neutral_units"):
		for unit in _unit_manager.get_neutral_units():
			if is_instance_valid(unit):
				_initial_neutral_max_willpower += unit.max_willpower

func reset_state(unit_manager: UnitManager = null) -> void:
	if unit_manager:
		_unit_manager = unit_manager
	_player_retreat_condition_met = false
	_enemy_retreat_condition_met = false
	_neutral_retreat_condition_met = false
	_recalculate_initial_max_willpower()
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

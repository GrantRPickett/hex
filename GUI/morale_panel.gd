class_name MoralePanel
extends Control

signal morale_updated(player_willpower_ratio: float, enemy_willpower_ratio: float)
signal player_retreat_triggered
signal enemy_retreat_triggered

var _unit_manager: UnitManager
var _initial_player_max_willpower: int = 0
var _initial_enemy_max_willpower: int = 0
var _player_retreat_condition_met: bool = false
var _enemy_retreat_condition_met: bool = false

var _morale_advantage_bar: ProgressBar
var _player_ratio_label: Label
var _enemy_ratio_label: Label

func _ready() -> void:
	_ensure_controls_ready()
	if _player_ratio_label:
		_player_ratio_label.text = "Player: 0%"
	if _enemy_ratio_label:
		_enemy_ratio_label.text = "Enemy: 0%"
	if _morale_advantage_bar:
		_morale_advantage_bar.value = 0 

func setup(unit_manager: UnitManager) -> void:
	_unit_manager = unit_manager
	_unit_manager.unit_removed.connect(_on_unit_data_changed)
	_unit_manager.unit_spawn_requested.connect(_on_unit_data_changed)

	for unit in _unit_manager.get_units():
		_connect_unit_signals(unit)

	reset_state()

func _connect_unit_signals(unit: Unit) -> void:
	if unit.has_signal("willpower_changed") and unit.willpower_changed.is_connected(_on_willpower_changed):
		unit.willpower_changed.disconnect(_on_willpower_changed)
	
	if unit.has_signal("willpower_changed"):
		unit.willpower_changed.connect(_on_willpower_changed)

func _on_unit_data_changed(unit: Unit = null) -> void:
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
	if _morale_advantage_bar == null:
		_morale_advantage_bar = get_node_or_null("VBoxContainer/MoraleAdvantageBar")

func update_morale_display() -> void:
	if not _unit_manager:
		return
	_ensure_controls_ready()
	if _player_ratio_label == null or _enemy_ratio_label == null or _morale_advantage_bar == null:
		return

	var player_units = _unit_manager.get_player_units()
	var enemy_units = _unit_manager.get_enemy_units()

	var total_player_willpower := 0
	var total_player_max_willpower := 0
	for unit in player_units:
		if is_instance_valid(unit):
			total_player_willpower += unit.willpower
			total_player_max_willpower += unit.max_willpower

	var total_enemy_willpower := 0
	var total_enemy_max_willpower := 0
	for unit in enemy_units:
		if is_instance_valid(unit):
			total_enemy_willpower += unit.willpower
			total_enemy_max_willpower += unit.max_willpower
	
	var player_ratio := 0.0
	if total_player_max_willpower > 0:
		player_ratio = float(total_player_willpower) / total_player_max_willpower

	var enemy_ratio := 0.0
	if total_enemy_max_willpower > 0:
		enemy_ratio = float(total_enemy_willpower) / total_enemy_max_willpower
	
	_player_ratio_label.text = "Player: %d%%" % int(player_ratio * 100)
	_enemy_ratio_label.text = "Enemy: %d%%" % int(enemy_ratio * 100)

	var total_current_willpower = total_player_willpower + total_enemy_willpower
	var total_max_willpower = total_player_max_willpower + total_enemy_max_willpower

	var advantage_value := 0.0
	if total_current_willpower > 0:
		var player_contribution = player_ratio * total_player_max_willpower
		var enemy_contribution = enemy_ratio * total_enemy_max_willpower
		
		if (player_contribution + enemy_contribution) > 0:
			advantage_value = ((player_contribution - enemy_contribution) / (player_contribution + enemy_contribution)) * 100.0
		else:
			advantage_value = 0.0

	_morale_advantage_bar.value = advantage_value
	
	morale_updated.emit(player_ratio, enemy_ratio)
	
	# Check for retreat conditions
	var retreat_threshold_player = _initial_player_max_willpower * 0.2
	if total_player_willpower < retreat_threshold_player and not _player_retreat_condition_met:
		_player_retreat_condition_met = true
		player_retreat_triggered.emit()
		print_debug("Player retreat triggered! Current WP: %d, Threshold: %f" % [total_player_willpower, retreat_threshold_player])

	var retreat_threshold_enemy = _initial_enemy_max_willpower * 0.2
	if total_enemy_willpower < retreat_threshold_enemy and not _enemy_retreat_condition_met:
		_enemy_retreat_condition_met = true
		enemy_retreat_triggered.emit()
		print_debug("Enemy retreat triggered! Current WP: %d, Threshold: %f" % [total_enemy_willpower, retreat_threshold_enemy])

func _recalculate_initial_max_willpower() -> void:
	_initial_player_max_willpower = 0
	_initial_enemy_max_willpower = 0
	if _unit_manager == null:
		return
	for unit in _unit_manager.get_player_units():
		if is_instance_valid(unit):
			_initial_player_max_willpower += unit.max_willpower
	for unit in _unit_manager.get_enemy_units():
		if is_instance_valid(unit):
			_initial_enemy_max_willpower += unit.max_willpower

func reset_state(unit_manager: UnitManager = null) -> void:
	if unit_manager:
		_unit_manager = unit_manager
	_player_retreat_condition_met = false
	_enemy_retreat_condition_met = false
	_recalculate_initial_max_willpower()
	_ensure_controls_ready()
	if _player_ratio_label:
		_player_ratio_label.text = "Player: 0%"
	if _enemy_ratio_label:
		_enemy_ratio_label.text = "Enemy: 0%"
	if _morale_advantage_bar:
		_morale_advantage_bar.value = 0
	if _unit_manager:
		update_morale_display()

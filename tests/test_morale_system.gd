extends GdUnitTestSuite


# Mock classes for MoralePanel testing
class MockUnit extends Node:
	signal willpower_changed(unit)
	var willpower: int
	var max_willpower: int
	var faction: int # Corresponds to Unit.Faction

	func _init(p_faction: int, p_willpower: int, p_max_willpower: int):
		faction = p_faction
		willpower = p_willpower
		max_willpower = p_max_willpower

	func set_willpower_test(value: int) -> void:
		if willpower != value:
			willpower = value
			willpower_changed.emit(self )

class MockUnitManager extends Node:
	signal unit_removed(unit)
	signal unit_spawn_requested(unit)
	var units: Array[MockUnit] = []
	var removed_units: Array[MockUnit] = []

	func _init(initial_units: Array[MockUnit] = []):
		units = initial_units

	func get_units_by_faction(faction: int) -> Array[MockUnit]:
		var result: Array[MockUnit] = []
		for u in units:
			if u.faction == faction:
				result.append(u)
		return result

	func get_player_units() -> Array[MockUnit]:
		return get_units_by_faction(Unit.Faction.PLAYER)

	func get_enemy_units() -> Array[MockUnit]:
		return get_units_by_faction(Unit.Faction.ENEMY)

	func get_neutral_units() -> Array[MockUnit]:
		return get_units_by_faction(Unit.Faction.NEUTRAL)

	func get_units() -> Array[MockUnit]:
		return units

	func remove_unit(unit) -> void:
		var index = units.find(unit)
		if index != -1:
			units.remove_at(index)
			removed_units.append(unit)
			unit_removed.emit(unit)

	func add_unit(unit) -> void:
		units.append(unit)
		unit_spawn_requested.emit(unit)

# Mocks for LevelManagerGameplay testing

class MockMoralePanel extends Node:
	signal player_retreat_triggered
	signal enemy_retreat_triggered
	signal neutral_retreat_triggered

	func _trigger_all_for_lint() -> void:
		player_retreat_triggered.emit()
		enemy_retreat_triggered.emit()
		neutral_retreat_triggered.emit()

class MockHud extends Node:
	var warning_messages: Array[String] = []

	func _init(p_morale_panel: Node):
		set_name("HUD")
		var margin := Node.new()
		margin.name = "HUDMarginContainer"
		var bottom := Node.new()
		bottom.name = "BottomCenterContainer"
		margin.add_child(bottom)
		p_morale_panel.name = "MoralePanel"
		bottom.add_child(p_morale_panel)
		add_child(margin)

	func show_warning_message(message: String) -> void:
		warning_messages.append(message)
		print_debug("MockHud: " + message) # For debugging tests

class MockGameState extends Node:
	var hud
	var unit_manager
	var combat_system = Node.new() # Dummy
	var location_controller = Node.new() # Dummy, for update_location_progress
	var hud_components = null

	func _init(p_hud, p_unit_manager):
		hud = p_hud
		unit_manager = p_unit_manager
		location_controller.add_child(Node.new()) # To prevent null access on location_controller.check_location_progress()
		location_controller.check_location_progress = func(): pass # Mock method
		location_controller.is_location_reached = func(): return false # Mock method

class MockGameplayCoordinator extends Node2D:
	var player_roster = Node.new()
	var enemy_roster = Node.new()
	var neutral_roster = Node.new()
	var gameplay_disabled := false

	func _disable_gameplay() -> void:
		gameplay_disabled = true

func _register(node):
	if node == null:
		return node
	return auto_free(node)

func _setup_morale_panel_nodes(morale_panel: Node) -> void:
	var vbox := VBoxContainer.new()
	vbox.name = "VBoxContainer"
	morale_panel.add_child(_register(vbox))

	var hbox := HBoxContainer.new()
	hbox.name = "HBoxContainer"
	vbox.add_child(_register(hbox))

	var p_ratio := Label.new()
	p_ratio.name = "PlayerRatioLabel"
	hbox.add_child(_register(p_ratio))

	var spacer := Control.new()
	hbox.add_child(_register(spacer))

	var n_ratio := Label.new()
	n_ratio.name = "NeutralRatioLabel"
	hbox.add_child(_register(n_ratio))

	var e_ratio := Label.new()
	e_ratio.name = "EnemyRatioLabel"
	hbox.add_child(_register(e_ratio))

	var adv_bar := ProgressBar.new()
	adv_bar.name = "MoraleAdvantageBar"
	vbox.add_child(_register(adv_bar))

func test_action_points_component_emits_willpower_changed_on_value_change() -> void:
	var component: ActionPointsComponent = ActionPointsComponent.new()
	component.set_max_willpower(10)
	component.set_willpower(5) # Initial set

	var signal_emitted := [false]
	component.willpower_changed.connect(func(): signal_emitted[0] = true)

	component.set_willpower(4) # Change value
	assert_bool(signal_emitted[0]).is_true()

	signal_emitted[0] = false
	component.set_willpower(4) # Set to same value, should not emit
	assert_bool(signal_emitted[0]).is_false()

	signal_emitted[0] = false
	component.set_willpower(100) # Clamped value change
	assert_bool(signal_emitted[0]).is_true()
	assert_int(component.get_willpower()).is_equal(10)

func test_unit_emits_willpower_changed_on_action_points_willpower_change() -> void:
	var unit_instance: Unit = _register(Unit.new())
	# Mock the _action_points component for the unit
	var action_points_component = ActionPointsComponent.new()
	unit_instance.res = action_points_component

	# Manually connect the unit's signal to the action points component's signal
	if action_points_component:
		if not action_points_component.willpower_changed.is_connected(unit_instance._on_action_points_willpower_changed):
			action_points_component.willpower_changed.connect(unit_instance._on_action_points_willpower_changed)

	unit_instance.max_willpower = 10 # Set initial max_willpower
	unit_instance.willpower = 5 # Initial willpower set via Unit's setter

	var unit_signal_emitted := [false]
	var emitted_unit: Array[Unit] = [null]
	unit_instance.willpower_changed.connect(func(unit):
		unit_signal_emitted[0] = true
		emitted_unit[0] = unit
	)

	unit_instance.willpower = 4 # Change willpower via Unit's setter
	assert_bool(unit_signal_emitted[0]).is_true()
	assert_that(emitted_unit[0]).is_equal(unit_instance)

	unit_signal_emitted[0] = false
	unit_instance.willpower = 4 # Set to same value, should not emit from Unit
	assert_bool(unit_signal_emitted[0]).is_false()

	unit_signal_emitted[0] = false
	unit_instance.willpower = 100 # Clamped value change
	assert_bool(unit_signal_emitted[0]).is_true()
	assert_int(unit_instance.willpower).is_equal(10)
	assert_that(emitted_unit[0]).is_equal(unit_instance)

func test_morale_panel_initial_state() -> void:
	# Mock units
	var player1 = MockUnit.new(Unit.Faction.PLAYER, 10, 10)
	var player2 = MockUnit.new(Unit.Faction.PLAYER, 5, 10)
	var enemy1 = MockUnit.new(Unit.Faction.ENEMY, 8, 10)

	var mock_unit_manager = MockUnitManager.new([player1, player2, enemy1])
	var morale_panel = _register(MoralePanel.new())
	_setup_morale_panel_nodes(morale_panel)

	morale_panel._ready() # Simulate _ready call for @onready to initialize

	var morale_updated_emitted := [false]
	var p_ratio := [0.0]
	var e_ratio := [0.0]
	morale_panel.morale_updated.connect(func(pr, er, nr):
		morale_updated_emitted[0] = true
		p_ratio[0] = pr
		e_ratio[0] = er
		assert_float(nr).is_zero()
	)

	var state := GameState.new({}, [])
	state.unit_manager = mock_unit_manager
	var config := GameSessionBuilder.Config.new()
	morale_panel.setup(state, config)

	await morale_panel.morale_updated # Wait for the signal
	assert_bool(morale_updated_emitted[0]).is_true()
	# Player: (10+5)/(10+10) = 15/20 = 0.75
	# Enemy: 8/10 = 0.8
	assert_float(p_ratio[0]).is_approximately(0.75)
	assert_float(e_ratio[0]).is_approximately(0.8)
	assert_str(morale_panel._player_ratio_label.text).is_equal("Player: 75%")
	assert_str(morale_panel._enemy_ratio_label.text).is_equal("Enemy: 80%")

	# Advantage value check: (P_current - E_current) / (P_current + E_current) * 100
	# (15 - 8) / (15 + 8) * 100 = 7 / 23 * 100 = 30.43
	assert_float(morale_panel._morale_advantage_bar.value).is_approximately_equal(30.43, 0.01)

func test_morale_panel_updates_on_willpower_change() -> void:
	var player1 = MockUnit.new(Unit.Faction.PLAYER, 10, 10)
	var enemy1 = MockUnit.new(Unit.Faction.ENEMY, 8, 10)
	var mock_unit_manager = MockUnitManager.new([player1, enemy1])
	var morale_panel = _register(MoralePanel.new())
	_setup_morale_panel_nodes(morale_panel)

	var state := GameState.new({}, [])
	state.unit_manager = mock_unit_manager
	var config := GameSessionBuilder.Config.new()
	morale_panel.setup(state, config)
	await morale_panel.morale_updated # Wait for initial update

	var morale_updated_emitted := [false]
	morale_panel.morale_updated.connect(func(_pr, _er, _nr): morale_updated_emitted[0] = true)

	player1.set_willpower_test(5) # Player willpower drops
	await morale_panel.morale_updated # Wait for update
	assert_bool(morale_updated_emitted[0]).is_true()
	assert_str(morale_panel._player_ratio_label.text).is_equal("Player: 50%")
	# (5-8)/(5+8)*100 = -3/13*100 = -23.0769
	assert_float(morale_panel._morale_advantage_bar.value).is_approximately_equal(-23.08, 0.01)

func test_morale_panel_player_retreat_trigger() -> void:
	var player1 = MockUnit.new(Unit.Faction.PLAYER, 10, 10)
	var enemy1 = MockUnit.new(Unit.Faction.ENEMY, 10, 10)
	var mock_unit_manager = MockUnitManager.new([player1, enemy1])
	var morale_panel = _register(MoralePanel.new())
	_setup_morale_panel_nodes(morale_panel)

	morale_panel._ready()
	var state := GameState.new({}, [])
	state.unit_manager = mock_unit_manager
	var config := GameSessionBuilder.Config.new()
	morale_panel.setup(state, config)
	await morale_panel.morale_updated # Wait for initial update

	var player_retreat_emitted := [false]
	morale_panel.player_retreat_triggered.connect(func(): player_retreat_emitted[0] = true)

	player1.set_willpower_test(1) # Player willpower 1/10 = 10% (below 20% of initial 10 max)
	await morale_panel.player_retreat_triggered
	assert_bool(player_retreat_emitted[0]).is_true()

	player_retreat_emitted[0] = false
	player1.set_willpower_test(0) # Change again, should not re-emit
	assert_bool(player_retreat_emitted[0]).is_false()

func test_morale_panel_enemy_retreat_trigger() -> void:
	var player1 = MockUnit.new(Unit.Faction.PLAYER, 10, 10)
	var enemy1 = MockUnit.new(Unit.Faction.ENEMY, 10, 10)
	var mock_unit_manager = MockUnitManager.new([player1, enemy1])
	var morale_panel = _register(MoralePanel.new())
	_setup_morale_panel_nodes(morale_panel)

	morale_panel._ready()
	var state := GameState.new({}, [])
	state.unit_manager = mock_unit_manager
	var config := GameSessionBuilder.Config.new()
	morale_panel.setup(state, config)
	await morale_panel.morale_updated # Wait for initial update

	var enemy_retreat_emitted := [false]
	morale_panel.enemy_retreat_triggered.connect(func(): enemy_retreat_emitted[0] = true)

	enemy1.set_willpower_test(1) # Enemy willpower 1/10 = 10% (below 20% of initial 10 max)
	await morale_panel.enemy_retreat_triggered
	assert_bool(enemy_retreat_emitted[0]).is_true()

	enemy_retreat_emitted[0] = false
	enemy1.set_willpower_test(0) # Change again, should not re-emit
	assert_bool(enemy_retreat_emitted[0]).is_false()

func test_morale_panel_neutral_ratio_and_signal() -> void:
	var player1 = MockUnit.new(Unit.Faction.PLAYER, 10, 10)
	var neutral1 = MockUnit.new(Unit.Faction.NEUTRAL, 6, 12)
	var mock_unit_manager = MockUnitManager.new([player1, neutral1])
	var morale_panel = _register(MoralePanel.new())
	_setup_morale_panel_nodes(morale_panel)

	morale_panel._ready()
	var state := GameState.new({}, [])
	state.unit_manager = mock_unit_manager
	var config := GameSessionBuilder.Config.new()
	morale_panel.setup(state, config)
	await morale_panel.morale_updated
	assert_str(morale_panel._neutral_ratio_label.text).is_equal("Neutral: 50%")

	var neutral_retreat_emitted := [false]
	morale_panel.neutral_retreat_triggered.connect(func(): neutral_retreat_emitted[0] = true)
	neutral1.set_willpower_test(1)
	await morale_panel.neutral_retreat_triggered
	assert_bool(neutral_retreat_emitted[0]).is_true()



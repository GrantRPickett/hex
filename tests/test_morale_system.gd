extends GdUnitTestSuite

# FORCE_IMPORT_TIMESTAMP: 2026-03-11 16:10:00

# Mock classes for MoralePanel testing
class MockUnit extends Unit:
	var willpower_test: int
	var max_willpower_test: int

	func _init(p_faction: int, p_willpower: int, p_max_willpower: int):
		set_name("MockUnit")
		faction = p_faction as Unit.Faction
		willpower = p_willpower
		max_willpower = p_max_willpower
		willpower_test = p_willpower
		max_willpower_test = p_max_willpower

	func set_willpower_test(value: int) -> void:
		if willpower != value:
			willpower = value
			willpower_changed.emit(self)

class MockUnitManager extends UnitManager:
	var units_list: Array[Unit] = []
	var removed_units_list: Array[Unit] = []

	func _init(initial_units: Array[Unit] = []):
		units_list = initial_units

	func get_units_by_faction(p_faction: int) -> Array[Unit]:
		var result: Array[Unit] = []
		for u in units_list:
			if u.faction == p_faction:
				result.append(u)
		return result

	func get_player_units() -> Array[Unit]:
		return get_units_by_faction(GameConstants.Faction.PLAYER)

	func get_enemy_units() -> Array[Unit]:
		return get_units_by_faction(GameConstants.Faction.ENEMY)

	func get_neutral_units() -> Array[Unit]:
		return get_units_by_faction(GameConstants.Faction.NEUTRAL)

	func get_units() -> Array[Unit]:
		return units_list

	func remove_unit(unit: Unit) -> void:
		var index: int = units_list.find(unit)
		if index != -1:
			units_list.remove_at(index)
			removed_units_list.append(unit)
			unit_removed.emit(unit)

	func add_unit(unit: Unit, _coord: Vector2i = Vector2i.ZERO, _player_controlled: bool = false) -> void:
		units_list.append(unit)
		unit_spawn_requested.emit(unit)

	func get_faction_max_willpower(p_faction: int, _include_debug := false) -> int:
		var total := 0
		for u in get_units_by_faction(p_faction):
			total += u.max_willpower
		return total

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

class MockGameState extends RefCounted:
	var hud: Node
	var unit_manager: UnitManager
	var combat_system: Node = Node.new()
	var location_controller: Node = Node.new()
	var hud_components = null
	var task_controller = null
	var level_resource = null

	func _init(p_hud: Node, p_unit_manager: UnitManager):
		hud = p_hud
		unit_manager = p_unit_manager

# --- Helper Methods ---

func _register(node: Node) -> Node:
	if node == null:
		return node
	return auto_free(node)

func _setup_morale_panel_nodes(morale_panel: Control) -> void:
	var vbox := VBoxContainer.new()
	vbox.name = "VBoxContainer"
	morale_panel.add_child(_register(vbox))

	var labels_hbox := HBoxContainer.new()
	labels_hbox.name = "LabelsHBox"
	vbox.add_child(_register(labels_hbox))

	var p_ratio := Label.new()
	p_ratio.name = "PlayerRatioLabel"
	labels_hbox.add_child(_register(p_ratio))

	var n_ratio := Label.new()
	n_ratio.name = "NeutralRatioLabel"
	labels_hbox.add_child(_register(n_ratio))

	var e_ratio := Label.new()
	e_ratio.name = "EnemyRatioLabel"
	labels_hbox.add_child(_register(e_ratio))

	var adv_bar := ProgressBar.new()
	adv_bar.name = "MoraleAdvantageBar"
	vbox.add_child(_register(adv_bar))

# --- Tests ---

func test_morale_panel_initial_state() -> void:
	var player1: MockUnit = MockUnit.new(GameConstants.Faction.PLAYER as int, 10, 10)
	var player2: MockUnit = MockUnit.new(GameConstants.Faction.PLAYER as int, 5, 10)
	var enemy1: MockUnit = MockUnit.new(GameConstants.Faction.ENEMY as int, 8, 10)

	var mock_unit_manager: MockUnitManager = MockUnitManager.new([player1, player2, enemy1])
	var morale_panel = _register(MoralePanel.new())
	_setup_morale_panel_nodes(morale_panel)

	morale_panel._ready()

	var state: GameState = auto_free(GameState.new({}, []))
	var config: GameSessionBuilder.Config = GameSessionBuilder.Config.new()
	morale_panel.setup(state, config)

	await morale_panel.morale_updated
	assert_str(morale_panel._player_ratio_label.text).is_equal("Player: 75%")
	assert_str(morale_panel._enemy_ratio_label.text).is_equal("Enemy: 80%")

func test_morale_panel_updates_on_willpower_change() -> void:
	var player1: MockUnit = MockUnit.new(GameConstants.Faction.PLAYER as int, 10, 10)
	var enemy1: MockUnit = MockUnit.new(GameConstants.Faction.ENEMY as int, 8, 10)
	var mock_unit_manager: MockUnitManager = MockUnitManager.new([player1, enemy1])
	var morale_panel = _register(MoralePanel.new())
	_setup_morale_panel_nodes(morale_panel)

	var state: GameState = auto_free(GameState.new({}, []))
	var config: GameSessionBuilder.Config = GameSessionBuilder.Config.new()
	morale_panel.setup(state, config)
	await morale_panel.morale_updated

	player1.set_willpower_test(5)
	await morale_panel.morale_updated
	assert_str(morale_panel._player_ratio_label.text).is_equal("Player: 50%")

func test_morale_panel_player_retreat_trigger() -> void:
	var player1: MockUnit = MockUnit.new(GameConstants.Faction.PLAYER as int, 10, 10)
	var enemy1: MockUnit = MockUnit.new(GameConstants.Faction.ENEMY as int, 10, 10)
	var mock_unit_manager: MockUnitManager = MockUnitManager.new([player1, enemy1])
	var morale_panel = _register(MoralePanel.new())
	_setup_morale_panel_nodes(morale_panel)

	morale_panel._ready()
	var state: GameState = auto_free(GameState.new({}, []))
	morale_panel.setup(state, GameSessionBuilder.Config.new())
	await morale_panel.morale_updated

	var player_retreat_emitted := [false]
	morale_panel.player_retreat_triggered.connect(func(): player_retreat_emitted[0] = true)

	player1.set_willpower_test(1)
	await morale_panel.player_retreat_triggered
	assert_bool(player_retreat_emitted[0]).is_true()

func test_morale_panel_enemy_retreat_trigger() -> void:
	var player1: MockUnit = MockUnit.new(GameConstants.Faction.PLAYER as int, 10, 10)
	var enemy1: MockUnit = MockUnit.new(GameConstants.Faction.ENEMY as int, 10, 10)
	var mock_unit_manager: MockUnitManager = MockUnitManager.new([player1, enemy1])
	var morale_panel = _register(MoralePanel.new())
	_setup_morale_panel_nodes(morale_panel)

	morale_panel._ready()
	var state: GameState = auto_free(GameState.new({}, []))
	morale_panel.setup(state, GameSessionBuilder.Config.new())
	await morale_panel.morale_updated

	var enemy_retreat_emitted := [false]
	morale_panel.enemy_retreat_triggered.connect(func(): enemy_retreat_emitted[0] = true)

	enemy1.set_willpower_test(1)
	await morale_panel.enemy_retreat_triggered
	assert_bool(enemy_retreat_emitted[0]).is_true()

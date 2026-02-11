extends GdUnitTestSuite

const ActionPointsComponent := preload("res://Gameplay/components/action_points_component.gd")
const Unit := preload("res://Gameplay/unit.gd")
const MoralePanel := preload("res://GUI/morale_panel.gd")
const UnitManager := preload("res://Gameplay/unit_manager.gd") # For Faction enum
const LevelManagerGameplay := preload("res://Gameplay/level_manager_gameplay.gd")

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
			willpower_changed.emit(self)

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

	func remove_unit(unit: MockUnit) -> void:
		var index = units.find(unit)
		if index != -1:
			units.remove_at(index)
			removed_units.append(unit)
			unit_removed.emit(unit)

	func add_unit(unit: MockUnit) -> void:
		units.append(unit)
		unit_spawn_requested.emit(unit)

# Mocks for LevelManagerGameplay testing

class MockMoralePanel extends Node:
	signal player_retreat_triggered
	signal enemy_retreat_triggered
	signal neutral_retreat_triggered
	var ready_state := true

	func is_node_ready() -> bool:
		return ready_state

	func get_node_or_null(path: String) -> Node:
		if path == "HUDMarginContainer/BottomCenterContainer/MoralePanel":
			return self
		return null

	func _init():
		set_name("MoralePanel")

class MockHud extends Node:
	var warning_messages: Array[String] = []
	var mock_morale_panel: MockMoralePanel

	func _init(p_morale_panel: MockMoralePanel):
		mock_morale_panel = p_morale_panel
		set_name("HUD")

	func show_warning_message(message: String) -> void:
		warning_messages.append(message)
		print_debug("MockHud: " + message) # For debugging tests

	func get_node_or_null(path: String) -> Node:
		if path == "HUDMarginContainer/BottomCenterContainer/MoralePanel":
			return mock_morale_panel
		return null

	func add_child(node: Node) -> void:
		# Mocking the add_child for warnings
		pass

class MockGameState extends Node:
	var hud: MockHud
	var unit_manager: MockUnitManager
	var combat_system = Node.new() # Dummy
	var location_controller = Node.new() # Dummy, for update_location_progress
	var hud_components = null

	func _init(p_hud: MockHud, p_unit_manager: MockUnitManager):
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
	var _grid_width := 10
	var _grid_height := 10

	func _disable_gameplay() -> void:
		gameplay_disabled = true

func _register(node):
	if node == null:
		return node
	return auto_free(node)

func test_action_points_component_emits_willpower_changed_on_value_change() -> void:
	var component: ActionPointsComponent = ActionPointsComponent.new()
	component.set_max_willpower(10)
	component.set_willpower(5) # Initial set

	var signal_emitted := false
	component.willpower_changed.connect(func(): signal_emitted = true)

	component.set_willpower(4) # Change value
	assert_bool(signal_emitted).is_true()

	signal_emitted = false
	component.set_willpower(4) # Set to same value, should not emit
	assert_bool(signal_emitted).is_false()

	signal_emitted = false
	component.set_willpower(100) # Clamped value change
	assert_bool(signal_emitted).is_true()
	assert_int(component.get_willpower()).is_equal(10)

func test_unit_emits_willpower_changed_on_action_points_willpower_change() -> void:
	var unit_instance: Unit = _register(Unit.new())
	# Mock the _action_points component for the unit
	var action_points_component = ActionPointsComponent.new()
	unit_instance._action_points = action_points_component

	# Manually connect the unit's signal to the action points component's signal
	if action_points_component:
		if not action_points_component.willpower_changed.is_connected(unit_instance._on_action_points_willpower_changed):
			action_points_component.willpower_changed.connect(unit_instance._on_action_points_willpower_changed)

	unit_instance.max_willpower = 10 # Set initial max_willpower
	unit_instance.willpower = 5 # Initial willpower set via Unit's setter

	var unit_signal_emitted := false
	var emitted_unit: Unit = null
	unit_instance.willpower_changed.connect(func(unit):
		unit_signal_emitted = true
		emitted_unit = unit
	)

	unit_instance.willpower = 4 # Change willpower via Unit's setter
	assert_bool(unit_signal_emitted).is_true()
	assert_that(emitted_unit).is_equal(unit_instance)

	unit_signal_emitted = false
	unit_instance.willpower = 4 # Set to same value, should not emit from Unit
	assert_bool(unit_signal_emitted).is_false()

	unit_signal_emitted = false
	unit_instance.willpower = 100 # Clamped value change
	assert_bool(unit_signal_emitted).is_true()
	assert_int(unit_instance.willpower).is_equal(10)
	assert_that(emitted_unit).is_equal(unit_instance)

func test_morale_panel_initial_state() -> void:
	# Mock units
	var player1 = MockUnit.new(Unit.Faction.PLAYER, 10, 10)
	var player2 = MockUnit.new(Unit.Faction.PLAYER, 5, 10)
	var enemy1 = MockUnit.new(Unit.Faction.ENEMY, 8, 10)

	var mock_unit_manager = MockUnitManager.new([player1, player2, enemy1])
	var morale_panel: MoralePanel = _register(MoralePanel.new())
	morale_panel.add_child(_register(VBoxContainer.new())) # Mock structure for @onready
	morale_panel.get_node("VBoxContainer").add_child(_register(HBoxContainer.new()))
	morale_panel.get_node("VBoxContainer/HBoxContainer").add_child(_register(Label.new()) as Label).name = "PlayerRatioLabel"
	morale_panel.get_node("VBoxContainer/HBoxContainer").add_child(_register(Control.new())) # Spacer
	morale_panel.get_node("VBoxContainer/HBoxContainer").add_child(_register(Label.new()) as Label).name = "NeutralRatioLabel"
	morale_panel.get_node("VBoxContainer/HBoxContainer").add_child(_register(Label.new()) as Label).name = "EnemyRatioLabel"
	morale_panel.get_node("VBoxContainer").add_child(_register(ProgressBar.new()) as ProgressBar).name = "MoraleAdvantageBar"

	morale_panel._ready() # Simulate _ready call for @onready to initialize

	var morale_updated_emitted := false
	var p_ratio := 0.0
	var e_ratio := 0.0
	morale_panel.morale_updated.connect(func(pr, er, nr):
		morale_updated_emitted = true
		p_ratio = pr
		e_ratio = er
		assert_float(nr).is_zero()
	)

	morale_panel.setup(mock_unit_manager)

	await yield (morale_panel, "morale_updated") # Wait for the signal
	assert_bool(morale_updated_emitted).is_true()
	# Player: (10+5)/(10+10) = 15/20 = 0.75
	# Enemy: 8/10 = 0.8
	assert_float(p_ratio).is_approximately(0.75)
	assert_float(e_ratio).is_approximately(0.8)
	assert_str(morale_panel._player_ratio_label.text).is_equal("Player: 75%")
	assert_str(morale_panel._enemy_ratio_label.text).is_equal("Enemy: 80%")

	# Advantage value check: (P_current - E_current) / (P_current + E_current) * 100
	# (15 - 8) / (15 + 8) * 100 = 7 / 23 * 100 = 30.43
	assert_float(morale_panel._morale_advantage_bar.value).is_approximately_equal(30.43, 0.01)

func test_morale_panel_updates_on_willpower_change() -> void:
	var player1 = MockUnit.new(Unit.Faction.PLAYER, 10, 10)
	var enemy1 = MockUnit.new(Unit.Faction.ENEMY, 8, 10)
	var mock_unit_manager = MockUnitManager.new([player1, enemy1])
	var morale_panel: MoralePanel = _register(MoralePanel.new())
	morale_panel.add_child(_register(VBoxContainer.new())) # Mock structure for @onready
	morale_panel.get_node("VBoxContainer").add_child(_register(HBoxContainer.new()))
	morale_panel.get_node("VBoxContainer/HBoxContainer").add_child(_register(Label.new()) as Label).name = "PlayerRatioLabel"
	morale_panel.get_node("VBoxContainer/HBoxContainer").add_child(_register(Control.new())) # Spacer
	morale_panel.get_node("VBoxContainer/HBoxContainer").add_child(_register(Label.new()) as Label).name = "NeutralRatioLabel"
	morale_panel.get_node("VBoxContainer/HBoxContainer").add_child(_register(Label.new()) as Label).name = "EnemyRatioLabel"
	morale_panel.get_node("VBoxContainer").add_child(_register(ProgressBar.new()) as ProgressBar).name = "MoraleAdvantageBar"

	morale_panel._ready()
	morale_panel.setup(mock_unit_manager)
	await yield (morale_panel, "morale_updated") # Wait for initial update

	var morale_updated_emitted := false
	morale_panel.morale_updated.connect(func(_pr, _er, _nr): morale_updated_emitted = true)

	player1.set_willpower_test(5) # Player willpower drops
	await yield (morale_panel, "morale_updated") # Wait for update
	assert_bool(morale_updated_emitted).is_true()
	assert_str(morale_panel._player_ratio_label.text).is_equal("Player: 50%")
	# (5-8)/(5+8)*100 = -3/13*100 = -23.0769
	assert_float(morale_panel._morale_advantage_bar.value).is_approximately_equal(-23.08, 0.01)

func test_morale_panel_player_retreat_trigger() -> void:
	var player1 = MockUnit.new(Unit.Faction.PLAYER, 10, 10)
	var enemy1 = MockUnit.new(Unit.Faction.ENEMY, 10, 10)
	var mock_unit_manager = MockUnitManager.new([player1, enemy1])
	var morale_panel: MoralePanel = _register(MoralePanel.new())
	morale_panel.add_child(_register(VBoxContainer.new())) # Mock structure for @onready
	morale_panel.get_node("VBoxContainer").add_child(_register(HBoxContainer.new()))
	morale_panel.get_node("VBoxContainer/HBoxContainer").add_child(_register(Label.new()) as Label).name = "PlayerRatioLabel"
	morale_panel.get_node("VBoxContainer/HBoxContainer").add_child(_register(Control.new())) # Spacer
	morale_panel.get_node("VBoxContainer/HBoxContainer").add_child(_register(Label.new()) as Label).name = "NeutralRatioLabel"
	morale_panel.get_node("VBoxContainer/HBoxContainer").add_child(_register(Label.new()) as Label).name = "EnemyRatioLabel"
	morale_panel.get_node("VBoxContainer").add_child(_register(ProgressBar.new()) as ProgressBar).name = "MoraleAdvantageBar"

	morale_panel._ready()
	morale_panel.setup(mock_unit_manager)
	await yield (morale_panel, "morale_updated") # Wait for initial update

	var player_retreat_emitted := false
	morale_panel.player_retreat_triggered.connect(func(): player_retreat_emitted = true)

	player1.set_willpower_test(1) # Player willpower 1/10 = 10% (below 20% of initial 10 max)
	await yield (morale_panel, "player_retreat_triggered")
	assert_bool(player_retreat_emitted).is_true()

	player_retreat_emitted = false
	player1.set_willpower_test(0) # Change again, should not re-emit
	assert_bool(player_retreat_emitted).is_false()

func test_morale_panel_enemy_retreat_trigger() -> void:
	var player1 = MockUnit.new(Unit.Faction.PLAYER, 10, 10)
	var enemy1 = MockUnit.new(Unit.Faction.ENEMY, 10, 10)
	var mock_unit_manager = MockUnitManager.new([player1, enemy1])
	var morale_panel: MoralePanel = _register(MoralePanel.new())
	morale_panel.add_child(_register(VBoxContainer.new())) # Mock structure for @onready
	morale_panel.get_node("VBoxContainer").add_child(_register(HBoxContainer.new()))
	morale_panel.get_node("VBoxContainer/HBoxContainer").add_child(_register(Label.new()) as Label).name = "PlayerRatioLabel"
	morale_panel.get_node("VBoxContainer/HBoxContainer").add_child(_register(Control.new())) # Spacer
	morale_panel.get_node("VBoxContainer/HBoxContainer").add_child(_register(Label.new()) as Label).name = "NeutralRatioLabel"
	morale_panel.get_node("VBoxContainer/HBoxContainer").add_child(_register(Label.new()) as Label).name = "EnemyRatioLabel"
	morale_panel.get_node("VBoxContainer").add_child(_register(ProgressBar.new()) as ProgressBar).name = "MoraleAdvantageBar"

	morale_panel._ready()
	morale_panel.setup(mock_unit_manager)
	await yield (morale_panel, "morale_updated") # Wait for initial update

	var enemy_retreat_emitted := false
	morale_panel.enemy_retreat_triggered.connect(func(): enemy_retreat_emitted = true)

	enemy1.set_willpower_test(1) # Enemy willpower 1/10 = 10% (below 20% of initial 10 max)
	await yield (morale_panel, "enemy_retreat_triggered")
	assert_bool(enemy_retreat_emitted).is_true()

	enemy_retreat_emitted = false
	enemy1.set_willpower_test(0) # Change again, should not re-emit
	assert_bool(enemy_retreat_emitted).is_false()

func test_morale_panel_neutral_ratio_and_signal() -> void:
	var player1 = MockUnit.new(Unit.Faction.PLAYER, 10, 10)
	var neutral1 = MockUnit.new(Unit.Faction.NEUTRAL, 6, 12)
	var mock_unit_manager = MockUnitManager.new([player1, neutral1])
	var morale_panel: MoralePanel = _register(MoralePanel.new())
	morale_panel.add_child(_register(VBoxContainer.new()))
	morale_panel.get_node("VBoxContainer").add_child(_register(HBoxContainer.new()))
	morale_panel.get_node("VBoxContainer/HBoxContainer").add_child(_register(Label.new()) as Label).name = "PlayerRatioLabel"
	morale_panel.get_node("VBoxContainer/HBoxContainer").add_child(_register(Control.new()))
	morale_panel.get_node("VBoxContainer/HBoxContainer").add_child(_register(Label.new()) as Label).name = "NeutralRatioLabel"
	morale_panel.get_node("VBoxContainer/HBoxContainer").add_child(_register(Label.new()) as Label).name = "EnemyRatioLabel"
	morale_panel.get_node("VBoxContainer").add_child(_register(ProgressBar.new()) as ProgressBar).name = "MoraleAdvantageBar"

	morale_panel._ready()
	morale_panel.setup(mock_unit_manager)
	await yield (morale_panel, "morale_updated")
	assert_str(morale_panel._neutral_ratio_label.text).is_equal("Neutral: 50%")

	var neutral_retreat_emitted := false
	morale_panel.neutral_retreat_triggered.connect(func(): neutral_retreat_emitted = true)
	neutral1.set_willpower_test(1)
	await yield (morale_panel, "neutral_retreat_triggered")
	assert_bool(neutral_retreat_emitted).is_true()

func test_level_manager_gameplay_handles_player_retreat() -> void:
	var mock_morale_panel = MockMoralePanel.new()
	var mock_hud = MockHud.new(mock_morale_panel)
	var mock_unit_manager = MockUnitManager.new()
	var mock_game_state = MockGameState.new(mock_hud, mock_unit_manager)
	var mock_coordinator = _register(MockGameplayCoordinator.new())
	var level_resource = Resource.new() # Dummy resource

	var level_manager_gameplay = LevelManagerGameplay.new(mock_game_state, mock_coordinator, null)
	level_manager_gameplay.set_level_resource(level_resource)

	# Mock the set_level_and_rebuild to ensure it is not called
	var set_level_and_rebuild_called := false
	level_manager_gameplay.set_level_and_rebuild = func(_level_res):
		set_level_and_rebuild_called = true
	level_manager_gameplay._defeat_return_delay = 0.0
	var quit_called := false
	level_manager_gameplay.quit_to_level_select.connect(func(): quit_called = true)

	# Call apply_level_if_available to establish signal connections
	await level_manager_gameplay.apply_level_if_available()

	assert_bool(mock_morale_panel.player_retreat_triggered.is_connected(level_manager_gameplay._on_player_retreat_triggered)).is_true()
	assert_bool(mock_morale_panel.neutral_retreat_triggered.is_connected(level_manager_gameplay._on_neutral_retreat_triggered)).is_true()
	assert_bool(mock_morale_panel.enemy_retreat_triggered.is_connected(level_manager_gameplay._on_enemy_retreat_triggered)).is_true()
	assert_bool(mock_morale_panel.player_retreat_triggered.is_connected(level_manager_gameplay._on_player_retreat_triggered)).is_true()

	# Trigger player retreat
	mock_morale_panel.player_retreat_triggered.emit()

	await get_tree().process_frame

	assert_bool(mock_coordinator.gameplay_disabled).is_true()
	assert_int(mock_hud.warning_messages.size()).is_equal(1)
	assert_str(mock_hud.warning_messages[0]).is_equal("GAME OVER! Morale Broken!")
	assert_bool(set_level_and_rebuild_called).is_false()
	assert_bool(quit_called).is_true()


func test_level_manager_gameplay_handles_enemy_retreat() -> void:
	var enemy1 = MockUnit.new(Unit.Faction.ENEMY, 5, 10)
	var enemy2 = MockUnit.new(Unit.Faction.ENEMY, 8, 10)
	var mock_unit_manager = MockUnitManager.new([enemy1, enemy2])

	var mock_morale_panel = MockMoralePanel.new()
	var mock_hud = MockHud.new(mock_morale_panel)
	var mock_game_state = MockGameState.new(mock_hud, mock_unit_manager)
	var mock_coordinator = _register(MockGameplayCoordinator.new())
	var level_resource = Resource.new() # Dummy resource

	var level_manager_gameplay = LevelManagerGameplay.new(mock_game_state, mock_coordinator, null)
	level_manager_gameplay.set_level_resource(level_resource)

	# Mock update_location_progress
	var update_location_progress_called := false
	level_manager_gameplay.update_location_progress = func():
		update_location_progress_called = true

	# Call apply_level_if_available to establish signal connections
	await level_manager_gameplay.apply_level_if_available()

	assert_bool(mock_morale_panel.enemy_retreat_triggered.is_connected(level_manager_gameplay._on_enemy_retreat_triggered)).is_true()

	# Trigger enemy retreat
	mock_morale_panel.enemy_retreat_triggered.emit()

	await get_tree().create_timer(0.1).timeout # Give time for signals/awaits

	assert_int(mock_hud.warning_messages.size()).is_equal(1)
	assert_str(mock_hud.warning_messages[0]).is_equal("Enemy morale broken! Victory!")
	assert_int(mock_unit_manager.removed_units.size()).is_equal(2)
	assert_bool(mock_unit_manager.removed_units.has(enemy1)).is_true()
	assert_bool(mock_unit_manager.removed_units.has(enemy2)).is_true()
	assert_bool(update_location_progress_called).is_true()

func test_level_manager_gameplay_handles_neutral_retreat() -> void:
	var neutral1 = MockUnit.new(Unit.Faction.NEUTRAL, 5, 10)
	var neutral2 = MockUnit.new(Unit.Faction.NEUTRAL, 7, 10)
	var mock_unit_manager = MockUnitManager.new([neutral1, neutral2])
	var mock_morale_panel = MockMoralePanel.new()
	var mock_hud = MockHud.new(mock_morale_panel)
	var mock_game_state = MockGameState.new(mock_hud, mock_unit_manager)
	var mock_coordinator = _register(MockGameplayCoordinator.new())
	var level_resource = Resource.new()

	var level_manager_gameplay = LevelManagerGameplay.new(mock_game_state, mock_coordinator, null)
	level_manager_gameplay.set_level_resource(level_resource)
	var update_location_progress_called := false
	level_manager_gameplay.update_location_progress = func():
		update_location_progress_called = true

	await level_manager_gameplay.apply_level_if_available()
	mock_morale_panel.neutral_retreat_triggered.emit()
	await get_tree().create_timer(0.1).timeout
	assert_int(mock_hud.warning_messages.size()).is_equal(1)
	assert_str(mock_hud.warning_messages[0]).is_equal("Neutral forces withdraw!")
	assert_int(mock_unit_manager.removed_units.size()).is_equal(2)
	assert_bool(mock_unit_manager.removed_units.has(neutral1)).is_true()
	assert_bool(mock_unit_manager.removed_units.has(neutral2)).is_true()
	assert_bool(update_location_progress_called).is_true()


func test_level_manager_gameplay_handles_location_failure_signal() -> void:
	var mock_morale_panel = MockMoralePanel.new()
	var mock_hud = MockHud.new(mock_morale_panel)
	var mock_unit_manager = MockUnitManager.new()
	var mock_game_state = MockGameState.new(mock_hud, mock_unit_manager)
	var mock_coordinator = _register(MockGameplayCoordinator.new())
	var level_manager_gameplay = LevelManagerGameplay.new(mock_game_state, mock_coordinator, null)
	level_manager_gameplay._defeat_return_delay = 0.0
	var quit_called := false
	level_manager_gameplay.quit_to_level_select.connect(func(): quit_called = true)
	await level_manager_gameplay.apply_level_if_available()
	await level_manager_gameplay.on_location_failed()
	assert_bool(mock_coordinator.gameplay_disabled).is_true()
	assert_str(mock_hud.warning_messages.back()).is_equal("Enemy secured the objectives! Retreat!")
	assert_bool(quit_called).is_true()

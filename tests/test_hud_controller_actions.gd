extends GdUnitTestSuite

const HUDController := preload("res://Gameplay/hud_controller.gd")
const TerrainMap := preload("res://Gameplay/terrain_map.gd")
const UnitManager := preload("res://Gameplay/unit_manager.gd")
const Unit := preload("res://Gameplay/unit.gd")
const HUDComponentFactory := preload("res://Gameplay/hud_component_factory.gd")
const GoalManager := preload("res://Gameplay/goal_manager.gd")
const CombatSystem := preload("res://Gameplay/combat_system.gd")
const CombatPreviewPanel := preload("res://GUI/combat_preview_panel.gd")

class FakeUnit extends Unit:
	func _ready() -> void:
		pass

class StubGoalManager extends GoalManager:
	var entries: Array[Dictionary] = []

	func set_entries(data: Array[Dictionary]) -> void:
		entries = data

	func get_goal_count() -> int:
		return entries.size()

	func get_progress(index: int, faction: int) -> int:
		return entries[index].get(faction, 0)

	func get_required_amount(index: int, faction: int = Unit.Faction.PLAYER) -> int:
		return entries[index].get("max", 0)

	func get_required_type(index: int, faction: int = Unit.Faction.PLAYER) -> String:
		return entries[index].get("type", "")

class StubCombatPreviewPanel extends CombatPreviewPanel:
	var last_forecast: Dictionary = {}
	func show_preview(_attacker, _defender) -> void:
		last_forecast = {}
	func show_forecast(_attacker, _defender, forecast: Dictionary) -> void:
		last_forecast = forecast
	func hide_preview() -> void:
		last_forecast = {}

class StubCombatSystem extends CombatSystem:
	var forecasts: Dictionary = {}
	func get_combat_forecast(_attacker, _defender, pair_idx: int) -> Dictionary:
		return forecasts.get(pair_idx, {})

class StubHoverUnitManager extends UnitManager:
	var selected_index := -1
	var units := {}
	var coord_lookup := {}
	var player_controlled := {}
	func get_selected_index() -> int:
		return selected_index
	func get_unit(index: int):
		return units.get(index)
	func index_of_unit_at(cell: Vector2i) -> int:
		return coord_lookup.get(cell, -1)
	func is_player_controlled(index: int) -> bool:
		return player_controlled.get(index, false)

class FakeUnitManager extends UnitManager:
	var _selected_unit: Unit
	var _selected_idx := -1

	func set_selected(unit: Unit, index: int = 0) -> void:
		_selected_unit = unit
		_selected_idx = index

	func get_selected_index() -> int:
		return _selected_idx

	func get_unit(index: int) -> Unit:
		if index == _selected_idx:
			return _selected_unit
		return null

func test_on_hud_action_executed_reemits_actions_updated() -> void:
	var controller: HUDController = auto_free(HUDController.new())
	get_tree().root.add_child(controller)
	var manager: FakeUnitManager = auto_free(FakeUnitManager.new())
	var unit: FakeUnit = auto_free(FakeUnit.new())
	manager.set_selected(unit)
	controller._unit_manager = manager
	controller._terrain_map = TerrainMap.new()
	controller._pending_combat_target = unit
	var emissions: Array = []
	controller.actions_updated.connect(func(u, terrain, mgr): emissions.append({
		"unit": u,
		"terrain": terrain,
		"manager": mgr
	}))
	controller._on_hud_action_executed("attack")
	assert_int(emissions.size()).is_equal(1)
	assert_object(emissions[0].unit).is_equal(unit)
	assert_object(emissions[0].manager).is_equal(manager)
	assert_bool(controller._pending_combat_target == null).is_true()

func test_on_hud_action_executed_ignores_attack_menu_request() -> void:
	var controller: HUDController = auto_free(HUDController.new())
	get_tree().root.add_child(controller)
	var manager: FakeUnitManager = auto_free(FakeUnitManager.new())
	var unit: FakeUnit = auto_free(FakeUnit.new())
	manager.set_selected(unit)
	controller._unit_manager = manager
	controller._terrain_map = TerrainMap.new()
	controller._pending_combat_target = unit
	var emission_count := 0
	controller.actions_updated.connect(func(_u, _terrain, _mgr): emission_count += 1)
	controller._on_hud_action_executed("open_attack_menu")
	assert_int(emission_count).is_equal(0)
	assert_object(controller._pending_combat_target).is_equal(unit)

func test_goal_manager_signal_updates_progress() -> void:
	var controller: HUDController = auto_free(HUDController.new())
	get_tree().root.add_child(controller)
	var goal_manager: StubGoalManager = auto_free(StubGoalManager.new())
	goal_manager.set_entries([{
		Unit.Faction.PLAYER: 2,
		Unit.Faction.ENEMY: 0,
		Unit.Faction.NEUTRAL: 1,
		"max": 5,
		"type": "grit"
	}])
	var config := HUDController.Config.new()
	config.goal_manager = goal_manager
	controller.setup(config)
	var emissions: Array = []
	controller.goals_updated.connect(func(data): emissions.append(data))
	goal_manager.goal_updated.emit(0)
	assert_int(emissions.size()).is_equal(1)
	var payload: Array = emissions[0]
	assert_int(payload.size()).is_equal(1)
	var entry: Dictionary = payload[0]
	assert_int(entry.get("player_progress", -1)).is_equal(2)
	assert_str(entry.get("type", "")).is_equal("grit")

func test_goal_completion_refreshes_goal_progress() -> void:
	var controller: HUDController = auto_free(HUDController.new())
	get_tree().root.add_child(controller)
	var goal_manager: StubGoalManager = auto_free(StubGoalManager.new())
	goal_manager.set_entries([{
		Unit.Faction.PLAYER: 1,
		Unit.Faction.ENEMY: 0,
		Unit.Faction.NEUTRAL: 0,
		"max": 3,
		"type": "lore"
	}])
	var config := HUDController.Config.new()
	config.goal_manager = goal_manager
	controller.setup(config)
	var emissions: Array = []
	controller.goals_updated.connect(func(data): emissions.append(data))
	goal_manager.entries[0][Unit.Faction.PLAYER] = 3
	goal_manager.goal_completed.emit(0, Unit.Faction.PLAYER)
	assert_int(emissions.size()).is_equal(1)
	var payload: Array = emissions[0]
	var entry: Dictionary = payload[0]
	assert_int(entry.get("player_progress", -1)).is_equal(3)

func test_combat_preview_state_emits_best_forecast() -> void:
	var controller: HUDController = auto_free(HUDController.new())
	get_tree().root.add_child(controller)
	var components := HUDComponentFactory.Components.new()
	var preview := StubCombatPreviewPanel.new()
	components.combat_preview = preview
	controller._components = components
	var manager := StubHoverUnitManager.new()
	var attacker: Unit = auto_free(Unit.new())
	attacker.unit_name = "Hero"
	attacker.faction = Unit.Faction.PLAYER
	var defender: Unit = auto_free(Unit.new())
	defender.unit_name = "Enemy"
	defender.faction = Unit.Faction.ENEMY
	manager.selected_index = 0
	manager.units[0] = attacker
	manager.units[1] = defender
	manager.coord_lookup[Vector2i(3, 3)] = 1
	manager.player_controlled[0] = true
	controller._unit_manager = manager
	var combat_system := StubCombatSystem.new()
	combat_system.forecasts = {
		0: {"damage_to_target": 1, "counter_damage_to_self": 0},
		1: {"damage_to_target": 5, "counter_damage_to_self": 2},
		2: {"damage_to_target": 3, "counter_damage_to_self": 1}
	}
	controller._combat_system = combat_system
	var state := HUDController.CombatPreviewState.new()
	state.update(controller, Vector2i(3, 3))
	assert_dict(preview.last_forecast).is_not_empty()
	assert_int(preview.last_forecast.get("damage_to_target", 0)).is_equal(5)

extends GdUnitTestSuite

const _HUDController := preload("res://GUI/HUD/hud_controller.gd")
const _HUDComponentFactory := preload("res://GUI/HUD/hud_component_factory.gd")
const TerrainMapClass := preload("res://Gameplay/map/terrain_map.gd")
const UnitManagerClass := preload("res://Gameplay/targets/unit_manager.gd")
const UnitClass := preload("res://Gameplay/targets/unit.gd")
const TaskManagerClass := preload("res://Gameplay/narrative/task/task_manager.gd")
const Stubs := preload("res://tests/fixtures/test_stubs.gd")
const ObjectiveClass := preload("res://Gameplay/narrative/task/objective.gd")

func test_on_hud_action_executed_reemits_actions_updated() -> void:
	var controller: _HUDController = auto_free(_HUDController.new())
	get_tree().root.add_child(controller)
	var manager: Stubs.FakeUnitManager = auto_free(Stubs.FakeUnitManager.new())
	var unit: Stubs.FakeUnit = auto_free(Stubs.FakeUnit.new())
	manager.add_unit(unit, Vector2i(1, 1), true)
	manager.select_index(0)

	controller._unit_manager = manager
	controller._terrain_map = auto_free(TerrainMapClass.new())
	controller._pending_combat_target = unit

	var emissions: Array = []
	controller.actions_updated.connect(func(u, terrain, mgr, combat, enabled): emissions.append({
		"unit": u,
		"terrain": terrain,
		"manager": mgr,
		"combat": combat,
		"enabled": enabled
	}))

	controller._on_hud_action_executed(GameConstants.ActionType.ATTACK)
	assert_int(emissions.size()).is_equal(1)
	assert_object(emissions[0].unit).is_equal(unit)
	assert_object(emissions[0].manager).is_equal(manager)
	assert_bool(controller._pending_combat_target == null).is_true()

func test_on_hud_action_executed_ignores_attack_menu_request() -> void:
	var controller: _HUDController = auto_free(_HUDController.new())
	get_tree().root.add_child(controller)
	var manager: Stubs.FakeUnitManager = auto_free(Stubs.FakeUnitManager.new())
	var unit: Stubs.FakeUnit = auto_free(Stubs.FakeUnit.new())
	manager.add_unit(unit, Vector2i(1, 1), true)
	manager.select_index(0)

	controller._unit_manager = manager
	controller._terrain_map = auto_free(TerrainMapClass.new())
	controller._pending_combat_target = unit

	var emission_count := [0]
	controller.actions_updated.connect(func(_u, _terrain, _mgr, _combat, _enabled): emission_count[0] += 1)

	controller._on_hud_action_executed(GameConstants.ActionType.OPEN_ATTACK_MENU)
	assert_int(emission_count[0]).is_equal(0)
	assert_object(controller._pending_combat_target).is_equal(unit)

func test_task_manager_signal_updates_progress() -> void:
	var controller: _HUDController = auto_free(_HUDController.new())
	get_tree().root.add_child(controller)
	var task_manager: Stubs.FakeTaskManager = auto_free(Stubs.FakeTaskManager.new())
	var components = auto_free(_HUDComponentFactory.Components.new())
	var state = auto_free(GameState.new({}))
	state.task_manager = task_manager

	controller._task_manager = task_manager
	var connector = auto_free(load("res://GUI/HUD/hud_signal_connector.gd").new())
	connector.setup(controller, state, components)
	connector._connect_task_manager_signals()

	var task_emissions: Array = []
	var loc_emissions: Array = []
	if controller.has_signal("tasks_updated"):
		controller.connect("tasks_updated", func(data): task_emissions.append(data))
	if controller.has_signal("locations_updated"):
		controller.connect("locations_updated", func(data): loc_emissions.append(data))

	# The HUD controller connects to objective_updated
	var objective: ObjectiveClass = auto_free(ObjectiveClass.new())
	objective.is_active = true
	task_manager.objective_updated.emit(objective)

	if controller.has_signal("tasks_updated"):
		assert_int(task_emissions.size()).is_equal(1)

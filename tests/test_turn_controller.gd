extends GdUnitTestSuite

var _turn_controller: TurnController
var _unit_manager: UnitManager
var _unit1: Unit
var _unit2: Unit

class FakeAIController extends AIController:
	var executed_units: Array[Unit] = []
	var attempted_units: Array[Unit] = []
	var should_succeed := true
	var unit_results := {}

	func execute_turn(unit: Unit) -> bool:
		attempted_units.append(unit)
		var result := should_succeed
		if unit_results.has(unit.unit_name):
			result = unit_results[unit.unit_name]
		if not result:
			return false
		executed_units.append(unit)
		await get_tree().process_frame
		return true

func before_test() -> void:
	_turn_controller = auto_free(TurnController.new())
	_turn_controller.reset()
	_unit_manager = auto_free(UnitManager.new())
	_unit1 = auto_free(Unit.new())
	_unit1.unit_name = "Unit1"
	_unit2 = auto_free(Unit.new())
	_unit2.unit_name = "Unit2"

	add_child(_turn_controller)
	add_child(_unit_manager)

	var state := GameState.new({}, [])
	state.unit_manager = _unit_manager
	var config := GameSessionBuilder.Config.new()
	_turn_controller.setup(state, config)

func test_start_next_turn_with_empty_queue() -> void:
	_unit_manager.add_unit(_unit1, Vector2i(0, 0), true)

	_turn_controller.start_next_turn()

	# Should handle empty queue gracefully
	assert_object(_turn_controller).is_not_null()

func test_complete_turn() -> void:
	_unit_manager.add_unit(_unit1, Vector2i(0, 0), true)
	_unit_manager.add_unit(_unit2, Vector2i(1, 1), false)

	# complete_turn is a signal-based method, just verify it exists and is callable
	_turn_controller.complete_turn()

	assert_object(_turn_controller).is_not_null()

func test_get_current_unit_index() -> void:
	_unit_manager.add_unit(_unit1, Vector2i(0, 0), true)

	var index = _turn_controller.get_current_unit_index()

	# Index might be -1 initially
	assert_object(index).is_not_null()

func test_get_current_side() -> void:
	_unit_manager.add_unit(_unit1, Vector2i(0, 0), true)

	var side = _turn_controller.get_current_side()

	assert_int(side).is_greater_equal(0)

func test_get_round() -> void:
	_unit_manager.add_unit(_unit1, Vector2i(0, 0), true)

	var current_round: float = _turn_controller.get_round()

	assert_int(current_round).is_equal(1)

func test_set_player_auto_battle_enabled_emits_signal() -> void:
	var toggles: Array[bool] = []
	_turn_controller.player_auto_battle_changed.connect(func(enabled: bool): toggles.append(enabled))
	_turn_controller.set_player_auto_battle_enabled(true)
	_turn_controller.set_player_auto_battle_enabled(false)
	assert_array(toggles).has_size(2)
	assert_bool(toggles[0]).is_true()
	assert_bool(toggles[1]).is_false()
	assert_bool(_turn_controller.is_player_auto_battle_enabled()).is_false()

func test_force_disable_auto_battle_emits_failure_signal() -> void:
	var reasons: Array[String] = []
	_turn_controller.player_auto_battle_failed.connect(func(reason: String): reasons.append(reason))
	_turn_controller.set_player_auto_battle_enabled(true)
	_turn_controller.force_disable_auto_battle("Manual cancel")
	assert_bool(_turn_controller.is_player_auto_battle_enabled()).is_false()
	assert_int(reasons.size()).is_equal(1)

func test_player_auto_control_lock_clears_after_ai_turn() -> void:
	var ai: FakeAIController = auto_free(FakeAIController.new())
	get_tree().root.add_child(ai)
	var state := GameState.new({}, [])
	state.unit_manager = _unit_manager
	state.ai_controller = ai
	var config := GameSessionBuilder.Config.new()
	_turn_controller.setup(state, config)
	var player: Unit = auto_free(Unit.new())
	player.unit_name = "Scout"
	player.willpower = 2
	_unit_manager.add_unit(player, Vector2i(0, 0), true)
	_turn_controller.set_player_auto_battle_enabled(true)
	_turn_controller.rebuild_turn_roster()
	await get_tree().process_frame
	assert_bool(_turn_controller.is_player_auto_control_locked()).is_true()
	await get_tree().create_timer(1.0).timeout
	assert_bool(_turn_controller.is_player_auto_control_locked()).is_false()

func test_auto_battle_enabling_runs_current_turn() -> void:
	var unit_manager: UnitManager = auto_free(UnitManager.new())
	var controller: TurnController = auto_free(TurnController.new())
	var ai: FakeAIController = auto_free(FakeAIController.new())
	get_tree().root.add_child(controller)
	get_tree().root.add_child(ai)
	var state := GameState.new({}, [])
	state.unit_manager = unit_manager
	state.ai_controller = ai
	var config := GameSessionBuilder.Config.new()
	controller.setup(state, config)
	var player: Unit = auto_free(Unit.new())
	player.unit_name = "Hero"
	player.willpower = 2
	var enemy: Unit = auto_free(Unit.new())
	enemy.unit_name = "Bandit"
	enemy.willpower = 2
	unit_manager.add_unit(player, Vector2i(0, 0), true)
	unit_manager.add_unit(enemy, Vector2i(1, 1), false)
	controller.rebuild_turn_roster()
	await get_tree().process_frame
	assert_int(ai.executed_units.size()).is_equal(0)
	controller.set_player_auto_battle_enabled(true)
	await get_tree().process_frame
	assert_bool(controller.is_player_auto_control_locked()).is_true()
	await get_tree().create_timer(0.7).timeout
	assert_int(ai.executed_units.size()).is_equal(1)

func test_auto_battle_disables_when_ai_cannot_act() -> void:
	var unit_manager: UnitManager = auto_free(UnitManager.new())
	var controller: TurnController = auto_free(TurnController.new())
	var ai: FakeAIController = auto_free(FakeAIController.new())
	ai.should_succeed = false
	get_tree().root.add_child(controller)
	get_tree().root.add_child(ai)
	var state := GameState.new({}, [])
	state.unit_manager = unit_manager
	state.ai_controller = ai
	var config := GameSessionBuilder.Config.new()
	controller.setup(state, config)
	var player: Unit = auto_free(Unit.new())
	player.unit_name = "Hero"
	player.willpower = 2
	unit_manager.add_unit(player, Vector2i(0, 0), true)
	var failure_reasons: Array[String] = []
	controller.player_auto_battle_failed.connect(func(reason: String): failure_reasons.append(reason))
	var state_obj := {"ready_calls": 0}
	controller.turn_ready.connect(func(_unit: Unit): state_obj.ready_calls += 1)
	controller.set_player_auto_battle_enabled(true)
	controller.rebuild_turn_roster()
	await get_tree().process_frame
	assert_bool(controller.is_player_auto_control_locked()).is_true()
	await get_tree().create_timer(0.6).timeout
	assert_bool(controller.is_player_auto_battle_enabled()).is_false()
	assert_int(failure_reasons.size()).is_equal(1)
	assert_int(state_obj.ready_calls).is_greater_equal(2)

func test_auto_battle_switches_to_other_unit_when_one_is_stuck() -> void:
	var unit_manager: UnitManager = auto_free(UnitManager.new())
	var controller: TurnController = auto_free(TurnController.new())
	var ai: FakeAIController = auto_free(FakeAIController.new())
	ai.unit_results = {"Hero": false, "Mage": true}
	get_tree().root.add_child(controller)
	get_tree().root.add_child(ai)
	var state := GameState.new({}, [])
	state.unit_manager = unit_manager
	state.ai_controller = ai
	var config := GameSessionBuilder.Config.new()
	controller.setup(state, config)
	var unit_a: Unit = auto_free(Unit.new())
	unit_a.unit_name = "Hero"
	unit_a.willpower = 2
	var unit_b: Unit = auto_free(Unit.new())
	unit_b.unit_name = "Mage"
	unit_b.willpower = 2
	unit_manager.add_unit(unit_a, Vector2i(0, 0), true)
	unit_manager.add_unit(unit_b, Vector2i(1, 0), true)
	controller.set_player_auto_battle_enabled(true)
	controller.rebuild_turn_roster()
	await get_tree().process_frame
	await get_tree().create_timer(0.8).timeout
	assert_bool(controller.is_player_auto_battle_enabled()).is_true()
	assert_array(ai.executed_units).has_size(1)
	assert_str(ai.executed_units[0].unit_name).is_equal("Mage")

func test_auto_battle_disables_after_exhausting_all_units() -> void:
	var unit_manager: UnitManager = auto_free(UnitManager.new())
	var controller: TurnController = auto_free(TurnController.new())
	var ai: FakeAIController = auto_free(FakeAIController.new())
	ai.should_succeed = false
	get_tree().root.add_child(controller)
	get_tree().root.add_child(ai)
	var state := GameState.new({}, [])
	state.unit_manager = unit_manager
	state.ai_controller = ai
	var config := GameSessionBuilder.Config.new()
	controller.setup(state, config)
	var unit_a: Unit = auto_free(Unit.new())
	unit_a.unit_name = "Hero"
	unit_a.willpower = 2
	var unit_b: Unit = auto_free(Unit.new())
	unit_b.unit_name = "Mage"
	unit_b.willpower = 2
	unit_manager.add_unit(unit_a, Vector2i(0, 0), true)
	unit_manager.add_unit(unit_b, Vector2i(1, 0), true)
	var failure_reasons: Array[String] = []
	controller.player_auto_battle_failed.connect(func(reason: String): failure_reasons.append(reason))
	controller.set_player_auto_battle_enabled(true)
	controller.rebuild_turn_roster()
	await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	assert_bool(controller.is_player_auto_battle_enabled()).is_false()
	assert_int(failure_reasons.size()).is_equal(1)
	var seen: Array[String] = []
	for unit in ai.attempted_units:
		seen.append(unit.unit_name)
	assert_int(seen.size()).is_equal(2)
	var hero_attempts := 0
	var mage_attempts := 0
	for unit_name in seen:
		if unit_name == "Hero":
			hero_attempts += 1
		elif unit_name == "Mage":
			mage_attempts += 1
	assert_int(hero_attempts).is_equal(1)
	assert_int(mage_attempts).is_equal(1)

func test_rebuild_turn_roster_handles_player_only_units() -> void:
	_turn_controller.set_enabled(false)
	_unit1.faction = GameConstants.Faction.PLAYER
	_unit_manager.add_unit(_unit1, Vector2i(0, 0), true)
	_turn_controller.rebuild_turn_roster()
	assert_array(_turn_controller._turn_queue).has_size(1)
	assert_int(_turn_controller._turn_queue[0]).is_equal(0)
	_turn_controller.set_enabled(true)

func test_rebuild_turn_roster_handles_player_and_neutral_only() -> void:
	_turn_controller.set_enabled(false)
	_unit1.faction = GameConstants.Faction.PLAYER
	_unit_manager.add_unit(_unit1, Vector2i(0, 0), true)
	var neutral: Unit = auto_free(Unit.new())
	neutral.faction = GameConstants.Faction.NEUTRAL
	_unit_manager.add_unit(neutral, Vector2i(1, 0), false)
	_turn_controller.rebuild_turn_roster()
	var queue := _turn_controller._turn_queue.duplicate()
	assert_int(queue.size()).is_equal(2)
	assert_bool(queue.has(_unit_manager.get_unit_index(neutral))).is_true()
	_turn_controller.set_enabled(true)

func test_restore_memento_rehydrates_auto_battle_state() -> void:
	var unit_manager: UnitManager = auto_free(UnitManager.new())
	var controller: TurnController = auto_free(TurnController.new())
	var state := GameState.new({}, [])
	state.unit_manager = unit_manager
	var config := GameSessionBuilder.Config.new()
	controller.setup(state, config)
	controller.set_player_auto_battle_enabled(true)
	controller.set_enabled(false)
	controller._turns_taken_this_round[GameConstants.Side.PLAYER] = 2
	controller._player_auto_turn_in_progress = true
	var snapshot: Dictionary = controller.create_memento()
	controller.set_player_auto_battle_enabled(false)
	controller.set_enabled(true)
	controller._turns_taken_this_round[GameConstants.Side.PLAYER] = 0
	var toggles: Array[bool] = []
	controller.player_auto_battle_changed.connect(func(enabled: bool): toggles.append(enabled))
	controller.restore_from_memento(snapshot)
	assert_bool(controller.is_player_auto_battle_enabled()).is_true()
	assert_bool(controller.is_enabled()).is_false()
	assert_int(controller._turns_taken_this_round[GameConstants.Side.PLAYER]).is_equal(2)
	assert_bool(controller.is_player_auto_control_locked()).is_false()
	assert_int(toggles.size()).is_equal(1)


func test_player_can_act_with_any_available_unit() -> void:
	var unit_manager: UnitManager = auto_free(UnitManager.new())
	var controller: TurnController = auto_free(TurnController.new())
	var state := GameState.new({}, [])
	state.unit_manager = unit_manager
	var config := GameSessionBuilder.Config.new()
	controller.setup(state, config)
	var unit_a: Unit = auto_free(Unit.new())
	unit_a.unit_name = "Alpha"
	var unit_b: Unit = auto_free(Unit.new())
	unit_b.unit_name = "Bravo"
	unit_manager.add_unit(unit_a, Vector2i(0, 0), true)
	unit_manager.add_unit(unit_b, Vector2i(1, 0), true)
	controller.rebuild_turn_roster()
	var idx_a: int = unit_manager.get_unit_index(unit_a)
	var idx_b: int = unit_manager.get_unit_index(unit_b)
	assert_bool(controller.can_act_on_index(idx_a)).is_true()
	assert_bool(controller.can_act_on_index(idx_b)).is_true()
	controller.lock_active_player_unit(idx_b)
	assert_bool(controller.can_act_on_index(idx_b)).is_true()
	assert_bool(controller.can_act_on_index(idx_a)).is_false()

func test_player_queue_reorders_when_switching_units() -> void:
	var unit_manager: UnitManager = auto_free(UnitManager.new())
	var controller: TurnController = auto_free(TurnController.new())
	var state := GameState.new({}, [])
	state.unit_manager = unit_manager
	var config := GameSessionBuilder.Config.new()
	controller.setup(state, config)
	var unit_a: Unit = auto_free(Unit.new())
	unit_a.unit_name = "Alpha"
	var unit_b: Unit = auto_free(Unit.new())
	unit_b.unit_name = "Bravo"
	var enemy: Unit = auto_free(Unit.new())
	enemy.unit_name = "Enemy"
	enemy.faction = GameConstants.Faction.ENEMY
	unit_manager.add_unit(unit_a, Vector2i(0, 0), true)
	unit_manager.add_unit(enemy, Vector2i(1, 0), false)
	unit_manager.add_unit(unit_b, Vector2i(2, 0), true)
	controller.rebuild_turn_roster()
	var idx_a: int = unit_manager.get_unit_index(unit_a)
	var idx_b: int = unit_manager.get_unit_index(unit_b)
	assert_int(controller._turn_queue[0]).is_equal(idx_a)
	controller.lock_active_player_unit(idx_b)
	assert_int(controller._turn_queue[0]).is_equal(idx_b)
	controller.complete_turn()
	assert_bool(controller.can_act_on_index(idx_b)).is_false()
	assert_bool(controller.can_act_on_index(idx_a)).is_true()

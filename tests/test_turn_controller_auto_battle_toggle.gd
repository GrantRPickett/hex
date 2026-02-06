const TurnSystem := preload("res://Gameplay/turn_system.gd")
extends GdUnitTestSuite

class FakeAIController extends AIController:
	var executed_units: Array[Unit] = []

	func execute_turn(unit: Unit) -> bool:
		executed_units.append(unit)
		await get_tree().process_frame
		return true

func test_auto_battle_toggle_mid_turn_runs_selected_unit() -> void:
	var unit_manager := auto_free(UnitManager.new())
	var controller := auto_free(TurnController.new())
	var ai := auto_free(FakeAIController.new())
	get_tree().root.add_child(controller)
	get_tree().root.add_child(ai)
	controller.setup(unit_manager, ai)
	var player := auto_free(Unit.new())
	player.unit_name = "Hero"
	player.willpower = 2
	var enemy := auto_free(Unit.new())
	enemy.unit_name = "Bandit"
	enemy.willpower = 2
	unit_manager.add_unit(player, Vector2i.ZERO, true)
	unit_manager.add_unit(enemy, Vector2i.ONE, false)
	controller.rebuild_turn_roster()
	await get_tree().process_frame
	assert_bool(controller.is_player_auto_control_locked()).is_false()
	controller.set_player_auto_battle_enabled(true)
	await get_tree().process_frame
	assert_bool(controller.is_player_auto_control_locked()).is_true()
	await get_tree().create_timer(0.6).timeout
	assert_array(ai.executed_units).has_size(1)
	assert_str(ai.executed_units[0].unit_name).is_equal("Hero")

func test_should_preserve_player_auto_turn_only_in_free_roam() -> void:
	var unit_manager := auto_free(UnitManager.new())
	var controller := auto_free(TurnController.new())
	controller.setup(unit_manager, null)
	controller._current_turn_side = TurnSystem.Side.PLAYER
	var player := auto_free(Unit.new())
	player.unit_name = "Scout"
	assert_bool(controller._should_preserve_player_auto_turn(player)).is_false()
	player.set_free_roam_mode(true)
	assert_bool(controller._should_preserve_player_auto_turn(player)).is_true()
	controller._current_turn_side = TurnSystem.Side.ENEMY
	assert_bool(controller._should_preserve_player_auto_turn(player)).is_false()

func test_auto_battle_preserves_turn_for_free_roam_unit() -> void:
	var unit_manager := auto_free(UnitManager.new())
	var controller := auto_free(TurnController.new())
	var ai := auto_free(FakeAIController.new())
	get_tree().root.add_child(controller)
	get_tree().root.add_child(ai)
	controller.setup(unit_manager, ai)
	var player := auto_free(Unit.new())
	player.unit_name = "Hero"
	player.willpower = 2
	player.set_free_roam_mode(true)
	unit_manager.add_unit(player, Vector2i.ZERO, true)
	controller.rebuild_turn_roster()
	await get_tree().process_frame
	controller.set_player_auto_battle_enabled(true)
	await get_tree().create_timer(0.7).timeout
	assert_int(controller.get_current_side()).is_equal(TurnSystem.Side.PLAYER)
	assert_int(controller.get_current_unit_index()).is_not_equal(-1)
	assert_array(ai.executed_units).has_size(1)

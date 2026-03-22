extends GdUnitTestSuite

const AutoBattleScript := preload("res://Gameplay/turn/auto_battle_service.gd")

class FakeTurnController extends TurnController:
	var q: Array[int] = [0]
	func is_queue_empty() -> bool: return q.is_empty()
	func get_turn_queue() -> Array: return q
	func get_current_unit_index() -> int: return q[0] if not q.is_empty() else -1
	func get_current_side() -> int: return GameConstants.Side.PLAYER # 1

class FakeUnitManager extends UnitManager:
	func is_player_controlled(_idx: int) -> bool: return true

func test_auto_battle_force_disable() -> void:
	var ctrl := FakeTurnController.new()
	var srv := AutoBattleScript.new(ctrl)

	srv.set_enabled(true)
	assert_bool(srv.is_enabled()).is_true()

	srv.force_disable("Test reason")
	assert_bool(srv.is_enabled()).is_false()

	ctrl.queue_free()

func test_auto_battle_maybe_run_turn_aborts_if_disabled() -> void:
	var ctrl := FakeTurnController.new()
	var srv := AutoBattleScript.new(ctrl)

	srv.set_enabled(false)
	srv._in_progress = false
	srv.maybe_run_turn(null)

	assert_bool(srv.is_in_progress()).is_false() # Should not have started

	ctrl.queue_free()

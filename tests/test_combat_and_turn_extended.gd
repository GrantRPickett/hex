extends GdUnitTestSuite

# Tests for CombatSystem: get_combat_forecast, get_attack_of_opportunity_forecast
# and TurnController: on_turn_changed

const CombatScript = preload("res://Gameplay/turn/combat_system.gd")

func _make_target(val: int) -> Target:
	var t = Target.new()
	t.grit = val
	t.flow = val
	t.gusto = val
	t.focus = val
	t.shine = val
	t.shade = val
	add_child(t)
	return t

func test_combat_system_get_combat_forecast() -> void:
	var c = auto_free(CombatScript.new())
	var a = _make_target(10)
	var d = _make_target(5)

	var r = c.get_combat_forecast(a, d, 0) # Pair 0

	assert_dict(r).contains_keys(["damage_to_target", "counter_damage_to_self"])
	# 10 - 5 = 5 damage
	assert_int(r["damage_to_target"]).is_equal(5)
	assert_int(r["counter_damage_to_self"]).is_equal(0)

	a.queue_free()
	d.queue_free()

func test_combat_system_get_attack_of_opportunity_forecast() -> void:
	var c = auto_free(CombatScript.new())
	var a = _make_target(10)
	var d = _make_target(5)

	var r = c.get_attack_of_opportunity_forecast(a, d, 0)

	assert_dict(r).contains_keys(["damage_to_target", "counter_damage_to_self"])
	# Opp attack shouldn't have counter
	assert_int(r["counter_damage_to_self"]).is_equal(0)

	a.queue_free()
	d.queue_free()

class FakeCheckpointManager extends Node:
	var requested := false
	func on_checkpoint_requested() -> void:
		requested = true

class FakeTurnControllerExtended extends TurnController:
	pass

func test_turn_controller_on_turn_changed_checkpoints() -> void:
	var t = auto_free(FakeTurnControllerExtended.new())
	var chk = auto_free(FakeCheckpointManager.new())

	t._checkpoint_manager = chk

	# Pass empty unit just to test basic routing
	var u = auto_free(Unit.new())
	t.on_turn_changed(u)

	assert_bool(chk.requested).is_true()

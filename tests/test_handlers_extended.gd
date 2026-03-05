extends GdUnitTestSuite

# Tests for UnitDeathHandler.die and TargetInteractionHandler.work_on_task

const FakeDeathHandler := preload("res://Gameplay/targets/components/unit_death_handler.gd")

func _make_unit() -> Unit:
	var u = Unit.new()
	var ap = ActionPointsComponent.new()
	u.action_points_template = ap
	u.res = ap
	u.stress = 0
	u.is_dead = false
	add_child(u)
	return u

func after_test() -> void:
	for child in get_children():
		if is_instance_valid(child):
			child.queue_free()

func test_unit_death_handler_die() -> void:
	var u = _make_unit()
	u.faction = Unit.Faction.PLAYER
	var handler = FakeDeathHandler.new(u)

	# Simulating default "normal" difficulty which adds 1 stress
	handler.die()

	assert_bool(u.is_dead).is_false()
	assert_int(u.stress).is_equal(1)
	assert_bool(handler._is_dying).is_true()

	# Consecutive calls shouldn't increase stress
	handler.die()
	assert_int(u.stress).is_equal(1)

func test_unit_interaction_handler_work_on_task_fails_without_task() -> void:
	var u = _make_unit()
	var handler = u.interaction

	var success = handler.work_on_opposed_task(null, null)
	assert_bool(success).is_false()

class FakeTask extends Task:
	var can_work := true
	func can_be_worked_on_by(_u: Unit, _c: Vector2i = Vector2i.ZERO) -> bool:
		return can_work

class FakeLocation extends Location:
	var interacted_with: Unit = null
	func interact(u: Unit, _ctx: Dictionary = {}) -> void:
		interacted_with = u

func test_unit_interaction_handler_work_on_task_succeeds() -> void:
	var u = _make_unit()
	var handler = u.interaction
	var tm = TaskManager.new()
	handler._task_manager = tm

	var task = FakeTask.new()
	var loc = FakeLocation.new()

	var success = handler.work_on_opposed_task(task, loc)

	assert_bool(success).is_true()
	assert_object(loc.interacted_with).is_equal(u)
	assert_bool(u.res.has_action_available()).is_false()

	# Should fail now that action is consumed
	success = handler.work_on_opposed_task(task, loc)
	assert_bool(success).is_false()

	task.queue_free()
	loc.queue_free()
	tm.queue_free()

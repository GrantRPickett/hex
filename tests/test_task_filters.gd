extends GdUnitTestSuite

const Task := preload("res://Gameplay/narrative/task/task.gd")

const Unit := preload("res://Gameplay/targets/unit.gd")
const Stubs := preload("res://tests/fixtures/test_stubs.gd")

func _make_task() -> Task:
	var task: Task = Task.new()
	task.id = &"test_task"
	task.owning_faction = GameConstants.Faction.PLAYER
	task.effort_required = 2
	task.is_opposed = false
	task.initialize()
	return task

func test_target_filters_match_multiple_event_types() -> void:
	var task := _make_task()
	task.target_filters = [
		{"event_type": GameConstants.TaskEvents.EXPLORE, "target_id": "Ancient Cave", "target_kind": "location"},
		{"event_type": GameConstants.TaskEvents.LOOT, "target_id": "Relic Cache", "target_kind": "item"}
	]
	var unit := Stubs.FakeUnit.new()
	unit.faction = GameConstants.Faction.PLAYER
	task.handle_event(GameConstants.TaskEvents.EXPLORE, {"unit": unit, "id": "Ancient Cave"})
	assert_int(task.current_effort).is_equal(1)
	task.handle_event(GameConstants.TaskEvents.LOOT, {"unit": unit, "id": "Relic Cache"})
	assert_bool(task.current_effort >= task.effort_required).is_true()

func test_target_filters_coordinate_gating() -> void:
	var task := _make_task()
	task.target_filters = [
		{"event_type": GameConstants.TaskEvents.EXPLORE, "target_coord": Vector2i(2, 2), "target_kind": "location"}
	]
	var unit := Stubs.FakeUnit.new()
	unit.faction = GameConstants.Faction.PLAYER
	unit.set_grid_location(Vector2i(2, 2))
	assert_bool(task.can_be_worked_on_by(unit, Vector2i(2, 2))).is_true()
	assert_bool(task.can_be_worked_on_by(unit, Vector2i(1, 1))).is_false()

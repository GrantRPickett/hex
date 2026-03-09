extends GdUnitTestSuite

# Tests for TaskController covering:
# set_level, on_unit_defeated, on_round_changed, check_inventory_objectives, get_task_info

const TaskControllerScript := preload("res://Gameplay/narrative/task/task_controller.gd")

class FakeTaskManager extends TaskManager:
	var level_set: Level = null
	var objective_set: Objective = null
	var active_obj: FakeObjective = null
	var task: Task = null

	func set_level_and_objective(lvl: Level, obj: Objective) -> void:
		level_set = lvl
		objective_set = obj

	func get_active_objective() -> Objective:
		return active_obj as Objective

	func get_task_by_id(id: String) -> Task:
		if id == "found":
			return task
		return null

class FakeObjective extends Objective:
	var handled_events: Dictionary = {}
	func handle_event(event_name: String, payload: Dictionary) -> void:
		handled_events[event_name] = payload

class FakeUnitManager extends UnitManager:
	func get_unit_count() -> int:
		return 1
	func get_unit(_i: int) -> Unit:
		var u = Unit.new()
		u.faction = Unit.Faction.PLAYER
		u.willpower = 10
		return u
class FakeGameState extends GameState:
	func _init():
		var empty_dict: Dictionary = {}
		super (empty_dict)

func _make_controller() -> TaskController:
	var c := TaskControllerScript.new()
	var state := FakeGameState.new()
	var tm := FakeTaskManager.new()
	var um := FakeUnitManager.new()
	state.task_manager = tm
	state.unit_manager = um
	c.setup(state)
	return c

# ---------------------------------------------------------------------------
# set_level
# ---------------------------------------------------------------------------

func test_set_level_updates_manager() -> void:
	var c := _make_controller()
	var lvl := Level.new()
	var obj := Objective.new()
	lvl.objective = obj

	c.set_level(lvl)
	assert_object(c.level).is_equal(lvl)
	var tm: FakeTaskManager = c._task_manager
	assert_object(tm.level_set).is_equal(lvl)
	assert_object(tm.objective_set).is_equal(obj)

# ---------------------------------------------------------------------------
# on_unit_defeated
# ---------------------------------------------------------------------------

func test_on_unit_defeated_passes_event_to_objective() -> void:
	var c := _make_controller()
	var target := Unit.new()
	var obj := FakeObjective.new()
	obj.is_active = true
	var tm: FakeTaskManager = c._task_manager
	tm.active_obj = obj

	c.on_unit_defeated(target)
	assert_bool(obj.handled_events.has("unit_defeated")).is_true()
	assert_object(obj.handled_events["unit_defeated"]["unit"]).is_equal(target)

	target.queue_free()

# ---------------------------------------------------------------------------
# on_round_changed
# ---------------------------------------------------------------------------

func test_on_round_changed_passes_event_to_objective() -> void:
	var c := _make_controller()
	var obj := FakeObjective.new()
	obj.is_active = true
	var tm: FakeTaskManager = c._task_manager
	tm.active_obj = obj

	c.on_round_changed(5)
	assert_bool(obj.handled_events.has("round_changed")).is_true()
	assert_int(obj.handled_events["round_changed"]["round"]).is_equal(5)

# ---------------------------------------------------------------------------
# check_inventory_objectives
# ---------------------------------------------------------------------------

func test_check_inventory_objectives_passes_event_to_objective() -> void:
	var c := _make_controller()
	var obj := FakeObjective.new()
	obj.is_active = true
	var tm: FakeTaskManager = c._task_manager
	tm.active_obj = obj

	var units: Array[Unit] = []
	var test_unit := Unit.new()
	units.append(test_unit)

	c.check_inventory_objectives(units)
	assert_bool(obj.handled_events.has("inventory_check")).is_true()
	assert_array(obj.handled_events["inventory_check"]["units"]).contains(test_unit)

	test_unit.queue_free()

func test_check_objective_conditions_checks_inventory() -> void:
	# check_objective_conditions calls check_inventory_objectives on player units internally
	var c := _make_controller()
	var obj := FakeObjective.new()
	obj.is_active = true
	var tm: FakeTaskManager = c._task_manager
	tm.active_obj = obj

	c.check_objective_conditions()

	# The inner UnitManager stub returns one player unit
	assert_bool(obj.handled_events.has("inventory_check")).is_true()

# ---------------------------------------------------------------------------
# get_task_info
# ---------------------------------------------------------------------------

func test_get_task_info_returns_transformed_dict() -> void:
	var c := _make_controller()
	var tm: FakeTaskManager = c._task_manager
	var task := Task.new()
	task.id = "found"
	task.title = "A Task"
	task.description = "A Description"
	task.status = Task.Status.ACTIVE
	task.current_effort = 1
	task.effort_required = 3
	task.is_optional = true
	tm.task = task

	var result = c.get_task_info("found")
	assert_dict(result).contains_keys(["id", "title", "description", "status", "current", "required", "completed", "is_optional", "icon"])
	assert_str(result["id"]).is_equal("found")
	assert_str(result["title"]).is_equal("A Task")
	assert_int(result["current"]).is_equal(1)
	assert_int(result["required"]).is_equal(3)
	assert_bool(result["is_optional"]).is_true()

func test_get_task_info_returns_empty_when_not_found() -> void:
	var c := _make_controller()
	var result = c.get_task_info("not_found")
	assert_dict(result).is_empty()

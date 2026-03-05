extends GdUnitTestSuite

const TaskManagerScript := preload("res://Gameplay/narrative/task/task_manager.gd")
const ObjectiveScript := preload("res://Gameplay/narrative/task/objective.gd")
const StageScript := preload("res://Gameplay/narrative/task/stage.gd")
const TaskScript := preload("res://Gameplay/narrative/task/task.gd")
const UnitScript := preload("res://Gameplay/targets/unit.gd")
const LootScript := preload("res://Gameplay/targets/loot.gd")
const LocationScript := preload("res://Gameplay/targets/location.gd")

var _manager: TaskManager
var _unit_manager: UnitManager

func before_test() -> void:
	_manager = TaskManagerScript.new()
	_unit_manager = UnitManager.new()
	_manager._unit_manager = _unit_manager
	add_child(_manager)
	add_child(_unit_manager)

func after_test() -> void:
	if is_instance_valid(_manager):
		_manager.queue_free()
	if is_instance_valid(_unit_manager):
		_unit_manager.queue_free()

func _setup_active_objective(task: Task) -> Objective:
	var stage: Stage = StageScript.new()
	stage.id = &"test_stage"
	stage.tasks.append(task)
	var obj: Objective = ObjectiveScript.new("obj_1", "Test Obj", "")
	obj.starting_stage = stage
	_manager._active_objective = obj
	obj.start_objective(Level.new())
	return obj

func test_final_loot_interaction() -> void:
	var t: Task = TaskScript.new()
	t.id = &"loot_task"
	t.event_type = GameConstants.TaskEvents.PICKUP
	t.effort_required = 1
	_setup_active_objective(t)
	
	var unit: Unit = UnitScript.new()
	var loot: Loot = LootScript.new()
	_manager.register_loot(loot)
	
	# Simulate TargetInteractionHandler calling interact
	loot.interact(unit, {"type": GameConstants.Interactions.LOOT})
	
	var active_task: Task = _manager._active_objective.current_stage.active_tasks[0]
	assert_int(active_task.status).is_equal(Task.Status.COMPLETED)

func test_final_visit_interaction() -> void:
	var t: Task = TaskScript.new()
	t.id = &"visit_task"
	t.event_type = GameConstants.TaskEvents.TARGET_INTERACTION
	t.effort_required = 1
	_setup_active_objective(t)
	
	var unit: Unit = UnitScript.new()
	var loc: Location = LocationScript.new()
	_manager.register_location(loc)
	
	# Simulate TargetInteractionHandler calling interact
	loc.interact(unit, {"type": GameConstants.Interactions.VISIT})
	
	var active_task: Task = _manager._active_objective.current_stage.active_tasks[0]
	assert_int(active_task.status).is_equal(Task.Status.COMPLETED)

func test_final_convince_interaction() -> void:
	var t: Task = TaskScript.new()
	t.id = &"convince_task"
	t.event_type = GameConstants.TaskEvents.DIALOGUE_STARTED
	t.effort_required = 1
	t.target_id = "convince"
	_setup_active_objective(t)
	
	var unit: Unit = UnitScript.new()
	var target_unit: Unit = UnitScript.new()
	_manager.register_unit(target_unit)
	
	# Simulate TargetInteractionHandler calling interact
	target_unit.interact(unit, {"type": GameConstants.Interactions.CONVINCE})
	
	var active_task: Task = _manager._active_objective.current_stage.active_tasks[0]
	assert_int(active_task.status).is_equal(Task.Status.COMPLETED)

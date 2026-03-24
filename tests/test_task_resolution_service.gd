extends GdUnitTestSuite
class_name TaskResolutionServiceTest

const TaskResolutionService = preload("res://Gameplay/narrative/task/task_resolution_service.gd")

class StubTaskManager extends TaskManager:
	var tasks_by_id: Dictionary = {}
	var locations_by_coord: Dictionary = {}
	var units_by_coord: Dictionary = {}
	var tasks_for_target: Array[Task] = []

	func get_task_by_id(task_id: String) -> Task:
		return tasks_by_id.get(task_id)

	func get_location_at(coord: Vector2i) -> Location:
		return locations_by_coord.get(coord)

	func get_target_at(coord: Vector2i) -> Target:
		if locations_by_coord.has(coord): return locations_by_coord[coord]
		if units_by_coord.has(coord): return units_by_coord[coord]
		return null

	func get_unit(_index: int) -> Unit:
		for coord in units_by_coord:
			return units_by_coord[coord]
		return null

	func get_target_by_id(target_id: String) -> Target:
		if target_id.is_empty(): return null
		for loc in locations_by_coord.values():
			if resolve_target_id(loc) == target_id: return loc
		for unit in units_by_coord.values():
			if resolve_target_id(unit) == target_id: return unit
		return null

	func get_active_tasks_for_target(_target: Target, _faction: int = GameConstants.INVALID_INDEX) -> Array[Task]:
		return tasks_for_target

func test_resolve_from_task_object() -> void:
	var task := Task.new()
	task.event_type = "test_event"
	var result := TaskResolutionService.resolve_task_and_target(null, task, "test_event")
	assert_that(result.task).is_same(task)

func test_resolve_from_target_object() -> void:
	var target := Target.new()
	var result := TaskResolutionService.resolve_task_and_target(null, target, "any_event")
	assert_that(result.target).is_same(target)

func test_resolve_from_dictionary_with_task_id() -> void:
	var manager := StubTaskManager.new()
	var context := GameCommandContext.new({GameConstants.ContextKeys.TASK_MANAGER: manager})
	var task := Task.new()
	task.id = "test_task"
	task.event_type = "test_event"
	manager.tasks_by_id["test_task"] = task
	
	var payload = {GameConstants.Payload.TASK_ID: "test_task"}
	var result := TaskResolutionService.resolve_task_and_target(context, payload, "test_event")
	assert_that(result.task).is_same(task)

func test_resolve_from_dictionary_with_coord() -> void:
	var manager := StubTaskManager.new()
	var context := GameCommandContext.new({GameConstants.ContextKeys.TASK_MANAGER: manager})
	var target := Location.new()
	var coord := Vector2i(1, 2)
	manager.locations_by_coord[coord] = target
	
	var payload = {GameConstants.Payload.TARGET_COORD: coord}
	var result := TaskResolutionService.resolve_task_and_target(context, payload, "any_event")
	assert_that(result.target).is_same(target)

func test_resolve_finds_task_for_target() -> void:
	var manager := StubTaskManager.new()
	var context := GameCommandContext.new({GameConstants.ContextKeys.TASK_MANAGER: manager})
	var target := Location.new()
	var task := Task.new()
	task.event_type = "test_event"
	manager.tasks_for_target = [task]
	
	var result := TaskResolutionService.resolve_task_and_target(context, target, "test_event")
	assert_that(result.task).is_same(task)
	assert_that(result.target).is_same(target)

func test_resolve_finds_target_for_task() -> void:
	var manager := StubTaskManager.new()
	var context := GameCommandContext.new({GameConstants.ContextKeys.TASK_MANAGER: manager})
	var target := Location.new()
	var task := Task.new()
	task.event_type = "test_event"
	task.target_coord = Vector2i(5, 5)
	manager.locations_by_coord[Vector2i(5, 5)] = target
	
	var result := TaskResolutionService.resolve_task_and_target(context, task, "test_event")
	assert_that(result.task).is_same(task)
	assert_that(result.target).is_same(target)

func test_resolve_unit_target_from_task_coord() -> void:
	var manager := StubTaskManager.new()
	var context := GameCommandContext.new({GameConstants.ContextKeys.TASK_MANAGER: manager})
	var unit := Unit.new()
	unit.unit_name = "TestUnit"
	var coord := Vector2i(10, 10)
	manager.units_by_coord[coord] = unit
	
	var task := Task.new()
	task.event_type = "test_event"
	task.target_coord = coord
	
	var result := TaskResolutionService.resolve_task_and_target(context, task, "test_event")
	assert_that(result.target).is_same(unit)

func test_resolve_unit_target_from_task_id() -> void:
	var manager := StubTaskManager.new()
	var context := GameCommandContext.new({GameConstants.ContextKeys.TASK_MANAGER: manager})
	var unit := Unit.new()
	unit.unit_name = "UniqueUnitID"
	manager.units_by_coord[Vector2i(0,0)] = unit
	
	var task := Task.new()
	task.event_type = "test_event"
	task.target_id = "UniqueUnitID"
	
	var result := TaskResolutionService.resolve_task_and_target(context, task, "test_event")
	assert_that(result.target).is_same(unit)

func test_resolve_from_dictionary_with_loot_coord() -> void:
	var manager := StubTaskManager.new()
	var context := GameCommandContext.new({GameConstants.ContextKeys.TASK_MANAGER: manager})
	var target := Loot.new()
	var coord := Vector2i(15, 15)
	manager.locations_by_coord[coord] = target
	
	var payload := {GameConstants.Payload.LOOT_COORD: coord}
	var result := TaskResolutionService.resolve_task_and_target(context, payload, "test_event")
	assert_that(result.target).is_same(target)

func test_resolve_from_dictionary_with_target_index() -> void:
	var manager := StubTaskManager.new()
	var context := GameCommandContext.new({GameConstants.ContextKeys.TASK_MANAGER: manager})
	var target := Unit.new()
	manager.units_by_coord[Vector2i(0,0)] = target
	
	var payload := {GameConstants.Payload.TARGET_INDEX: 0}
	var result := TaskResolutionService.resolve_task_and_target(context, payload, "test_event")
	assert_that(result.target).is_same(target)

func test_resolve_provides_casted_fields() -> void:
	var manager := StubTaskManager.new()
	var context := GameCommandContext.new({GameConstants.ContextKeys.TASK_MANAGER: manager})
	
	# Test Unit cast
	var unit := Unit.new()
	manager.units_by_coord[Vector2i(0,0)] = unit
	var res_unit := TaskResolutionService.resolve_task_and_target(context, {GameConstants.Payload.TARGET_COORD: Vector2i(0,0)}, "test")
	assert_that(res_unit.unit).is_same(unit)
	assert_that(res_unit.location).is_null()
	assert_that(res_unit.loot).is_null()
	
	# Test Location cast
	var loc := Location.new()
	manager.locations_by_coord[Vector2i(1,1)] = loc
	var res_loc := TaskResolutionService.resolve_task_and_target(context, {GameConstants.Payload.TARGET_COORD: Vector2i(1,1)}, "test")
	assert_that(res_loc.location).is_same(loc)
	assert_that(res_loc.unit).is_null()
	assert_that(res_loc.loot).is_null()
	assert_that(res_loc.is_narrative).is_false()

func test_resolve_distinguishes_narrative_vs_incidental() -> void:
	var manager := StubTaskManager.new()
	var context := GameCommandContext.new({GameConstants.ContextKeys.TASK_MANAGER: manager})
	
	var loc := Location.new()
	manager.locations_by_coord[Vector2i(0,0)] = loc
	
	# Scenario A: Narrative (Task exists)
	var task := Task.new()
	task.event_type = "test_event"
	manager.tasks_for_target = [task]
	
	var res_narrative := TaskResolutionService.resolve_task_and_target(context, {GameConstants.Payload.TARGET_COORD: Vector2i(0,0)}, "test_event")
	assert_that(res_narrative.is_narrative).is_true()
	assert_that(res_narrative.resolution_mode).is_equal("NARRATIVE")
	assert_that(res_narrative.task).is_same(task)
	
	# Scenario B: Incidental (No Task exists)
	manager.tasks_for_target = []
	var res_incidental := TaskResolutionService.resolve_task_and_target(context, {GameConstants.Payload.TARGET_COORD: Vector2i(0,0)}, "test_event")
	assert_that(res_incidental.is_narrative).is_false()
	assert_that(res_incidental.resolution_mode).is_equal("INCIDENTAL")
	assert_that(res_incidental.task).is_null()

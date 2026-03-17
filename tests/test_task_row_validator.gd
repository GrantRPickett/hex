# test_task_row_validator.gd
extends GdUnitTestSuite

# No need to preload global class_names like Level, Objective, etc.
# TaskRowValidator is also global.

func test_validate_empty_level() -> void:
	var errors = TaskRowValidator.validate(null, "test_level", [], [], [])
	assert_array(errors).is_empty()

func test_validate_basic_valid_level() -> void:
	var level = Level.new()
	var obj = Objective.new()
	var stage = Stage.new()
	stage.id = &"stage_1"
	
	var task = Task.new()
	task.id = &"task_1"
	task.title = "A real task"
	task.event_type = "visit"
	task.target_kind = "location"
	task.target_id = "loc_1"
	task.target_coord = Vector2i(1, 1)
	task.effort_required = 5
	
	stage.tasks = [task]
	obj.stages = [stage]
	level.objective = obj
	
	var loc = LevelTaskEntry.new()
	loc.loc_id = "loc_1"
	loc.coord = Vector2i(1, 1)
	var stats = CombatStats.new()
	stats.willpower = 5
	loc.stats = stats
	
	var errors = TaskRowValidator.validate(level, "test_level", [], [], [loc])
	assert_array(errors).is_empty()

func test_validate_missing_metadata() -> void:
	var level = Level.new()
	var obj = Objective.new()
	var stage = Stage.new()
	stage.id = &"stage_1"
	
	var task = Task.new()
	# Missing id, title, event_type
	
	stage.tasks = [task]
	obj.stages = [stage]
	level.objective = obj
	
	var errors = TaskRowValidator.validate(level, "test_level", [], [], [])
	assert_array(errors).has_size(3)
	assert_str(errors[0]).contains("missing 'id'")
	assert_str(errors[1]).contains("default/empty title")
	assert_str(errors[2]).contains("missing 'event_type'")

func test_validate_item_not_found() -> void:
	var level = Level.new()
	var obj = Objective.new()
	var stage = Stage.new()
	stage.id = &"stage_1"
	
	var task = Task.new()
	task.id = &"task_1"
	task.title = "Loot item"
	task.event_type = "loot"
	task.target_kind = "item"
	task.target_id = "missing_item"
	
	stage.tasks = [task]
	obj.stages = [stage]
	level.objective = obj
	
	var errors = TaskRowValidator.validate(level, "test_level", [], [], [])
	assert_array(errors).has_size(1)
	assert_str(errors[0]).contains("item target 'missing_item' not found")

func test_validate_location_misaligned_willpower() -> void:
	var level = Level.new()
	var obj = Objective.new()
	var stage = Stage.new()
	stage.id = &"stage_1"
	
	var task = Task.new()
	task.id = &"task_1"
	task.title = "Visit location"
	task.event_type = "visit"
	task.target_kind = "location"
	task.target_id = "loc_1"
	task.target_coord = Vector2i(1, 1)
	task.effort_required = 10 # Misaligned with 5
	
	stage.tasks = [task]
	obj.stages = [stage]
	level.objective = obj
	
	var loc = LevelTaskEntry.new()
	loc.loc_id = "loc_1"
	loc.coord = Vector2i(1, 1)
	var stats = CombatStats.new()
	stats.willpower = 5
	loc.stats = stats
	
	var errors = TaskRowValidator.validate(level, "test_level", [], [], [loc])
	assert_array(errors).has_size(1)
	assert_str(errors[0]).contains("misaligned with location willpower")

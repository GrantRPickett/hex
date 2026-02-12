extends GdUnitTestSuite

var _location_manager: LocationManager

func before() -> void:
	_location_manager = LocationManager.new()

func after() -> void:
	if _location_manager:
		_location_manager.free()
		_location_manager = null

func test_get_location_count() -> void:
	var coords: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 2)]
	var locations: Array[TargetTask] = []
	_location_manager.setup(coords, locations, null)
	assert_int(_location_manager.get_location_count()).is_equal(3)

func test_multi_step_progression() -> void:
	var def = TaskDefinition.new()
	def.title = "MultiStep Task"

	var step1 = TaskStep.new()
	step1.description = "Step 1"
	step1.required_amount = 10
	step1.required_attribute = "grit"

	var step2 = TaskStep.new()
	step2.description = "Step 2"
	step2.required_amount = 20
	step2.required_attribute = "willpower"

	var steps: Array[TaskStep] = []
	steps.append(step1)
	steps.append(step2)
	def.steps = steps

	var target_task = auto_free(TargetTask.new())
	target_task.definition = def

	var coords: Array[Vector2i] = [Vector2i(0, 0)]
	_location_manager.setup(coords, [target_task], null)

	var unit = auto_free(Unit.new())
	unit.faction = Unit.Faction.PLAYER
	# Mock attributes? Unit returns 1 if missing, or we rely on default.
	# Unit.get_attributes().get_attribute(type) usually returns value.
	# If defaults are low, we might need many calls.
	# Let's assume Unit gives > 0.

	# Step 1: Needs 10.
	# Apply progress until complete.
	for i in range(10):
		_location_manager.apply_progress(0, unit)

	# Check if progressed to Step 2
	# get_required_amount should now return Step 2 amount (20)
	# But only if we crossed the threshold exactly or checking logic handles overflow/next step ready.
	# apply_progress emits location_completed if FINAL step done.
	# LocationManager auto-increments step if amount >= required.

	# After 10 calls (assuming 1 per call), progress >= 10.
	# Step moves to 1.

	var desc = _location_manager.get_current_step_description(0, Unit.Faction.PLAYER)
	assert_str(desc).is_equal("Step 2")

	var req = _location_manager.get_required_amount(0, Unit.Faction.PLAYER)
	assert_int(req).is_equal(20)

func test_faction_independence() -> void:
	var def = TaskDefinition.new()
	var step := TaskStep.new()
	step.description = "Step 1"
	step.required_amount = 5
	var single_step: Array[TaskStep] = []
	single_step.append(step)
	def.steps = single_step

	var target_task = auto_free(TargetTask.new())
	target_task.definition = def

	_location_manager.setup([Vector2i.ZERO], [target_task], null)

	var p_unit = auto_free(Unit.new())
	p_unit.faction = Unit.Faction.PLAYER

	var e_unit = auto_free(Unit.new())
	e_unit.faction = Unit.Faction.ENEMY

	for i in range(5):
		_location_manager.apply_progress(0, p_unit)

	# Player finished step? If single step, location complete.
	assert_bool(_location_manager.is_location_reached(0, Unit.Faction.PLAYER)).is_true()
	assert_bool(_location_manager.is_location_reached(0, Unit.Faction.ENEMY)).is_false()

func test_get_progress_initial() -> void:
	var coords: Array[Vector2i] = [Vector2i(0, 0)]
	_location_manager.setup(coords, [], null)
	assert_int(_location_manager.get_progress(0, Unit.Faction.PLAYER)).is_equal(0)

func test_remaining_location_titles_reflect_unfinished_required_locations() -> void:
	var def_a = TaskDefinition.new()
	def_a.title = "TaskA"
	var step_a := TaskStep.new()
	step_a.required_amount = 1
	step_a.required_attribute = "grit"
	def_a.steps = [step_a]
	var def_b = TaskDefinition.new()
	def_b.title = "TaskB"
	var step_b := TaskStep.new()
	step_b.required_amount = 1
	step_b.required_attribute = "grit"
	def_b.steps = [step_b]
	var target_task_a = auto_free(TargetTask.new())
	target_task_a.definition = def_a
	var target_task_b = auto_free(TargetTask.new())
	target_task_b.definition = def_b
	_location_manager.setup([Vector2i(0, 0), Vector2i(1, 0)], [target_task_a, target_task_b], null)
	var unit = auto_free(Unit.new())
	unit.faction = Unit.Faction.PLAYER
	var remaining := _location_manager.get_remaining_location_titles()
	assert_int(remaining.size()).is_equal(2)
	assert_str(remaining[0]).is_equal("TaskA")
	assert_str(remaining[1]).is_equal("TaskB")
	_location_manager.apply_progress(0, unit)
	remaining = _location_manager.get_remaining_location_titles()
	assert_int(remaining.size()).is_equal(1)
	assert_str(remaining[0]).is_equal("TaskB")
	_location_manager.apply_progress(1, unit)
	remaining = _location_manager.get_remaining_location_titles()
	assert_int(remaining.size()).is_equal(0)

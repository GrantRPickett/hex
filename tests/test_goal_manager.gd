extends GdUnitTestSuite

var _goal_manager: GoalManager

func before() -> void:
	_goal_manager = GoalManager.new()

func after() -> void:
	if _goal_manager:
		_goal_manager.free()
		_goal_manager = null

func test_get_goal_count() -> void:
	var coords: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 2)]
	var goals: Array[Goal] = []
	_goal_manager.setup(coords, goals, null)
	assert_int(_goal_manager.get_goal_count()).is_equal(3)

func test_multi_step_progression() -> void:
	var def = GoalDefinition.new()
	def.title = "MultiStep Goal"

	var step1 = GoalStep.new()
	step1.description = "Step 1"
	step1.required_amount = 10
	step1.required_attribute = "grit"

	var step2 = GoalStep.new()
	step2.description = "Step 2"
	step2.required_amount = 20
	step2.required_attribute = "willpower"

	def.steps = [step1, step2]

	var goal = auto_free(Goal.new())
	goal.definition = def

	var coords: Array[Vector2i] = [Vector2i(0, 0)]
	_goal_manager.setup(coords, [goal], null)

	var unit = auto_free(Unit.new())
	unit.faction = Unit.Faction.PLAYER
	# Mock attributes? Unit returns 1 if missing, or we rely on default.
	# Unit.get_attributes().get_attribute(type) usually returns value.
	# If defaults are low, we might need many calls.
	# Let's assume Unit gives > 0.

	# Step 1: Needs 10.
	# Apply progress until complete.
	for i in range(10):
		_goal_manager.apply_progress(0, unit)

	# Check if progressed to Step 2
	# get_required_amount should now return Step 2 amount (20)
	# But only if we crossed the threshold exactly or checking logic handles overflow/next step ready.
	# apply_progress emits goal_completed if FINAL step done.
	# GoalManager auto-increments step if amount >= required.

	# After 10 calls (assuming 1 per call), progress >= 10.
	# Step moves to 1.

	var desc = _goal_manager.get_current_step_description(0, Unit.Faction.PLAYER)
	assert_str(desc).is_equal("Step 2")

	var req = _goal_manager.get_required_amount(0, Unit.Faction.PLAYER)
	assert_int(req).is_equal(20)

func test_faction_independence() -> void:
	var def = GoalDefinition.new()
	def.steps = [GoalStep.new()]
	def.steps[0].description = "Step 1"
	def.steps[0].required_amount = 5

	var goal = auto_free(Goal.new())
	goal.definition = def

	_goal_manager.setup([Vector2i(0, 0)], [goal], null)

	var p_unit = auto_free(Unit.new())
	p_unit.faction = Unit.Faction.PLAYER

	var e_unit = auto_free(Unit.new())
	e_unit.faction = Unit.Faction.ENEMY

	for i in range(5):
		_goal_manager.apply_progress(0, p_unit)

	# Player finished step? If single step, goal complete.
	assert_bool(_goal_manager.is_goal_reached(0, Unit.Faction.PLAYER)).is_true()
	assert_bool(_goal_manager.is_goal_reached(0, Unit.Faction.ENEMY)).is_false()

func test_get_progress_initial() -> void:
	var coords: Array[Vector2i] = [Vector2i(0, 0)]
	_goal_manager.setup(coords, [], null)
	assert_int(_goal_manager.get_progress(0, Unit.Faction.PLAYER)).is_equal(0)

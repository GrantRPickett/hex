extends GdUnitTestSuite

const DifficultyServiceScript = preload("res://Autoloads/difficulty_service.gd")

func _make_service() -> Node:
	var service: DifficultyServiceScript = DifficultyServiceScript.new()
	add_child(service)
	return service

func after_test() -> void:
	for child in get_children():
		child.queue_free()

func test_get_ai_scaling_factor() -> void:
	var service = _make_service()
	service.current_difficulty = GameConstants.Settings.DIFFICULTY_EASY
	assert_float(service.get_ai_scaling_factor()).is_equal(GameConstants.Difficulty.AI_SCALE_EASY)

	service.current_difficulty = GameConstants.Settings.DIFFICULTY_NORMAL
	assert_float(service.get_ai_scaling_factor()).is_equal(GameConstants.Difficulty.AI_SCALE_NORMAL)

	service.current_difficulty = GameConstants.Settings.DIFFICULTY_HARD
	assert_float(service.get_ai_scaling_factor()).is_equal(GameConstants.Difficulty.AI_SCALE_HARD)

func test_get_ai_morale_weight() -> void:
	var service = _make_service()
	service.current_difficulty = GameConstants.Settings.DIFFICULTY_EASY
	assert_float(service.get_ai_morale_weight()).is_equal(GameConstants.Difficulty.AI_MORALE_WEIGHT_EASY)

	service.current_difficulty = GameConstants.Settings.DIFFICULTY_NORMAL
	assert_float(service.get_ai_morale_weight()).is_equal(GameConstants.Difficulty.AI_MORALE_WEIGHT_NORMAL)

	service.current_difficulty = GameConstants.Settings.DIFFICULTY_HARD
	assert_float(service.get_ai_morale_weight()).is_equal(GameConstants.Difficulty.AI_MORALE_WEIGHT_HARD)

func test_get_retreat_threshold() -> void:
	var service = _make_service()
	service.current_difficulty = GameConstants.Settings.DIFFICULTY_EASY
	assert_float(service.get_retreat_threshold()).is_equal(GameConstants.Difficulty.RETREAT_THRESHOLD_EASY)

	service.current_difficulty = GameConstants.Settings.DIFFICULTY_NORMAL
	assert_float(service.get_retreat_threshold()).is_equal(GameConstants.Difficulty.RETREAT_THRESHOLD_NORMAL)

	service.current_difficulty = GameConstants.Settings.DIFFICULTY_HARD
	assert_float(service.get_retreat_threshold()).is_equal(GameConstants.Difficulty.RETREAT_THRESHOLD_HARD)

func test_get_combat_modifier() -> void:
	var service = _make_service()
	service.current_difficulty = GameConstants.Settings.DIFFICULTY_EASY
	assert_float(service.get_combat_modifier()).is_equal(GameConstants.Difficulty.COMBAT_MODIFIER_EASY)

	service.current_difficulty = GameConstants.Settings.DIFFICULTY_NORMAL
	assert_float(service.get_combat_modifier()).is_equal(GameConstants.Difficulty.COMBAT_MODIFIER_NORMAL)

	service.current_difficulty = GameConstants.Settings.DIFFICULTY_HARD
	assert_float(service.get_combat_modifier()).is_equal(GameConstants.Difficulty.COMBAT_MODIFIER_HARD)

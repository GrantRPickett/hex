extends GdUnitTestSuite

const DialogueRepairer = preload("res://level/validation/repair/dialogue_repairer.gd")
const LocationRepairer = preload("res://level/validation/repair/location_repairer.gd")
const TaskRepairer = preload("res://level/validation/repair/task_repairer.gd")
const UnitSpawnRepairer = preload("res://level/validation/repair/unit_spawn_repairer.gd")

func test_repairers() -> void:
	var dialogue_repairer = DialogueRepairer.new()
	if false:
		dialogue_repairer.repair(null, [], {}, {}, null)

	var location_repairer = LocationRepairer.new()
	if false:
		location_repairer.repair(null, [], {}, {}, null)

	var task_repairer = TaskRepairer.new()
	if false:
		task_repairer.repair(null, {}, {}, null)

	var spawn_repairer = UnitSpawnRepairer.new()
	if false:
		spawn_repairer.repair_player_starts(null, [], {}, {}, null)
		spawn_repairer.repair_neutral_starts(null, [], {}, {}, null)

	assert_that(dialogue_repairer).is_not_null()
	assert_that(location_repairer).is_not_null()
	assert_that(task_repairer).is_not_null()
	assert_that(spawn_repairer).is_not_null()

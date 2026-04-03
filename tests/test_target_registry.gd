extends GdUnitTestSuite

const UNIT_SCENE := preload("res://Gameplay/targets/unit.gd")

func before_test() -> void:
	TargetDiscoveryService.clear_registry()

func test_target_registration() -> void:
	var target = auto_free(Node2D.new())
	target.set_script(load("res://Gameplay/targets/target.gd"))

	# Manually trigger ready since it's not in the tree
	target._ready()

	var generated_id = target.get_target_id()
	assert_str(generated_id).is_not_empty()
	assert_str(generated_id).starts_with("target_")

	var found = TargetDiscoveryService.get_target_by_id(generated_id)
	assert_object(found).is_same(target)

func test_subtype_deterministic_ids() -> void:
	var unit1 = auto_free(load("res://Gameplay/targets/unit.gd").new())
	unit1._ready()
	print("DEBUG: unit1 ID = '%s'" % unit1.get_target_id())
	assert_str(unit1.get_target_id()).is_equal("unit_1")

	var loot1 = auto_free(load("res://Gameplay/targets/loot.gd").new())
	loot1._ready()
	print("DEBUG: loot1 ID = '%s'" % loot1.get_target_id())
	assert_str(loot1.get_target_id()).is_equal("loot_1")

	var unit2 = auto_free(load("res://Gameplay/targets/unit.gd").new())
	unit2._ready()
	print("DEBUG: unit2 ID = '%s'" % unit2.get_target_id())
	assert_str(unit2.get_target_id()).is_equal("unit_2")

func test_willpower_standardization() -> void:
	var unit = auto_free(load("res://Gameplay/targets/unit.gd").new())
	unit.max_willpower = 50
	assert_int(unit.get_max_willpower()).is_equal(50)

func test_create_move_and_interact_action_for_aid_sets_aid_command() -> void:
	var unit_manager = auto_free(UnitManager.new())
	var actor = auto_free(UNIT_SCENE.new())
	var target = auto_free(UNIT_SCENE.new())
	actor._ready()
	target._ready()
	unit_manager.add_unit(actor, Vector2i(0, 0), true)
	unit_manager.add_unit(target, Vector2i(1, 0), false)

	var base_action = PlayerAction.create(GameConstants.ActionType.AID)
	var final_action = PlayerActionManager.create_move_and_interact_action(
		base_action,
		target,
		{},
		unit_manager,
		2,
		"aid"
	)

	assert_int(final_action.command_id).is_equal(GameConstants.ActionType.AID)
	assert_int(final_action.command_payload.get(GameConstants.Payload.HELPER_INDEX)).is_equal(0)
	assert_int(final_action.command_payload.get(GameConstants.Payload.TARGET_INDEX)).is_equal(1)
	assert_int(final_action.command_payload.get(GameConstants.Payload.ATTRIBUTE_INDEX)).is_equal(2)

func test_create_move_and_interact_action_for_skill_missing_skill_does_not_execute() -> void:
	var unit_manager = auto_free(UnitManager.new())
	var actor = auto_free(UNIT_SCENE.new())
	var target = auto_free(UNIT_SCENE.new())
	actor._ready()
	target._ready()
	unit_manager.add_unit(actor, Vector2i(0, 0), true)
	unit_manager.add_unit(target, Vector2i(1, 0), false)

	var base_action = PlayerAction.create(GameConstants.ActionType.SKILL)
	var final_action = PlayerActionManager.create_move_and_interact_action(
		base_action,
		target,
		{},
		unit_manager,
		0,
		"skill"
	)

	assert_int(final_action.command_id).is_equal(GameConstants.ActionType.NONE)

func test_registry_clear() -> void:
	var target = auto_free(load("res://Gameplay/targets/target.gd").new())
	target._ready()
	var tid = target.get_target_id()

	TargetDiscoveryService.clear_registry()
	assert_object(TargetDiscoveryService.get_target_by_id(tid)).is_null()

func test_debug_complete_convince_sets_half_willpower_and_completes_task() -> void:
	var task_manager = auto_free(TaskManager.new())
	var target = auto_free(load("res://Gameplay/targets/target.gd").new())
	target.base_willpower = 10
	target.willpower = 10
	target._ready()

	var task = Task.new()
	task.id = "convince_task"
	task.event_type = GameConstants.Activity.CONVINCE
	task.owning_faction = GameConstants.Faction.PLAYER
	task.target_id = target.get_target_id()

	var stage = Stage.new()
	stage.active_tasks = [task]
	var objective = Objective.new()
	objective.current_stage = stage

	task_manager.prepare_objective(null, objective)
	task_manager.debug_complete_task(task.id)

	assert_int(target.get_current_willpower()).is_equal(target.get_max_willpower() >> 1)
	assert_int(task.status).is_equal(Task.Status.COMPLETED)

func test_debug_complete_non_convince_sets_zero_willpower_and_completes_task() -> void:
	var task_manager = auto_free(TaskManager.new())
	var target = auto_free(load("res://Gameplay/targets/target.gd").new())
	target.base_willpower = 12
	target.willpower = 12
	target._ready()

	var task = Task.new()
	task.id = "gather_task"
	task.event_type = GameConstants.Activity.GATHER
	task.owning_faction = GameConstants.Faction.PLAYER
	task.target_id = target.get_target_id()

	var stage = Stage.new()
	stage.active_tasks = [task]
	var objective = Objective.new()
	objective.current_stage = stage

	task_manager.prepare_objective(null, objective)
	task_manager.debug_complete_task(task.id)

	assert_int(target.get_current_willpower()).is_equal(0)
	assert_int(task.status).is_equal(Task.Status.COMPLETED)

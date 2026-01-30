extends GdUnitTestSuite

func test_hud_on_command_executed_emits_refresh_on_success() -> void:
	var hud: Hud = auto_free(Hud.new())
	add_child(hud)
	await get_tree().process_frame

	var unit_manager: UnitManager = auto_free(UnitManager.new())
	hud._unit_manager = unit_manager

	var refresh_count := 0
	hud.action_refresh_requested.connect(func(): refresh_count += 1)

	hud.on_command_executed("move_action", CommandResult.success())
	await get_tree().process_frame
	await get_tree().process_frame

	assert_int(refresh_count).is_equal(1)

func test_hud_on_command_executed_skips_refresh_on_failure() -> void:
	var hud: Hud = auto_free(Hud.new())
	add_child(hud)
	await get_tree().process_frame

	var unit_manager: UnitManager = auto_free(UnitManager.new())
	hud._unit_manager = unit_manager

	var refresh_count := 0
	hud.action_refresh_requested.connect(func(): refresh_count += 1)

	hud.on_command_executed("move_action", CommandResult.failed("nope"))
	await get_tree().process_frame
	await get_tree().process_frame

	assert_int(refresh_count).is_equal(0)

extends GdUnitTestSuite

func before_test() -> void:
	# Clear save data and slots
	SaveManager._game_data = {}
	SaveManager.set_value(SaveManager.HARD_SAVE_INDEX_KEY, 0)
	for i in range(SaveManager.HARD_SAVE_SLOTS):
		var path = SaveManager.HARD_SAVE_PATH_TEMPLATE % i
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

func test_hard_save_rotation() -> void:
	# Slot 0
	SaveManager.trigger_hard_save("level_1")
	assert_int(SaveManager.get_value(SaveManager.HARD_SAVE_INDEX_KEY)).is_equal(1)
	assert_bool(FileAccess.file_exists(SaveManager.HARD_SAVE_PATH_TEMPLATE % 0)).is_true()
	
	# Slot 1
	SaveManager.trigger_hard_save("level_2")
	assert_int(SaveManager.get_value(SaveManager.HARD_SAVE_INDEX_KEY)).is_equal(2)
	assert_bool(FileAccess.file_exists(SaveManager.HARD_SAVE_PATH_TEMPLATE % 1)).is_true()
	
	# Slot 2
	SaveManager.trigger_hard_save("level_3")
	assert_int(SaveManager.get_value(SaveManager.HARD_SAVE_INDEX_KEY)).is_equal(0) # Rotated back to 0
	assert_bool(FileAccess.file_exists(SaveManager.HARD_SAVE_PATH_TEMPLATE % 2)).is_true()
	
	# Slot 0 Overwrite
	SaveManager.trigger_hard_save("level_4")
	assert_int(SaveManager.get_value(SaveManager.HARD_SAVE_INDEX_KEY)).is_equal(1)
	
	var metadata = SaveManager.get_hard_save_metadata()
	assert_int(metadata.size()).is_equal(3)

func test_hard_save_metadata() -> void:
	SaveManager.set_value("completed_levels", {"level_0": true})
	SaveManager.set_value("last_completed_level_id", "level_0")
	SaveManager.trigger_hard_save("level_1")
	
	var metadata = SaveManager.get_hard_save_metadata()
	var m = metadata[0]
	assert_str(m.level_id).is_equal("level_1")
	assert_int(m.completed_count).is_equal(1)
	assert_str(m.last_completed).is_equal("level_0")

func test_rollback_on_quit() -> void:
	# 1. Setup world state
	SaveManager.set_value("gold", 100)
	SaveManager.trigger_hard_save("level_1") # Saved slot 0: gold=100
	
	# 2. Enter level and change state
	SaveManager.set_value("gold", 50) # Spent some gold in level
	SaveManager.set_value("is_in_level", true)
	
	# 3. Quit to level select (should rollback)
	var flow = LevelFlowController.new()
	flow.handle_quit_to_level_select()
	
	assert_int(SaveManager.get_value("gold")).is_equal(100) # Rolled back!
	assert_bool(SaveManager.has_resumable_session()).is_false()

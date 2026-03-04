extends GdUnitTestSuite

const SaveManagerScript := preload("res://Autoloads/save_manager.gd")

func test_set_and_get_hometown_skit_shown() -> void:
	var mgr := SaveManagerScript.new()
	var initial_skits := mgr.get_hometown_skits()
	assert_dict(initial_skits).is_empty()

	mgr.set_hometown_skit_shown("res://test_skit.tres", true)
	var updated_skits := mgr.get_hometown_skits()
	assert_bool(updated_skits.has("res://test_skit.tres")).is_true()
	assert_bool(updated_skits["res://test_skit.tres"]).is_true()

func test_set_and_get_leader_unit_name() -> void:
	var mgr := SaveManagerScript.new()
	assert_str(mgr.get_leader_unit_name()).is_empty() # Default

	mgr.set_leader_unit_name("Jane Doe")
	assert_str(mgr.get_leader_unit_name()).is_equal("Jane Doe")

	mgr.set_leader_unit_name("") # Empty name check, should be ignored or keep old, let's see. The code returns early on empty.
	assert_str(mgr.get_leader_unit_name()).is_equal("Jane Doe")

func test_create_and_restore_game_memento() -> void:
	var mgr := SaveManagerScript.new()
	mgr.set_value("test_key", 42)

	var memento := mgr.create_game_memento()
	assert_dict(memento).has_key("test_key")
	assert_int(memento["test_key"]).is_equal(42)

	# Alter value
	mgr.set_value("test_key", 99)
	assert_int(mgr.get_value("test_key")).is_equal(99)

	# Restore
	mgr.restore_game_state(memento)
	assert_int(mgr.get_value("test_key")).is_equal(42)

func test_undo_and_redo_state() -> void:
	var mgr := SaveManagerScript.new()
	mgr.set_value("counter", 0)
	mgr.save_current_state_for_undo() # memento index 0

	mgr.set_value("counter", 1)
	mgr.save_current_state_for_undo() # memento index 1

	assert_int(mgr.get_value("counter")).is_equal(1)

	mgr.undo_state() # reverts to index 0
	assert_int(mgr.get_value("counter")).is_equal(0)

	mgr.redo_state() # advances to index 1
	assert_int(mgr.get_value("counter")).is_equal(1)

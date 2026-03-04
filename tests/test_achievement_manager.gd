extends GdUnitTestSuite

# Tests for achievement_manager.gd autoload — extends Node.
# We instantiate the script directly (not as the autoload), inject achievements
# into the dict, and test unlock_achievement, get_savable_data, load_savable_data.

const AchievementManagerScript := preload("res://Autoloads/achievement_manager.gd")

func _find_achievement_script() -> GDScript:
	# Look for Achievement class script
	var paths := [
		"res://Resources/Achievements/achievement.gd",
		"res://Autoloads/achievement.gd",
		"res://Gameplay/achievement.gd",
	]
	for p in paths:
		if ResourceLoader.exists(p):
			return load(p)
	return null

func _make_manager() -> Node:
	var mgr: Node = AchievementManagerScript.new()
	add_child(mgr)
	return mgr

func _make_achievement(id: String, title: String = "Test Achievement") -> Achievement:
	var a: Achievement = Achievement.new()
	a.id = id
	a.title = title
	a.unlocked = false
	auto_free(a)
	return a

func after_test() -> void:
	for child in get_children():
		if is_instance_valid(child):
			child.queue_free()

# ---------------------------------------------------------------------------
# unlock_achievement
# ---------------------------------------------------------------------------

func test_unlock_achievement_sets_unlocked_true() -> void:
	var mgr: Node = _make_manager()
	var ach: Achievement = _make_achievement("first_blood")
	mgr.achievements["first_blood"] = ach
	var result: bool = mgr.unlock_achievement("first_blood")
	assert_bool(result).is_true()
	assert_bool(ach.unlocked).is_true()

func test_unlock_achievement_emits_signal() -> void:
	var mgr: Node = _make_manager()
	var ach: Achievement = _make_achievement("explorer")
	mgr.achievements["explorer"] = ach
	var monitor := monitor_signals(mgr)
	mgr.unlock_achievement("explorer")
	assert_signal(monitor).is_emitted("achievement_unlocked")

func test_unlock_achievement_returns_false_when_already_unlocked() -> void:
	var mgr: Node = _make_manager()
	var ach: Achievement = _make_achievement("veteran")
	ach.unlocked = true
	mgr.achievements["veteran"] = ach
	var result: bool = mgr.unlock_achievement("veteran")
	assert_bool(result).is_false()

func test_unlock_achievement_returns_false_for_unknown_id() -> void:
	var mgr: Node = _make_manager()
	assert_bool(mgr.unlock_achievement("does_not_exist")).is_false()

func test_unlock_achievement_does_not_emit_signal_if_already_unlocked() -> void:
	var mgr: Node = _make_manager()
	var ach: Achievement = _make_achievement("scout")
	ach.unlocked = true
	mgr.achievements["scout"] = ach
	var monitor := monitor_signals(mgr)
	mgr.unlock_achievement("scout")
	assert_signal(monitor).is_not_emitted("achievement_unlocked")

func test_unlock_achievement_idempotent_on_second_call() -> void:
	var mgr: Node = _make_manager()
	var ach: Achievement = _make_achievement("hero")
	mgr.achievements["hero"] = ach
	mgr.unlock_achievement("hero")
	var second: bool = mgr.unlock_achievement("hero")
	assert_bool(second).is_false()
	assert_bool(ach.unlocked).is_true() # still true

# ---------------------------------------------------------------------------
# get_savable_data
# ---------------------------------------------------------------------------

func test_get_savable_data_returns_only_unlocked_ids() -> void:
	var mgr: Node = _make_manager()
	var a1: Achievement = _make_achievement("win")
	a1.unlocked = true
	var a2: Achievement = _make_achievement("lose")
	a2.unlocked = false
	mgr.achievements["win"] = a1
	mgr.achievements["lose"] = a2
	var data: Dictionary = mgr.get_savable_data()
	assert_that(data.has("unlocked_achievements")).is_true()
	var ids: Array = data["unlocked_achievements"]
	assert_bool(ids.has("win")).is_true()
	assert_bool(ids.has("lose")).is_false()

func test_get_savable_data_empty_when_none_unlocked() -> void:
	var mgr: Node = _make_manager()
	var ach: Achievement = _make_achievement("hidden")
	mgr.achievements["hidden"] = ach
	var data: Dictionary = mgr.get_savable_data()
	assert_int(data["unlocked_achievements"].size()).is_equal(0)

# ---------------------------------------------------------------------------
# load_savable_data
# ---------------------------------------------------------------------------

func test_load_savable_data_marks_matching_achievements_unlocked() -> void:
	var mgr: Node = _make_manager()
	var ach: Achievement = _make_achievement("survivor")
	mgr.achievements["survivor"] = ach
	mgr.load_savable_data({"unlocked_achievements": ["survivor"]})
	assert_bool(ach.unlocked).is_true()

func test_load_savable_data_ignores_unknown_ids_without_crash() -> void:
	var mgr: Node = _make_manager()
	mgr.load_savable_data({"unlocked_achievements": ["no_such_achievement"]})
	# Should not crash, just push_warning
	assert_bool(true).is_true()

func test_load_savable_data_no_key_does_nothing() -> void:
	var mgr: Node = _make_manager()
	var ach: Achievement = _make_achievement("coward")
	mgr.achievements["coward"] = ach
	mgr.load_savable_data({})
	assert_bool(ach.unlocked).is_false()

func test_load_savable_data_round_trip() -> void:
	var mgr: Node = _make_manager()
	var ach: Achievement = _make_achievement("champion")
	mgr.achievements["champion"] = ach
	mgr.unlock_achievement("champion")
	var saved: Dictionary = mgr.get_savable_data()
	# Reset the achievement
	ach.unlocked = false
	mgr.load_savable_data(saved)
	assert_bool(ach.unlocked).is_true()

extends GdUnitTestSuite

# Tests for JournalManager.unlock_entry and unlock_coupled_entry

const JournalManagerScript := preload("res://Autoloads/journal_manager.gd")

func _make_manager() -> JournalManagerScript:
	var jm = JournalManagerScript.new()
	jm._ensure_initialized() # to build journal_data
	return jm

func test_unlock_entry_succeeds() -> void:
	var jm = _make_manager()

	var entry = LevelJournalEntry.new(
		"test_entry", "Test", "Test Content", "topics", "sections", "test", "test_id"
	)
	jm.journal_data.add_entry(entry)

	var monitor = monitor_signals(jm)
	var unlocked = jm.unlock_entry("test_entry")

	assert_bool(unlocked).is_true()
	assert_bool(entry.unlocked).is_true()
	assert_signal(monitor).is_emitted("entry_unlocked")

	# Trying again should return false and not emit signal
	var unlocked2 = jm.unlock_entry("test_entry")
	assert_bool(unlocked2).is_false() # Just prints Already unlocked instead of re-emitting
	# Signal should still have only been emitted once, but we can't easily assert emit count with gdunit asserting is_emitted repeatedly
	# Actually gdunit assert_signal just checks if it happened *at least once*.

func test_unlock_entry_fails_on_missing() -> void:
	var jm = _make_manager()
	var monitor = monitor_signals(jm)

	var unlocked = jm.unlock_entry("missing")
	assert_bool(unlocked).is_false()
	assert_signal(monitor).is_not_emitted("entry_unlocked")

func test_unlock_coupled_entry_creates_and_unlocks() -> void:
	var jm = _make_manager()
	var monitor = monitor_signals(jm)

	jm.unlock_coupled_entry("coupled_1", "my_section", "my_topic", "Some notes", &"")

	var entry = jm.journal_data.get_entry("coupled_1")
	assert_object(entry).is_not_null()
	assert_str(entry.title).is_equal("Coupled_1")
	assert_str(entry.content).is_equal("Some notes")
	assert_bool(entry.unlocked).is_true()
	assert_signal(monitor).is_emitted("entry_unlocked")

	# Calling it again shouldn't re-create or crash, should just assert it's unlocked
	jm.unlock_coupled_entry("coupled_1", "my_section", "my_topic", "Other notes", &"")
	var entry2 = jm.journal_data.get_entry("coupled_1")
	assert_str(entry2.title).is_equal("Coupled_1") # shouldn't override existing title logic in this flow

func test_clear_journal() -> void:
	var jm = _make_manager()
	var monitor = monitor_signals(jm)

	var entry = LevelJournalEntry.new(
		"test_entry", "Test", "Test Content", "topics", "sections", "test", "test_id"
	)
	jm.journal_data.add_entry(entry)
	assert_bool(jm.journal_data.has_entry("test_entry")).is_true()

	jm.clear_journal()

	assert_bool(jm.journal_data.has_entry("test_entry")).is_false()
	assert_signal(monitor).is_emitted("journal_cleared")
	assert_signal(monitor).is_emitted("entry_unlocked")

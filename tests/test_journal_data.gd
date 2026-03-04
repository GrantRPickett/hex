extends GdUnitTestSuite

# Tests for JournalData — a pure Resource with no Node dependencies.
# Covers: add_section, add_topic, add_entry, replace_entry,
#         get_unlocked_topics_in_section, get_unlocked_entries_in_topic,
#         get_all_unlocked_entries

const JournalDataScript := preload("res://Gameplay/narrative/journal/journal_data.gd")
const JournalSectionScript := preload("res://Gameplay/narrative/journal/journal_section.gd")
const JournalTopicScript := preload("res://Gameplay/narrative/journal/journal_topic.gd")
const JournalEntryScript := preload("res://level/level_journal_entry.gd")

var _data: JournalData

func before_test() -> void:
	_data = JournalDataScript.new()
	auto_free(_data)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_section(id: String, title: String = "Section") -> JournalSection:
	var s: JournalSection = JournalSectionScript.new(id, title)
	auto_free(s)
	return s

func _make_topic(id: String, section_id: String, title: String = "Topic") -> JournalTopic:
	var t: JournalTopic = JournalTopicScript.new(id, title, section_id)
	auto_free(t)
	return t

func _make_entry(id: String, topic_id: String, section_id: String = "sec", unlocked: bool = false) -> LevelJournalEntry:
	var e: LevelJournalEntry = JournalEntryScript.new(id, "Entry " + id, "", topic_id, section_id)
	e.unlocked = unlocked
	auto_free(e)
	return e

# ---------------------------------------------------------------------------
# add_section
# ---------------------------------------------------------------------------

func test_add_section_stores_section() -> void:
	var sec: JournalSection = _make_section("lore")
	_data.add_section(sec)
	assert_that(_data.sections.has("lore")).is_true()

func test_add_section_duplicate_id_ignored() -> void:
	var sec1: JournalSection = _make_section("lore", "Lore First")
	var sec2: JournalSection = _make_section("lore", "Lore Second")
	_data.add_section(sec1)
	_data.add_section(sec2)
	# Original should be preserved
	assert_str((_data.sections["lore"] as JournalSection).title).is_equal("Lore First")

# ---------------------------------------------------------------------------
# add_topic
# ---------------------------------------------------------------------------

func test_add_topic_stores_topic() -> void:
	_data.add_section(_make_section("sec"))
	var topic: JournalTopic = _make_topic("t1", "sec")
	_data.add_topic(topic)
	assert_that(_data.topics.has("t1")).is_true()

func test_add_topic_auto_creates_missing_section() -> void:
	# No section added first
	var topic: JournalTopic = _make_topic("t1", "auto_sec")
	_data.add_topic(topic)
	assert_that(_data.sections.has("auto_sec")).is_true()

func test_add_topic_registers_in_section() -> void:
	_data.add_section(_make_section("sec"))
	var topic: JournalTopic = _make_topic("t1", "sec")
	_data.add_topic(topic)
	var sec := _data.sections["sec"] as JournalSection
	assert_that("t1" in sec.topic_ids).is_true()

func test_add_topic_duplicate_ignored() -> void:
	_data.add_section(_make_section("sec"))
	var t1: JournalTopic = _make_topic("t1", "sec", "First")
	var t2: JournalTopic = _make_topic("t1", "sec", "Second")
	_data.add_topic(t1)
	_data.add_topic(t2)
	assert_str((_data.topics["t1"] as JournalTopic).title).is_equal("First")

# ---------------------------------------------------------------------------
# add_entry
# ---------------------------------------------------------------------------

func test_add_entry_stores_entry() -> void:
	_data.add_section(_make_section("sec"))
	_data.add_topic(_make_topic("topic1", "sec"))
	var entry: LevelJournalEntry = _make_entry("e1", "topic1", "sec")
	_data.add_entry(entry)
	assert_that(_data.entries.has("e1")).is_true()

func test_add_entry_auto_creates_topic_when_missing() -> void:
	var entry: LevelJournalEntry = _make_entry("e1", "auto_topic", "auto_sec")
	_data.add_entry(entry)
	assert_that(_data.topics.has("auto_topic")).is_true()

func test_add_entry_registers_in_topic() -> void:
	_data.add_section(_make_section("sec"))
	_data.add_topic(_make_topic("t1", "sec"))
	var entry: LevelJournalEntry = _make_entry("e1", "t1", "sec")
	_data.add_entry(entry)
	var topic := _data.topics["t1"] as JournalTopic
	assert_that("e1" in topic.entry_ids).is_true()

func test_add_entry_duplicate_ignored() -> void:
	_data.add_section(_make_section("sec"))
	_data.add_topic(_make_topic("t1", "sec"))
	var e1: LevelJournalEntry = _make_entry("e1", "t1", "sec")
	var e2: LevelJournalEntry = _make_entry("e1", "t1", "sec")
	e2.title = "Duplicate"
	_data.add_entry(e1)
	_data.add_entry(e2)
	assert_str((_data.entries["e1"] as LevelJournalEntry).title).is_equal("Entry e1")

# ---------------------------------------------------------------------------
# replace_entry
# ---------------------------------------------------------------------------

func test_replace_entry_updates_existing() -> void:
	_data.add_section(_make_section("sec"))
	_data.add_topic(_make_topic("t1", "sec"))
	var original: LevelJournalEntry = _make_entry("e1", "t1", "sec")
	_data.add_entry(original)

	var updated: LevelJournalEntry = _make_entry("e1", "t1", "sec")
	updated.title = "Updated Title"
	_data.replace_entry(updated)

	assert_str((_data.entries["e1"] as LevelJournalEntry).title).is_equal("Updated Title")

func test_replace_entry_adds_when_not_yet_present() -> void:
	_data.add_section(_make_section("sec"))
	_data.add_topic(_make_topic("t1", "sec"))
	var entry: LevelJournalEntry = _make_entry("new_e", "t1", "sec")
	_data.replace_entry(entry)
	assert_that(_data.entries.has("new_e")).is_true()

func test_replace_entry_removes_from_old_topic() -> void:
	_data.add_section(_make_section("sec"))
	_data.add_topic(_make_topic("t1", "sec"))
	_data.add_topic(_make_topic("t2", "sec"))
	var entry: LevelJournalEntry = _make_entry("e1", "t1", "sec")
	_data.add_entry(entry)

	# Re-assign to t2
	var updated: LevelJournalEntry = _make_entry("e1", "t2", "sec")
	_data.replace_entry(updated)

	var old_topic := _data.topics["t1"] as JournalTopic
	assert_that("e1" in old_topic.entry_ids).is_false()
	var new_topic := _data.topics["t2"] as JournalTopic
	assert_that("e1" in new_topic.entry_ids).is_true()

# ---------------------------------------------------------------------------
# get_unlocked_topics_in_section
# ---------------------------------------------------------------------------

func test_get_unlocked_topics_empty_when_no_entries_unlocked() -> void:
	_data.add_section(_make_section("sec"))
	_data.add_topic(_make_topic("t1", "sec"))
	var entry: LevelJournalEntry = _make_entry("e1", "t1", "sec", false)
	_data.add_entry(entry)

	var result := _data.get_unlocked_topics_in_section("sec")
	assert_int(result.size()).is_equal(0)

func test_get_unlocked_topics_returns_topic_with_unlocked_entry() -> void:
	_data.add_section(_make_section("sec"))
	_data.add_topic(_make_topic("t1", "sec"))
	var entry: LevelJournalEntry = _make_entry("e1", "t1", "sec", true)
	_data.add_entry(entry)

	var result := _data.get_unlocked_topics_in_section("sec")
	assert_int(result.size()).is_equal(1)
	assert_str((result[0] as JournalTopic).id).is_equal("t1")

func test_get_unlocked_topics_empty_for_missing_section() -> void:
	var result := _data.get_unlocked_topics_in_section("nonexistent")
	assert_int(result.size()).is_equal(0)

# ---------------------------------------------------------------------------
# get_unlocked_entries_in_topic
# ---------------------------------------------------------------------------

func test_get_unlocked_entries_returns_only_unlocked() -> void:
	_data.add_section(_make_section("sec"))
	_data.add_topic(_make_topic("t1", "sec"))
	var locked: LevelJournalEntry = _make_entry("e_locked", "t1", "sec", false)
	var unlocked: LevelJournalEntry = _make_entry("e_unlocked", "t1", "sec", true)
	_data.add_entry(locked)
	_data.add_entry(unlocked)

	var result := _data.get_unlocked_entries_in_topic("t1")
	assert_int(result.size()).is_equal(1)
	assert_str((result[0] as LevelJournalEntry).id).is_equal("e_unlocked")

func test_get_unlocked_entries_empty_for_missing_topic() -> void:
	var result := _data.get_unlocked_entries_in_topic("ghost_topic")
	assert_int(result.size()).is_equal(0)

# ---------------------------------------------------------------------------
# get_all_unlocked_entries
# ---------------------------------------------------------------------------

func test_get_all_unlocked_entries_empty_when_none_unlocked() -> void:
	_data.add_section(_make_section("sec"))
	_data.add_topic(_make_topic("t1", "sec"))
	_data.add_entry(_make_entry("e1", "t1", "sec", false))
	_data.add_entry(_make_entry("e2", "t1", "sec", false))

	var result := _data.get_all_unlocked_entries()
	assert_int(result.size()).is_equal(0)

func test_get_all_unlocked_entries_returns_all_unlocked_across_topics() -> void:
	_data.add_section(_make_section("sec"))
	_data.add_topic(_make_topic("t1", "sec"))
	_data.add_topic(_make_topic("t2", "sec"))
	_data.add_entry(_make_entry("e1", "t1", "sec", true))
	_data.add_entry(_make_entry("e2", "t2", "sec", true))
	_data.add_entry(_make_entry("e3", "t2", "sec", false))

	var result := _data.get_all_unlocked_entries()
	assert_int(result.size()).is_equal(2)
	assert_that(result.has("e1")).is_true()
	assert_that(result.has("e2")).is_true()
	assert_that(result.has("e3")).is_false()

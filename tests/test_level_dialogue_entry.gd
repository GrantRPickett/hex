extends GdUnitTestSuite

# Tests for LevelDialogueEntry.get_flag_id()
# Pure Resource — no Node/scene dependencies.

const EntryScript := preload("res://level/level_dialogue_entry.gd")

func test_get_flag_id_uses_flag_name_when_set() -> void:
	var entry: LevelDialogueEntry = EntryScript.new()
	auto_free(entry)
	entry.flag_name = &"my_custom_flag"
	entry.dialogue_resource_path = "res://some/dialogue.dialogue"
	entry.initiator_name = &"Alice"
	entry.partner_name = &"Bob"
	assert_str(String(entry.get_flag_id())).is_equal("my_custom_flag")

func test_get_flag_id_falls_back_to_resource_path() -> void:
	var entry: LevelDialogueEntry = EntryScript.new()
	auto_free(entry)
	entry.flag_name = &""
	entry.dialogue_resource_path = "res://some/path.dialogue"
	entry.initiator_name = &"Alice"
	entry.partner_name = &"Bob"
	assert_str(String(entry.get_flag_id())).is_equal("res://some/path.dialogue")

func test_get_flag_id_falls_back_to_name_pair() -> void:
	var entry: LevelDialogueEntry = EntryScript.new()
	auto_free(entry)
	entry.flag_name = &""
	entry.dialogue_resource_path = ""
	entry.initiator_name = &"Alice"
	entry.partner_name = &"Bob"
	assert_str(String(entry.get_flag_id())).is_equal("Alice_Bob_dialogue")

func test_get_flag_id_returns_hash_when_all_empty() -> void:
	var entry: LevelDialogueEntry = EntryScript.new()
	auto_free(entry)
	entry.flag_name = &""
	entry.dialogue_resource_path = ""
	entry.initiator_name = &""
	entry.partner_name = &""
	# Should produce a non-empty fallback (hash-based)
	var result := String(entry.get_flag_id())
	assert_str(result).is_not_empty()

func test_get_flag_id_name_pair_requires_both_names() -> void:
	# Only initiator set — should fall through to hash
	var entry: LevelDialogueEntry = EntryScript.new()
	auto_free(entry)
	entry.flag_name = &""
	entry.dialogue_resource_path = ""
	entry.initiator_name = &"Alice"
	entry.partner_name = &""
	# partner_name is empty so the name-pair branch shouldn't match
	var result := String(entry.get_flag_id())
	# Should NOT produce "Alice__dialogue"  — should hit hash fallback
	assert_str(result).is_not_equal("Alice__dialogue")

func test_get_flag_id_priority_flag_name_over_path() -> void:
	var entry: LevelDialogueEntry = EntryScript.new()
	auto_free(entry)
	entry.flag_name = &"explicit_flag"
	entry.dialogue_resource_path = "res://other.dialogue"
	# flag_name takes priority
	assert_str(String(entry.get_flag_id())).is_equal("explicit_flag")

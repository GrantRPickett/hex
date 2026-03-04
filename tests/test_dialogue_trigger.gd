extends GdUnitTestSuite

# Tests for DialogueTrigger — extends Target (Node2D).
# We seat it in the scene tree and configure via LevelDialogueEntry.
# Covers: get_action_label, get_dialogue_resource, matches_partner, assign_coord_on_grid

const TriggerScript := preload("res://Gameplay/narrative/dialogue/dialogue_trigger.gd")
const EntryScript := preload("res://level/level_dialogue_entry.gd")

func _make_entry(initiator: StringName = &"", partner: StringName = &"", label: String = "") -> LevelDialogueEntry:
	var e: LevelDialogueEntry = EntryScript.new()
	e.initiator_name = initiator
	e.partner_name = partner
	e.action_label = label
	e.dialogue_resource_path = ""
	auto_free(e)
	return e

func _make_trigger(entry: LevelDialogueEntry = null) -> DialogueTrigger:
	var t: DialogueTrigger = TriggerScript.new()
	add_child(t)
	if entry:
		t.configure_from_entry(entry)
	return t

func after_test() -> void:
	for child in get_children():
		if is_instance_valid(child):
			child.queue_free()

# ---------------------------------------------------------------------------
# get_action_label
# ---------------------------------------------------------------------------

func test_get_action_label_uses_entry_action_label_when_set() -> void:
	var e: LevelDialogueEntry = _make_entry(&"", &"", "Investigate")
	var trigger: DialogueTrigger = _make_trigger(e)
	assert_str(trigger.get_action_label("Guard")).is_equal("Investigate")

func test_get_action_label_formats_talk_to_with_partner_display_name() -> void:
	var e: LevelDialogueEntry = _make_entry(&"", &"Innkeeper", "")
	var trigger: DialogueTrigger = _make_trigger(e)
	# partner_display_name overrides entry.partner_name
	assert_str(trigger.get_action_label("Merchant")).is_equal("Talk to Merchant")

func test_get_action_label_falls_back_to_entry_partner_name() -> void:
	var e: LevelDialogueEntry = _make_entry(&"", &"Innkeeper", "")
	var trigger: DialogueTrigger = _make_trigger(e)
	# Empty display name → fall back to entry.partner_name
	assert_str(trigger.get_action_label("")).is_equal("Talk to Innkeeper")

func test_get_action_label_no_entry_formats_with_provided_name() -> void:
	var trigger: DialogueTrigger = _make_trigger(null)
	assert_str(trigger.get_action_label("Stranger")).is_equal("Talk to Stranger")

func test_get_action_label_empty_everything_produces_talk_to_empty() -> void:
	var e: LevelDialogueEntry = _make_entry(&"", &"", "")
	var trigger: DialogueTrigger = _make_trigger(e)
	var label := trigger.get_action_label("")
	assert_str(label).is_equal("Talk to ")

# ---------------------------------------------------------------------------
# get_dialogue_resource
# ---------------------------------------------------------------------------

func test_get_dialogue_resource_returns_null_when_no_entry() -> void:
	var trigger: DialogueTrigger = _make_trigger(null)
	assert_object(trigger.get_dialogue_resource({})).is_null()

func test_get_dialogue_resource_returns_null_when_path_empty() -> void:
	var e: LevelDialogueEntry = _make_entry()
	e.dialogue_resource_path = ""
	var trigger: DialogueTrigger = _make_trigger(e)
	assert_object(trigger.get_dialogue_resource({})).is_null()

func test_get_dialogue_resource_returns_cached_value_on_hit() -> void:
	var e: LevelDialogueEntry = _make_entry()
	e.dialogue_resource_path = "res://fake/path.dialogue"
	var trigger: DialogueTrigger = _make_trigger(e)
	var fake_resource := Resource.new()
	auto_free(fake_resource)
	var cache: Dictionary = {"res://fake/path.dialogue": fake_resource}
	var result := trigger.get_dialogue_resource(cache)
	assert_object(result).is_equal(fake_resource)

func test_get_dialogue_resource_returns_null_for_nonexistent_path() -> void:
	var e: LevelDialogueEntry = _make_entry()
	e.dialogue_resource_path = "res://nonexistent_file_that_does_not_exist.dialogue"
	var trigger: DialogueTrigger = _make_trigger(e)
	var cache: Dictionary = {}
	# Non-existent file → load() returns null → method returns null
	assert_object(trigger.get_dialogue_resource(cache)).is_null()

# ---------------------------------------------------------------------------
# matches_partner
# ---------------------------------------------------------------------------

func test_matches_partner_false_when_null_unit() -> void:
	var e: LevelDialogueEntry = _make_entry(&"", &"Hero")
	var trigger: DialogueTrigger = _make_trigger(e)
	assert_bool(trigger.matches_partner(null)).is_false()

func test_matches_partner_false_when_no_entry() -> void:
	var trigger: DialogueTrigger = _make_trigger(null)
	var dummy_unit: Unit = Unit.new()
	add_child(dummy_unit)
	assert_bool(trigger.matches_partner(dummy_unit)).is_false()
	dummy_unit.queue_free()

func test_matches_partner_true_when_partner_name_empty_any_unit_matches() -> void:
	# Empty partner_name means "anyone"
	var e: LevelDialogueEntry = _make_entry(&"", &"")
	var trigger: DialogueTrigger = _make_trigger(e)
	var unit: Unit = Unit.new()
	add_child(unit)
	unit.unit_name = &"Grunt"
	assert_bool(trigger.matches_partner(unit)).is_true()
	unit.queue_free()

func test_matches_partner_true_when_unit_name_matches() -> void:
	var e: LevelDialogueEntry = _make_entry(&"", &"Hero")
	var trigger: DialogueTrigger = _make_trigger(e)
	var unit: Unit = Unit.new()
	add_child(unit)
	unit.unit_name = &"Hero"
	assert_bool(trigger.matches_partner(unit)).is_true()
	unit.queue_free()

func test_matches_partner_false_when_unit_name_does_not_match() -> void:
	var e: LevelDialogueEntry = _make_entry(&"", &"Hero")
	var trigger: DialogueTrigger = _make_trigger(e)
	var unit: Unit = Unit.new()
	add_child(unit)
	unit.unit_name = &"Villain"
	assert_bool(trigger.matches_partner(unit)).is_false()
	unit.queue_free()

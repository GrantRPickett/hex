extends GdUnitTestSuite

# Tests for DialogueTriggerGroup — pure RefCounted, no Node/scene deps.
# Covers: register_trigger, mark_seen

const GroupScript := preload("res://Gameplay/narrative/dialogue/dialogue_trigger_group.gd")

# Minimal stand-in for a DialogueTrigger with mark_seen / reset_seen support.
class FakeTrigger extends RefCounted:
	var seen := false
	var mark_from_group_calls := 0

	func mark_seen(from_group := false) -> void:
		if seen:
			return
		seen = true
		if from_group:
			mark_from_group_calls += 1

	func reset_seen() -> void:
		seen = false

# ---------------------------------------------------------------------------
# register_trigger
# ---------------------------------------------------------------------------

func test_register_trigger_adds_member() -> void:
	var group: DialogueTriggerGroup = GroupScript.new(&"grp1")
	auto_free(group)
	var trigger: FakeTrigger = FakeTrigger.new()
	group.register_trigger(trigger)
	# Verify the trigger was registered by confirming mark_seen propagates to it
	group.mark_seen()
	assert_bool(trigger.seen).is_true()

func test_register_trigger_null_is_ignored() -> void:
	var group: DialogueTriggerGroup = GroupScript.new(&"grp1")
	auto_free(group)
	group.register_trigger(null) # Should not crash; _members stays empty
	assert_that(group.seen).is_false()

func test_register_trigger_duplicate_not_added_twice() -> void:
	var group: DialogueTriggerGroup = GroupScript.new(&"grp1")
	auto_free(group)
	var trigger: FakeTrigger = FakeTrigger.new()
	group.register_trigger(trigger)
	group.register_trigger(trigger)
	# Mark seen and verify trigger.mark_from_group_calls == 1, not 2
	group.mark_seen()
	assert_int(trigger.mark_from_group_calls).is_equal(1)

func test_register_trigger_when_group_already_seen_calls_mark_seen_immediately() -> void:
	var group: DialogueTriggerGroup = GroupScript.new(&"grp1")
	auto_free(group)
	group.mark_seen() # group is now seen
	var late_trigger: FakeTrigger = FakeTrigger.new()
	group.register_trigger(late_trigger)
	# Late-registered trigger should immediately be marked seen
	assert_bool(late_trigger.seen).is_true()

# ---------------------------------------------------------------------------
# mark_seen
# ---------------------------------------------------------------------------

func test_mark_seen_sets_group_seen() -> void:
	var group: DialogueTriggerGroup = GroupScript.new(&"grp_a")
	auto_free(group)
	assert_bool(group.seen).is_false()
	group.mark_seen()
	assert_bool(group.seen).is_true()

func test_mark_seen_propagates_to_all_members() -> void:
	var group: DialogueTriggerGroup = GroupScript.new(&"grp_a")
	auto_free(group)
	var t1: FakeTrigger = FakeTrigger.new()
	var t2: FakeTrigger = FakeTrigger.new()
	group.register_trigger(t1)
	group.register_trigger(t2)
	group.mark_seen()
	assert_bool(t1.seen).is_true()
	assert_bool(t2.seen).is_true()

func test_mark_seen_idempotent() -> void:
	var group: DialogueTriggerGroup = GroupScript.new(&"grp_a")
	auto_free(group)
	var trigger: FakeTrigger = FakeTrigger.new()
	group.register_trigger(trigger)
	group.mark_seen()
	group.mark_seen() # Second call should be a no-op
	assert_int(trigger.mark_from_group_calls).is_equal(1)

func test_reset_clears_group_and_members() -> void:
	var group: DialogueTriggerGroup = GroupScript.new(&"grp_a")
	auto_free(group)
	var trigger: FakeTrigger = FakeTrigger.new()
	group.register_trigger(trigger)
	group.mark_seen()
	assert_bool(group.seen).is_true()
	group.reset()
	assert_bool(group.seen).is_false()
	assert_bool(trigger.seen).is_false()

extends GdUnitTestSuite

const DialogueTriggerEvaluatorClass = preload("res://Gameplay/narrative/dialogue/dialogue_trigger_evaluator.gd")
const DialogueTriggerClass = preload("res://Gameplay/narrative/dialogue/dialogue_trigger.gd")
const Stubs = preload("res://tests/fixtures/test_stubs.gd")
const LevelDialogueEntryClass = preload("res://level/level_dialogue_entry.gd")

func test_is_trigger_available() -> void:
	var eval = auto_free(DialogueTriggerEvaluatorClass.new())
	var trigger = auto_free(DialogueTriggerClass.new())
	var entry = LevelDialogueEntryClass.new()
	entry.dialogue_resource_path = "test_dialogue"
	entry.repeatable = false
	trigger.configure_from_entry(entry)
	trigger.seen = false

	assert_bool(eval.is_trigger_available(trigger, StringName(""))).is_true()
	assert_bool(eval.is_trigger_available(trigger, StringName("test_dialogue"))).is_false()

	trigger.seen = true
	# Repeatable is set on entry
	entry.repeatable = false
	assert_bool(eval.is_trigger_available(trigger, StringName(""))).is_false()
	
	entry.repeatable = true
	assert_bool(eval.is_trigger_available(trigger, StringName(""))).is_true()

func test_collect_partner_and_initiator_indices() -> void:
	var eval = auto_free(DialogueTriggerEvaluatorClass.new())
	var um = Stubs.FakeUnitManager.new()
	eval.setup(um, 1)

	var t1 = auto_free(DialogueTriggerClass.new())
	var e1 = LevelDialogueEntryClass.new()
	e1.dialogue_resource_path = "t1"
	t1.configure_from_entry(e1)

	var r1 = eval.collect_partner_indices(t1, -1, Vector2i.ZERO)
	assert_array(r1).is_empty()

	var r2 = eval.collect_initiator_indices(t1, -1, Vector2i.ZERO)
	assert_array(r2).is_empty()

func test_build_dialogue_action() -> void:
	var eval = auto_free(DialogueTriggerEvaluatorClass.new())
	var trigger = auto_free(DialogueTriggerClass.new())
	var entry = LevelDialogueEntryClass.new()
	entry.dialogue_resource_path = "dialogue_id"
	entry.action_hint = "hint"
	trigger.configure_from_entry(entry)
	var action = eval.build_dialogue_action(trigger, 0, 1, "talk to bob")

	assert_int(action.type).is_equal(UnitAction.Type.TALK)
	assert_str(action.label).is_equal("talk to bob")
	assert_str(action.dialogue_id).is_equal("dialogue_id")
	assert_int(action.initiator_index).is_equal(0)
	assert_int(action.target_index).is_equal(1)
	assert_str(action.hint).is_equal("hint")

func test_set_grid_axis() -> void:
	var eval = auto_free(DialogueTriggerEvaluatorClass.new())
	eval.set_grid_axis(0)
	assert_int(eval._grid_axis).is_equal(0)

extends GdUnitTestSuite

const DialogueTriggerEvaluatorClass = preload("res://Gameplay/narrative/dialogue/dialogue_trigger_evaluator.gd")
const DialogueTriggerClass = preload("res://Gameplay/narrative/dialogue/dialogue_trigger.gd")
const Stubs = preload("res://tests/fixtures/test_stubs.gd")

func test_is_trigger_available() -> void:
	var eval = auto_free(DialogueTriggerEvaluatorClass.new())
	var trigger = auto_free(DialogueTriggerClass.new())

	trigger.dialogue_file = "test_dialogue"
	trigger.seen = false

	assert_bool(eval.is_trigger_available(trigger, "")).is_true()
	assert_bool(eval.is_trigger_available(trigger, "test_dialogue")).is_false()

	trigger.seen = true
	trigger.repeatable = false
	assert_bool(eval.is_trigger_available(trigger, "")).is_false()

	trigger.repeatable = true
	assert_bool(eval.is_trigger_available(trigger, "")).is_true()

func test_collect_partner_and_initiator_indices() -> void:
	var eval = auto_free(DialogueTriggerEvaluatorClass.new())
	var um = Stubs.FakeUnitManager.new()
	eval.setup(um, 1)

	var t1 = auto_free(DialogueTriggerClass.new())
	t1.dialogue_file = "t1"

	var r1 = eval.collect_partner_indices(t1, -1, Vector2i.ZERO)
	assert_array(r1).is_empty()

	var r2 = eval.collect_initiator_indices(t1, -1, Vector2i.ZERO)
	assert_array(r2).is_empty()

func test_build_dialogue_action() -> void:
	var eval = auto_free(DialogueTriggerEvaluatorClass.new())
	var trigger = auto_free(DialogueTriggerClass.new())
	trigger.dialogue_file = "dialogue_id"
	trigger.action_hint = "hint"
	var action = eval.build_dialogue_action(trigger, 0, 1, "talk to bob")

	assert_str(action.get("type")).is_equal("talk")
	assert_str(action.get("label")).is_equal("talk to bob")
	assert_str(action.get("dialogue_id")).is_equal("dialogue_id")
	assert_int(action.get("initiator_index")).is_equal(0)
	assert_int(action.get("target_index")).is_equal(1)
	assert_str(action.get("hint")).is_equal("hint")

func test_set_grid_axis() -> void:
	var eval = auto_free(DialogueTriggerEvaluatorClass.new())
	eval.set_grid_axis(0)
	assert_int(eval._grid_axis).is_equal(0)

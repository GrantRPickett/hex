extends GdUnitTestSuite

# FORCE_IMPORT_TIMESTAMP: 2026-03-11 16:15:00

const LevelDialogueEntryClass = preload("res://level/level_dialogue_entry.gd")

func test_is_trigger_available() -> void:
	var evaluator: DialogueTriggerEvaluator = DialogueTriggerEvaluator.new()
	var trigger: DialogueTrigger = DialogueTrigger.new()
	var entry: LevelDialogueEntryClass = LevelDialogueEntryClass.new()
	trigger.entry = entry
	
	# Current API for is_trigger_available(trigger, partner, initiator)
	assert_bool(evaluator.is_trigger_available(trigger, StringName(""))).is_true()

	trigger.mark_seen()
	assert_bool(evaluator.is_trigger_available(trigger, StringName(""))).is_false()

func test_collect_partner_and_initiator_indices() -> void:
	var evaluator: DialogueTriggerEvaluator = DialogueTriggerEvaluator.new()
	var trigger: DialogueTrigger = DialogueTrigger.new()
	var entry: LevelDialogueEntryClass = LevelDialogueEntryClass.new()
	entry.partner_name = &"Partner"
	entry.initiator_name = &"Initiator"
	trigger.entry = entry

	# We need a UnitManager for these tests to work if they use it
	# However, DialogueTriggerEvaluator methods take UnitManager in setup()
	# Let's mock a simple UnitManager
	var unit_manager: UnitManager = auto_free(UnitManager.new())
	evaluator.setup(unit_manager, 0)

	# Test methods collect_partner_indices and collect_initiator_indices
	assert_array(evaluator.collect_partner_indices(trigger, 0, Vector2i.ZERO)).is_empty()
	assert_array(evaluator.collect_initiator_indices(trigger, 0, Vector2i.ZERO)).is_empty()

func test_build_dialogue_action() -> void:
	var evaluator: DialogueTriggerEvaluator = DialogueTriggerEvaluator.new()
	var trigger: DialogueTrigger = DialogueTrigger.new()
	var entry: LevelDialogueEntryClass = LevelDialogueEntryClass.new()
	trigger.entry = entry

	# Current API for build_dialogue_action(trigger, partner_index, initiator_index, initiator_display_name)
	var action = evaluator.build_dialogue_action(trigger, 0, 1, "Leader")
	assert_object(action).is_not_null()
	assert_str(action.get_label()).is_not_empty()

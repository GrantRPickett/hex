extends GdUnitTestSuite

## Verification for CombatFeedbackService Adverb Map Integration

func test_adverb_loading_and_lookup() -> void:
	# In headless mode without translation project loaded, adverbs securely return ""
	var adverb = CombatFeedbackService.get_adverb(GameConstants.AttributeIndex.SHINE, "convince")
	assert_str(adverb).is_equal("")
	
	adverb = CombatFeedbackService.get_adverb(GameConstants.AttributeIndex.GUSTO, "fight")
	assert_str(adverb).is_equal("")
	
	adverb = CombatFeedbackService.get_adverb(GameConstants.AttributeIndex.GRIT, "aid")
	assert_str(adverb).is_equal("")
	
	# Test invalid mapping
	adverb = CombatFeedbackService.get_adverb(GameConstants.AttributeIndex.SHINE, "non_existent_action")
	assert_str(adverb).is_equal("")


func test_action_past_tense_lookup() -> void:
	assert_str(CombatFeedbackService.get_action_past_tense("fight")).is_equal("verb.fought")
	assert_str(CombatFeedbackService.get_action_past_tense("convince")).is_equal("verb.convinced")
	assert_str(CombatFeedbackService.get_action_past_tense("gather")).is_equal("verb.gathered")
	assert_str(CombatFeedbackService.get_action_past_tense("disarm")).is_equal("verb.disarmed")
	assert_str(CombatFeedbackService.get_action_past_tense("aid")).is_equal("verb.encouraged")
	assert_str(CombatFeedbackService.get_action_past_tense("unknown")).is_equal("verb.used")

func test_formatted_action_phrase() -> void:
	# In headless, adverb returns "", so get_formatted_action should just return the verb key
	var phrase1 = CombatFeedbackService.get_formatted_action(GameConstants.AttributeIndex.SHINE, "convince")
	assert_str(phrase1).is_equal("verb.convinced")
	
	var phrase2 = CombatFeedbackService.get_formatted_action(GameConstants.AttributeIndex.SHINE, "non_existent_action")
	assert_str(phrase2).is_equal("verb.used")



	# Verify that it doesn't crash if the map is already loaded or called multiple times
	CombatFeedbackService.get_adverb(GameConstants.AttributeIndex.FOCUS, "explore")
	var adverb = CombatFeedbackService.get_adverb(GameConstants.AttributeIndex.FOCUS, "explore")
	assert_str(adverb).is_equal("thoroughly")

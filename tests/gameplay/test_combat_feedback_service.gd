extends GdUnitTestSuite

## Verification for LocalizationGrammar adverb/verb/phrase functions.
## In headless GdUnit4, TranslationServer returns the key unchanged,
## so we assert against the fallback key string behaviour.

func test_adver_translation_loaded_in_headless() -> void:
	var adverb = LocalizationGrammar.get_adverb(GameConstants.AttributeIndex.SHINE, "convince")
	assert_str(adverb).contains("charismatically")

	adverb = LocalizationGrammar.get_adverb(GameConstants.AttributeIndex.GUSTO, "fight")
	assert_str(adverb).contains("fiercely")

	# Unknown action should return "" because string is equal to key
	adverb = LocalizationGrammar.get_adverb(GameConstants.AttributeIndex.SHINE, "non_existent_action")
	assert_str(adverb).is_equal("")


func test_action_past_tense_returns_translation() -> void:
	assert_str(LocalizationGrammar.get_action_past_tense("fight")).contains("fought")
	assert_str(LocalizationGrammar.get_action_past_tense("convince")).contains("convinced")
	assert_str(LocalizationGrammar.get_action_past_tense("gather")).contains("gathered")
	assert_str(LocalizationGrammar.get_action_past_tense("disarm")).contains("disarmed")
	assert_str(LocalizationGrammar.get_action_past_tense("encouraged")).contains("encouraged")
	assert_str(LocalizationGrammar.get_action_past_tense("unknown")).contains("used")


func test_build_action_phrase_translates() -> void:
	var phrase = LocalizationGrammar.build_action_phrase(GameConstants.AttributeIndex.SHINE, "convince")
	assert_str(phrase).contains("charismatically")
	assert_str(phrase).contains("convinced")

	phrase = LocalizationGrammar.build_action_phrase(GameConstants.AttributeIndex.SHINE, "non_existent_action")
	assert_str(phrase).contains("used")


func test_format_feedback_key_passthrough() -> void:
	# In headless, format_feedback returns the raw template key with placeholders replaced
	# because TranslationServer.translate returns the key itself.
	var result = LocalizationGrammar.format_feedback(
		"log.combat.action_used", "Alice", "Bob", "Shine", 5
	)
	# Template key returned as-is, .format() substitutes placeholders
	assert_str(result).contains("Alice")
	assert_str(result).contains("Bob")

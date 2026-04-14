extends GdUnitTestSuite

## Verification for LocalizationGrammar adverb/verb/phrase functions.
## In headless GdUnit4, TranslationServer returns the key unchanged,
## so we assert against the fallback key string behaviour.

func test_adverb_returns_empty_when_no_translation() -> void:
	# In headless mode without the translation CSV loaded, tr() returns the key.
	# LocalizationGrammar.get_adverb treats key==translated as "missing", returns "".
	var adverb = LocalizationGrammar.get_adverb(GameConstants.AttributeIndex.SHINE, "convince")
	assert_str(adverb).is_equal("")

	adverb = LocalizationGrammar.get_adverb(GameConstants.AttributeIndex.GUSTO, "fight")
	assert_str(adverb).is_equal("")

	# Unknown action should also return ""
	adverb = LocalizationGrammar.get_adverb(GameConstants.AttributeIndex.SHINE, "non_existent_action")
	assert_str(adverb).is_equal("")


func test_action_past_tense_returns_key_in_headless() -> void:
	# TranslationServer.translate returns the raw key in headless.
	# get_action_past_tense falls back to "verb.used" only when key itself is unknown.
	assert_str(LocalizationGrammar.get_action_past_tense("fight")).is_equal("verb.fought")
	assert_str(LocalizationGrammar.get_action_past_tense("convince")).is_equal("verb.convinced")
	assert_str(LocalizationGrammar.get_action_past_tense("gather")).is_equal("verb.gathered")
	assert_str(LocalizationGrammar.get_action_past_tense("disarm")).is_equal("verb.disarmed")
	assert_str(LocalizationGrammar.get_action_past_tense("encouraged")).is_equal("verb.encouraged")
	assert_str(LocalizationGrammar.get_action_past_tense("unknown")).is_equal("verb.used")


func test_build_action_phrase_headless() -> void:
	# In headless: adverb="" so phrase should just be the verb key
	var phrase = LocalizationGrammar.build_action_phrase(GameConstants.AttributeIndex.SHINE, "convince")
	assert_str(phrase).is_equal("verb.convinced")

	phrase = LocalizationGrammar.build_action_phrase(GameConstants.AttributeIndex.SHINE, "non_existent_action")
	assert_str(phrase).is_equal("verb.used")


func test_format_feedback_key_passthrough() -> void:
	# In headless, format_feedback returns the raw template key with placeholders replaced
	# because TranslationServer.translate returns the key itself.
	var result = LocalizationGrammar.format_feedback(
		"log.combat.action_used", "Alice", "Bob", "Shine", 5
	)
	# Template key returned as-is, .format() substitutes placeholders
	assert_str(result).contains("Alice")
	assert_str(result).contains("Bob")

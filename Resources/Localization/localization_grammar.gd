class_name LocalizationGrammar
extends RefCounted

## Utility for managing language-dependent grammar and structural combinations.

## Retrieves translation string for adverb
static func get_adverb(attr_idx: int, action_key: String) -> String:
	var attr_name = GameConstants.get_attribute_name(attr_idx).to_lower()
	var key = "adverb." + attr_name + "." + action_key.to_lower()
	var translated = TranslationServer.translate(StringName(key))
	if translated == StringName(key):
		return ""
	return str(translated)

## Retrieves translation string for verb in past tense
static func get_action_past_tense(action_key: String) -> String:
	var key = "verb." + action_key.to_lower()
	var translated = TranslationServer.translate(StringName(key))
	if translated == StringName(key):
		return TranslationServer.translate("verb.used")
	return str(translated)

## Full construction of dynamic action phrase
static func build_action_phrase(attr_idx: int, action_key: String) -> String:
	var adverb = get_adverb(attr_idx, action_key)
	var verb = get_action_past_tense(action_key)
	if adverb.is_empty():
		return verb
	if verb.is_empty():
		return adverb
	return TranslationServer.translate("format.action_phrase").format({
		"adverb": adverb,
		"verb": verb
	})

## Generates complete feedback strings (logs or barks) by mapping provided variables into localized templates.
static func format_feedback(key: String, initiator: String, partner: String, attribute: String, amount: int, action_phrase: String = "") -> String:
	return TranslationServer.translate(key).format({
		"initiator": initiator,
		"partner": partner,
		"attribute": attribute,
		"action_phrase": action_phrase,
		"amount": amount
	})

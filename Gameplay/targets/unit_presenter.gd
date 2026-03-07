class_name UnitPresenter
extends RefCounted

const LocalizationStrings := preload("res://Resources/Localization/localization_strings.gd")

## Presenter for transforming Unit state into human-readable strings and UI data.
## Extracted from Unit to reduce file complexity.

static func get_hover_info(unit: Unit) -> String:
	var info_text = LocalizationStrings.get_text("unit.details.name").format({"name": unit.unit_name})
	info_text += "\n" + LocalizationStrings.get_text("unit.details.faction").format({"faction": get_faction_name(unit)})
	info_text += "\nWP: %d/%d" % [unit.willpower, unit.max_willpower]

	if unit.res:
		info_text += "\nReactions: %d/%d" % [unit.res.get_reactions_available(), unit.res.get_max_reactions()]

	# Access Faction directly from Unit
	if int(unit.faction) == 2: # NEUTRAL
		var loyalty_text := LocalizationStrings.get_text(LocalizationStrings.HUD_FACTION_NEUTRAL)
		var loyalty_val = unit.loyalty.neutral_loyalty
		if loyalty_val == 0: # PLAYER
			loyalty_text = LocalizationStrings.get_text(LocalizationStrings.HUD_FACTION_PLAYER)
		elif loyalty_val == 1: # ENEMY
			loyalty_text = LocalizationStrings.get_text(LocalizationStrings.HUD_FACTION_ENEMY)
		info_text += "\n" + LocalizationStrings.get_text("unit.details.loyalty").format({"loyalty": loyalty_text})

	if unit.status:
		var effects = unit.status.get_status_effects()
		if not effects.is_empty():
			info_text += "\nStatus: " + ", ".join(effects.map(func(e): return str(e)))

	return info_text


static func get_faction_name(unit: Unit) -> String:
	match int(unit.faction):
		0: # PLAYER
			return LocalizationStrings.get_text(LocalizationStrings.HUD_FACTION_PLAYER)
		1: # ENEMY
			return LocalizationStrings.get_text(LocalizationStrings.HUD_FACTION_ENEMY)
		2: # NEUTRAL
			return LocalizationStrings.get_text(LocalizationStrings.HUD_FACTION_NEUTRAL)
	return LocalizationStrings.get_text("hud.unit_name_fallback")

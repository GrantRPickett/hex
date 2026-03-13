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
		info_text += "\n" + LocalizationStrings.get_text(LocalizationStrings.HUD_UNIT_REACTIONS).format({
			"current": unit.res.get_reactions_available(),
			"max": unit.res.get_max_reactions()
		})

	# Access Faction directly from Unit
	if int(unit.faction) == Unit.Faction.NEUTRAL:
		var loyalty_text := LocalizationStrings.get_text(LocalizationStrings.HUD_FACTION_NEUTRAL)
		var loyalty_val = unit.loyalty.neutral_loyalty
		if loyalty_val == Unit.Faction.PLAYER:
			loyalty_text = LocalizationStrings.get_text(LocalizationStrings.HUD_FACTION_PLAYER)
		elif loyalty_val == Unit.Faction.ENEMY:
			loyalty_text = LocalizationStrings.get_text(LocalizationStrings.HUD_FACTION_ENEMY)
		info_text += "\n" + LocalizationStrings.get_text("unit.details.loyalty").format({"loyalty": loyalty_text})

	if unit.status:
		var effects = unit.status.get_status_effects()
		if not effects.is_empty():
			var effects_str = ", ".join(effects.map(func(e): return str(e)))
			info_text += "\n" + LocalizationStrings.get_text(LocalizationStrings.HUD_UNIT_STATUS).format({
				"effects": effects_str
			})

	return info_text


static func get_faction_name(unit: Unit) -> String:
	return GameConstants.get_faction_name(int(unit.faction))

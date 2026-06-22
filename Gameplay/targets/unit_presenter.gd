class_name UnitPresenter
extends RefCounted

const LocalizationStrings := preload("res://Resources/Localization/localization_strings.gd")

## Presenter for transforming Unit state into human-readable strings and UI data.
## Extracted from Unit to reduce file complexity.

static func get_hover_info(unit: Unit) -> String:
	var info_text: String = LocalizationStrings.get_text("unit.details.name").format({"name": unit.unit_name})
	info_text += "\n" + LocalizationStrings.get_text("unit.details.faction").format({"faction": GameConstants.get_faction_name(int(unit.faction))})

	var total_wp = unit.get_max_willpower()
	info_text += "\nWP: %d/%d" % [unit.get_current_willpower(), total_wp]

	# Core Stats
	var stats_line: String = ""
	for idx in GameConstants.COMBAT_ATTRIBUTE_INDICES:
		var total: int = unit.get_attribute(idx)
		var base = unit.get_base_attribute_from_target(idx)
		var bonus = total - base

		var internal_name: String = GameConstants.get_attribute_name(idx)
		var stat_name: String = TranslationServer.translate("attr." + internal_name.to_lower())
		# Format as "Attr: base+bonus" to match the attribute grid display
		var stat_str: String = ""
		if bonus > 0:
			stat_str = "%s: %d+%d" % [stat_name, base, bonus]
		elif bonus < 0:
			stat_str = "%s: %d%d" % [stat_name, base, bonus]
		else:
			stat_str = "%s: %d" % [stat_name, base]

		if stats_line.is_empty():
			stats_line = stat_str
		else:
			stats_line += ", " + stat_str

	if not stats_line.is_empty():
		info_text += "\n" + stats_line

	if unit.res:
		info_text += "\n" + LocalizationStrings.get_text(LocalizationStrings.HUD_UNIT_REACTIONS).format({
			"current": unit.res.get_reactions_available(),
			"max": unit.res.get_max_reactions()
		})

	# Access Faction directly from Unit
	if int(unit.faction) == GameConstants.Faction.NEUTRAL:
		var loyalty_text := LocalizationStrings.get_text(LocalizationStrings.HUD_FACTION_NEUTRAL)
		var loyalty_val = unit.loyalty.neutral_loyalty
		if loyalty_val == GameConstants.Faction.PLAYER:
			loyalty_text = LocalizationStrings.get_text(LocalizationStrings.HUD_FACTION_PLAYER)
		elif loyalty_val == GameConstants.Faction.ENEMY:
			loyalty_text = LocalizationStrings.get_text(LocalizationStrings.HUD_FACTION_ENEMY)
		info_text += "\n" + LocalizationStrings.get_text("unit.details.loyalty").format({"loyalty": loyalty_text})

	if unit.status:
		var effects = unit.status.get_status_effects()
		if not effects.is_empty():
			var effects_str: String = ", ".join(effects.map(func(e): return str(e)))
			info_text += "\n" + LocalizationStrings.get_text(LocalizationStrings.HUD_UNIT_STATUS).format({
				"effects": effects_str
			})

	return info_text

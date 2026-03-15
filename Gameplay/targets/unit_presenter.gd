class_name UnitPresenter
extends RefCounted

const LocalizationStrings := preload("res://Resources/Localization/localization_strings.gd")

## Presenter for transforming Unit state into human-readable strings and UI data.
## Extracted from Unit to reduce file complexity.

static func get_hover_info(unit: Unit) -> String:
	var info_text = LocalizationStrings.get_text("unit.details.name").format({"name": unit.unit_name})
	info_text += "\n" + LocalizationStrings.get_text("unit.details.faction").format({"faction": GameConstants.get_faction_name(int(unit.faction))})
	
	# WP with bonus if any
	var base_wp = unit.get_base_attribute_from_target(GameConstants.Attributes.AttributeIndex.WILLPOWER)
	var total_wp = unit.max_willpower
	if total_wp > base_wp:
		info_text += "\nWP: %d/%d (+%d)" % [unit.willpower, total_wp, total_wp - base_wp]
	else:
		info_text += "\nWP: %d/%d" % [unit.willpower, total_wp]

	# Core Stats
	var stats_line = ""
	for attr_name in GameConstants.Attributes.COMBAT_ATTRIBUTES:
		var idx = GameConstants.Attributes.get_attribute_index(attr_name)
		var total = unit.get_attribute(idx)
		var base = unit.get_base_attribute_from_target(idx)
		var bonus = total - base
		
		var stat_name = attr_name.capitalize()
		var stat_str = "%s: %d" % [stat_name, total]
		if bonus > 0:
			stat_str += " (+%d)" % bonus
		elif bonus < 0:
			stat_str += " (%d)" % bonus
			
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

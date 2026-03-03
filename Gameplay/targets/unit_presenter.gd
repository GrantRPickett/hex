class_name UnitPresenter
extends RefCounted

## Presenter for transforming Unit state into human-readable strings and UI data.
## Extracted from Unit to reduce file complexity.

static func get_hover_info(unit: Unit) -> String:
	var info_text = "Name: " + unit.unit_name
	info_text += "\nFaction: " + get_faction_name(unit)
	info_text += "\nWP: %d/%d" % [unit.willpower, unit.max_willpower]

	if unit.res:
		info_text += "\nReactions: %d/%d" % [unit.res.get_reactions_available(), unit.res.get_max_reactions()]

	# Access Faction directly from Unit
	if int(unit.faction) == 2: # NEUTRAL
		var loyalty_text := "Neutral"
		var loyalty_val = unit.loyalty.neutral_loyalty
		if loyalty_val == 0: # PLAYER
			loyalty_text = "Player"
		elif loyalty_val == 1: # ENEMY
			loyalty_text = "Enemy"
		info_text += "\nLoyalty: " + loyalty_text

	if unit.status:
		var effects = unit.status.get_status_effects()
		if not effects.is_empty():
			info_text += "\nStatus: " + ", ".join(effects.map(func(e): return str(e)))

	return info_text


static func get_faction_name(unit: Unit) -> String:
	match int(unit.faction):
		0: # PLAYER
			return "Player"
		1: # ENEMY
			return "Enemy"
		2: # NEUTRAL
			return "Neutral"
	return "Unknown"

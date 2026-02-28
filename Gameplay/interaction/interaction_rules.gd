class_name InteractionRules
extends RefCounted

# Decides whether an interaction consumes action points and whether it requires an opposed check.

static func location_interaction_cost(danger: bool) -> Dictionary:
	# returns {costs_action: bool, opposed: bool}
	return {"costs_action": danger, "opposed": false}

static func unit_talk_cost(actor: Unit, target: Unit) -> Dictionary:
	# Neutral allied to player (via neutral loyalty) → free.
	var opposed := false
	var costs := true
	if target and target.faction == 2: # Unit.Faction.NEUTRAL
		var nl :int= target.get_neutral_loyalty() if target.has_method("get_neutral_loyalty") else 2
		if nl == 0: # aligned with player
			costs = false
			opposed = false
		elif nl == 1: # aligned with enemy
			costs = true
			opposed = true
		else:
			# Truly neutral defaults to free talk
			costs = false
			opposed = false
	elif target and target.faction == 1: # enemy
		costs = true
		opposed = true
	else:
		costs = false
		opposed = false
	return {"costs_action": costs, "opposed": opposed}


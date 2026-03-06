class_name UnitLoyaltyComponent
extends RefCounted

var unit: Unit
var faction: int
var neutral_loyalty: int = -1 # Matches Unit.Faction.NEUTRAL usually
var neutral_can_be_persuaded: bool = false
var neutral_can_rally_allies: bool = false
var leader_faction: int = -1
var loyalty_locked: bool = false
var loyalty_type: GameConstants.Loyalty = GameConstants.Loyalty.NEUTRAL

func _init(p_unit: Unit) -> void:
	unit = p_unit
	faction = unit.faction
	loyalty_type = unit.loyalty_type # Initialize from unit
	neutral_loyalty = unit.faction # Initialize with base faction

	neutral_can_be_persuaded = unit.neutral_can_be_persuaded
	neutral_can_rally_allies = unit.neutral_can_rally_allies

func is_faction_leader(p_faction: int) -> bool:
	return leader_faction == p_faction and p_faction >= 0

func set_faction_leader(p_faction: int, enabled: bool) -> void:
	if p_faction < 0:
		return
	if enabled:
		leader_faction = p_faction
	else:
		if leader_faction == p_faction:
			leader_faction = -1

func reset_neutral_loyalty() -> void:
	if unit.faction != Unit.Faction.NEUTRAL:
		return
	var changed := neutral_loyalty != Unit.Faction.NEUTRAL
	neutral_loyalty = Unit.Faction.NEUTRAL
	if changed and unit.query:
		unit.query.invalidate_cache()

func set_neutral_loyalty(target_faction: int, allow_rally: bool = true, rally_targets: Array = []) -> void:
	if unit.faction != Unit.Faction.NEUTRAL:
		return
	if loyalty_locked or loyalty_type == GameConstants.Loyalty.STATIC:
		return

	var normalized := target_faction
	if normalized != Unit.Faction.PLAYER and normalized != Unit.Faction.ENEMY:
		normalized = Unit.Faction.NEUTRAL
	if neutral_loyalty == normalized:
		return
	neutral_loyalty = normalized
	if unit.query:
		unit.query.invalidate_cache()

	if allow_rally and neutral_can_rally_allies and neutral_loyalty != Unit.Faction.NEUTRAL:
		var targets: Array = rally_targets.duplicate()
		if targets.is_empty() and unit.get_unit_manager():
			targets = unit.get_unit_manager().get_neutral_units()
		for ally in targets:
			if ally == null or ally == unit:
				continue
			if not (ally is Unit):
				continue
			if ally.faction != Unit.Faction.NEUTRAL:
				continue
			if not ally.neutral_can_be_persuaded:
				continue
			ally.loyalty.set_neutral_loyalty(neutral_loyalty, false)

func apply_persuasion(target_faction: int) -> void:
	if unit.faction != Unit.Faction.NEUTRAL:
		return
	if not neutral_can_be_persuaded:
		return
	set_neutral_loyalty(target_faction)

func handle_attack_from(attacker: Unit) -> void:
	if unit.faction != Unit.Faction.NEUTRAL or attacker == null:
		return
	var aggressor := attacker.faction
	if aggressor == Unit.Faction.NEUTRAL:
		var attacker_loyalty := attacker.loyalty.neutral_loyalty
		if attacker_loyalty == Unit.Faction.PLAYER or attacker_loyalty == Unit.Faction.ENEMY:
			aggressor = attacker_loyalty as Unit.Faction
		else:
			return
	var retaliate_faction := Unit.Faction.NEUTRAL
	if aggressor == Unit.Faction.PLAYER:
		retaliate_faction = Unit.Faction.ENEMY
	elif aggressor == Unit.Faction.ENEMY:
		retaliate_faction = Unit.Faction.PLAYER
	if retaliate_faction != Unit.Faction.NEUTRAL:
		set_neutral_loyalty(retaliate_faction)

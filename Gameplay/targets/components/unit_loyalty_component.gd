class_name UnitLoyaltyComponent
extends RefCounted

var _unit: Unit
var faction: int
var neutral_loyalty: int = -1 # Matches GameConstants.Faction.NEUTRAL usually
var neutral_can_be_persuaded: bool:
	get:
		return _unit.neutral_can_be_persuaded if is_instance_valid(_unit) else _neutral_can_be_persuaded
	set(value):
		_neutral_can_be_persuaded = value
		if is_instance_valid(_unit):
			_unit.neutral_can_be_persuaded = value

var neutral_can_rally_allies: bool:
	get:
		return _unit.neutral_can_rally_allies if is_instance_valid(_unit) else _neutral_can_rally_allies
	set(value):
		_neutral_can_rally_allies = value
		if is_instance_valid(_unit):
			_unit.neutral_can_rally_allies = value

var _neutral_can_be_persuaded: bool = false
var _neutral_can_rally_allies: bool = false
var leader_faction: int = -1
var loyalty_locked: bool = false
var loyalty_type: GameConstants.Faction = GameConstants.Faction.NEUTRAL

func _init(p_unit: Unit) -> void:
	_unit = p_unit
	if is_instance_valid(_unit):
		faction = _unit.faction
		loyalty_type = _unit.loyalty_type # Initialize from unit
		neutral_loyalty = _unit.faction # Initialize with base faction

		neutral_can_be_persuaded = _unit.neutral_can_be_persuaded
		neutral_can_rally_allies = _unit.neutral_can_rally_allies

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
	if _unit.faction != GameConstants.Faction.NEUTRAL:
		return
	var changed : bool = neutral_loyalty != GameConstants.Faction.NEUTRAL
	neutral_loyalty = GameConstants.Faction.NEUTRAL
	if changed:
		if _unit.query:
			_unit.query.invalidate_cache()
		if EventBus:
			EventBus.unit_loyalty_changed.emit(_unit, neutral_loyalty)
		_unit.update_visuals()

func set_neutral_loyalty(target_faction: int, allow_rally: bool = true, rally_targets: Array = []) -> void:
	if not _can_change_loyalty():
		return

	var normalized := _normalize_faction(target_faction)
	if neutral_loyalty == normalized:
		return

	neutral_loyalty = normalized
	if _unit.query:
		_unit.query.invalidate_cache()
	if EventBus:
		EventBus.unit_loyalty_changed.emit(_unit, neutral_loyalty)
	
	if is_instance_valid(_unit):
		_unit.refresh_is_opposed()
		_unit.update_visuals()

	if allow_rally and neutral_can_rally_allies and neutral_loyalty != GameConstants.Faction.NEUTRAL:
		_rally_allies(rally_targets)

func _can_change_loyalty() -> bool:
	return _unit.faction == GameConstants.Faction.NEUTRAL and not loyalty_locked and loyalty_type != GameConstants.Faction.STATIC

func _normalize_faction(target_faction: GameConstants.Faction) -> GameConstants.Faction:
	if target_faction != GameConstants.Faction.PLAYER and target_faction != GameConstants.Faction.ENEMY:
		return GameConstants.Faction.NEUTRAL
	return target_faction

func _rally_allies(rally_targets: Array) -> void:
	var targets: Array = rally_targets.duplicate()
	if targets.is_empty() and _unit.get_unit_manager():
		targets = _unit.get_unit_manager().get_neutral_units()

	for ally in targets:
		if _can_rally_ally(ally):
			ally.loyalty.set_neutral_loyalty(neutral_loyalty, false)

func _can_rally_ally(ally: Variant) -> bool:
	if ally == null or not (ally is Unit) or ally == _unit:
		return false
	return ally.faction == GameConstants.Faction.NEUTRAL and ally.neutral_can_be_persuaded and ally.loyalty != null

func apply_persuasion(target_faction: int) -> void:
	if _unit.faction != GameConstants.Faction.NEUTRAL:
		return
	if not neutral_can_be_persuaded:
		return
	set_neutral_loyalty(target_faction)

func handle_attack_from(attacker: Unit) -> void:
	if _unit.faction != GameConstants.Faction.NEUTRAL or attacker == null:
		return
	var aggressor := attacker.faction
	if aggressor == GameConstants.Faction.NEUTRAL:
		if attacker.loyalty == null:
			return
		var attacker_loyalty := attacker.loyalty.neutral_loyalty
		if attacker_loyalty == GameConstants.Faction.PLAYER or attacker_loyalty == GameConstants.Faction.ENEMY:
			aggressor = attacker_loyalty as GameConstants.Faction
		else:
			return
	var retaliate_faction := GameConstants.Faction.NEUTRAL
	if aggressor == GameConstants.Faction.PLAYER:
		retaliate_faction = GameConstants.Faction.ENEMY
	elif aggressor == GameConstants.Faction.ENEMY:
		retaliate_faction = GameConstants.Faction.PLAYER
	if retaliate_faction != GameConstants.Faction.NEUTRAL:
		set_neutral_loyalty(retaliate_faction)


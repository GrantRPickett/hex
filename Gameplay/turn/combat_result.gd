class_name CombatResult
extends RefCounted

var attacker: Unit = null
var defender: Target = null
var damage: int = 0
var counter_damage: int = 0
var type: String = ""
var is_opposed: bool = false
var quality: GameConstants.Combat.AttackQuality = GameConstants.Combat.AttackQuality.IDLE
var attribute_index: int = -1

func to_dict() -> Dictionary:
	return {
		"damage": damage,
		"counter_damage": counter_damage,
		"type": type,
		"is_opposed": is_opposed,
		"quality": quality,
		"attribute_index": attribute_index,
		"actor_faction": get_actor_faction(),
		"target_faction": get_target_faction()
	}

static func from_dict(dict: Dictionary) -> CombatResult:
	var res = CombatResult.new()
	if dict.is_empty(): return res
	res.attacker = dict.get("attacker")
	res.defender = dict.get("defender")
	res.damage = dict.get("damage", 0)
	res.counter_damage = dict.get("counter_damage", 0)
	res.type = dict.get("type", "")
	res.is_opposed = dict.get("is_opposed", false)
	res.quality = dict.get("quality", GameConstants.Combat.AttackQuality.IDLE)
	res.attribute_index = dict.get("attribute_index", -1)
	return res

## New standardized resolution helpers

func bind_participants(p_attacker: Unit, p_defender: Target) -> void:
	attacker = p_attacker
	defender = p_defender

static func from_payload(payload: Dictionary, context: GameCommandContext) -> CombatResult:
	if payload.is_empty(): return null
	
	# Handle nested forecast if present
	var data = payload
	if payload.has(GameConstants.Payload.FORECAST_RESULTS):
		data = payload[GameConstants.Payload.FORECAST_RESULTS]

	var res = from_dict(data)

	# Re-resolve participants from payload if not already bound
	if res.attacker == null and context and context.unit_manager:
		var unit_idx = payload.get(GameConstants.Payload.UNIT_INDEX, GameConstants.INVALID_INDEX)
		if unit_idx != GameConstants.INVALID_INDEX:
			res.attacker = context.unit_manager.get_unit(unit_idx)

	if res.defender == null:
		var target_id = payload.get("target_id", "")
		if not target_id.is_empty():
			res.defender = TargetDiscoveryService.get_target_by_id(target_id)
		else:
			# Fallback for old payloads that might use TARGET_INDEX (Vector2i)
			var target_coord = payload.get(GameConstants.Payload.TARGET_INDEX, GameConstants.INVALID_COORD)
			if target_coord != GameConstants.INVALID_COORD:
				res.defender = TargetDiscoveryService.get_target_at_coord(target_coord)

	return res

func is_equal(other: CombatResult) -> bool:
	if other == null: return false
	return (
		attacker == other.attacker and
		defender == other.defender and
		damage == other.damage and
		counter_damage == other.counter_damage and
		type == other.type and
		is_opposed == other.is_opposed and
		quality == other.quality and
		attribute_index == other.attribute_index
	)

func get_actor_faction() -> int:
	if is_instance_valid(attacker):
		return attacker.get_effective_faction()
	return GameConstants.INVALID_INDEX

func get_target_faction() -> int:
	if is_instance_valid(defender) and (defender is Unit or defender.has_method("get_effective_faction")):
		return defender.get_effective_faction()
	return GameConstants.INVALID_INDEX


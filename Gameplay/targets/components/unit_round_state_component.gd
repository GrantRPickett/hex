class_name UnitRoundStateComponent
extends RefCounted

var _unit: Unit
var _leader_faction: int = -1

func _init(unit: Unit) -> void:
	_unit = unit


func refresh_for_new_round() -> void:
	if _unit.res:
		_unit.res.refresh_for_new_round()

	consume_aid_buffs()

	if _unit._movement_cache:
		_unit._movement_cache.invalidate()
	if _unit._threat_cache:
		_unit._threat_cache.invalidate()

	if _unit.movement:
		_unit.movement.refresh_for_new_round()

	if _unit.query:
		_unit.query.invalidate_cache()


func set_free_roam_mode(enabled: bool) -> void:
	if is_in_free_roam_mode() == enabled:
		return
	if _unit.movement:
		_unit.movement.set_free_roam_mode(enabled)
	if _unit.res:
		_unit.res.refresh_for_new_round()
	if _unit._movement_cache:
		_unit._movement_cache.invalidate()
	if _unit._threat_cache:
		_unit._threat_cache.invalidate()


func is_in_free_roam_mode() -> bool:
	return _unit.movement.is_free_roam_mode() if _unit.movement else false


func consume_action() -> void:
	if is_in_free_roam_mode():
		return
	if _unit.res:
		_unit.res.consume_action()


func block_movement_this_turn() -> void:
	if _unit.res:
		_unit.res.block_movement_this_turn()


func block_action_this_turn() -> void:
	if _unit.res:
		_unit.res.block_action_this_turn()


func is_faction_leader(p_faction: int) -> bool:
	return _leader_faction == p_faction and p_faction >= 0


func set_faction_leader(p_faction: int, enabled: bool) -> void:
	if p_faction < 0:
		return
	if enabled:
		_leader_faction = p_faction
	elif _leader_faction == p_faction:
		_leader_faction = -1


func is_player_leader() -> bool:
	return is_faction_leader(GameConstants.Faction.PLAYER)


func set_player_leader(enabled: bool) -> void:
	set_faction_leader(GameConstants.Faction.PLAYER, enabled)


func get_aid_buff(pair_index: int) -> int:
	if pair_index >= 0 and pair_index < _unit.aid_buffs.size():
		return _unit.aid_buffs[pair_index]
	return 0


func add_aid_buff(p_value: int, pair_index: int) -> void:
	if pair_index == GameConstants.INVALID_INDEX:
		for i in range(_unit.aid_buffs.size()):
			_unit.aid_buffs[i] += p_value
	elif pair_index >= 0 and pair_index < _unit.aid_buffs.size():
		_unit.aid_buffs[pair_index] += p_value

	var total := 0
	for b in _unit.aid_buffs:
		total += b
	_unit.aid_buffs_changed.emit(total)
	if _unit.attributes:
		_unit.attributes.invalidate_cache()


func consume_aid_buffs() -> void:
	var total := 0
	for b in _unit.aid_buffs:
		total += b

	if total <= 0:
		return

	_unit.aid_buffs = PackedInt32Array([0, 0, 0])
	_unit.aid_buffs_changed.emit(0)
	if _unit.attributes:
		_unit.attributes.invalidate_cache()

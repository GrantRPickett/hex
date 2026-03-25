extends GdUnitTestSuite

# Tests for LootActionProvider: append_loot_action

const ActionProvider := preload("res://Gameplay/targets/loot_action_provider.gd")

class FakeLootManager extends LootManager:
	var _loots: Dictionary = {} # coord -> array of loots
	var _all_loots: Array = []
	var _fake_coords: Array = []

	func _init() -> void:
		pass

	func get_loot_at(coord: Vector2i) -> Loot:
		if _loots.has(coord) and not _loots[coord].is_empty():
			return _loots[coord][0]
		return null

	func get_loot_count() -> int:
		return _all_loots.size()

	func get_loot(index: int) -> Loot:
		if index >= 0 and index < _all_loots.size():
			return _all_loots[index]
		return null

	func get_coord(index: int) -> Vector2i:
		if index >= 0 and index < _fake_coords.size():
			return _fake_coords[index]
		return Vector2i(-1, -1)

	func add_fake_loot(loot: Loot, coord: Vector2i) -> void:
		if not _loots.has(coord): _loots[coord] = []
		_loots[coord].append(loot)
		_all_loots.append(loot)
		_fake_coords.append(coord)

class FakeLoot extends Loot:
	var can_loot := true
	func can_be_looted_by(_u: Unit, _d: float = 0.0) -> bool:
		return can_loot
	func is_type_loot() -> bool: return true # To pass generic checks

class FakeUnit extends Unit:
	var _loot_mgr: LootManager
	func get_loot_manager() -> LootManager:
		return _loot_mgr

func test_append_loot_action_adds_immediate_and_reachable() -> void:
	var provider := ActionProvider.new()
	var mgr := FakeLootManager.new()
	var u := FakeUnit.new()
	u._loot_mgr = mgr

	# Immediate loot
	var l_imm := FakeLoot.new()
	var l_reach := FakeLoot.new()
	mgr.add_fake_loot(l_imm, Vector2i(0, 0))
	mgr.add_fake_loot(l_reach, Vector2i(1, 0))

	var actions: Array[PlayerAction] = []
	var reachable_coords: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0)]
	var reachable_lookup: Dictionary = {Vector2i(0, 0): 0, Vector2i(1, 0): 1}

	var reach := ReachableState.new()
	reach.action_origin = Vector2i(0, 0)
	reach.reachable_coords = reachable_coords
	reach.lookup = reachable_lookup
	provider.append_loot_action(actions, u, reach)

	# Should append one action bridging immediate logic and reachable counts
	assert_int(actions.size()).is_equal(1)
	var action: PlayerAction = actions[0]
	assert_int(action.type).is_equal(GameConstants.ActionType.GATHER)
	assert_bool(action.available).is_true()
	assert_object(action.target_object).is_equal(l_imm)

	l_imm.queue_free()
	l_reach.queue_free()

func test_append_loot_action_changes_label_for_traps() -> void:
	var provider := ActionProvider.new()
	var mgr := FakeLootManager.new()
	var u := FakeUnit.new()
	u._loot_mgr = mgr

	var l_trap := FakeLoot.new()
	l_trap.is_trapped = true
	mgr.add_fake_loot(l_trap, Vector2i(5, 5))

	var actions: Array[PlayerAction] = []
	var reachable_coords: Array[Vector2i] = [Vector2i(5, 5)] # not checking reachables, just immediate
	var reachable_lookup: Dictionary = {Vector2i(5, 5): 0}

	var reach := ReachableState.new()
	reach.action_origin = Vector2i(5, 5)
	reach.reachable_coords = reachable_coords
	reach.lookup = reachable_lookup
	provider.append_loot_action(actions, u, reach)

	assert_int(actions.size()).is_equal(1)
	# Should be "Investigate Trap"
	# Should be Item Opposed (Standardized)
	assert_str(actions[0].action_id).is_equal(GameConstants.ActionIds.ITEM_OPPOSED)

	l_trap.queue_free()

func test_append_loot_action_no_loot_returns_empty() -> void:
	var provider := ActionProvider.new()
	var mgr := FakeLootManager.new()
	var u := FakeUnit.new()
	u._loot_mgr = mgr

	var actions: Array[Dictionary] = []
	var reach := ReachableState.new()
	reach.action_origin = Vector2i(0, 0)
	reach.reachable_coords = [Vector2i(0, 0)]
	reach.lookup = {Vector2i(0, 0): 0}
	provider.append_loot_action(actions, u, reach)
	assert_array(actions).is_empty()

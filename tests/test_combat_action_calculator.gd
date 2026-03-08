extends GdUnitTestSuite

# Tests for CombatActionCalculator: append_combat_actions

const CalculatorScript := preload("res://Gameplay/turn/combat_action_calculator.gd")

class FakeQueryService extends UnitQueryService:
	var friends: Array[Unit] = []
	var enemies: Array[Unit] = []
	var neutrals: Array[Unit] = []
	var adjacents: Dictionary = {} # unit -> array of adjacent units

	func get_friendly_units() -> Array[Unit]: return friends
	func get_hostile_units() -> Array[Unit]: return enemies
	func get_adjacent_units(p_units: Array, _max_range: float = 1.0) -> Array[Unit]:
		var result: Array[Unit] = []
		for u in p_units:
			if adjacents.has(u):
				result.append_array(adjacents[u])
		return result

func _make_reach_state(coords: Array[Vector2i]) -> Dictionary:
	var lookup := {}
	var index := 0
	for coord in coords:
		lookup[coord] = {"cost": index}
		index += 1
	return {"coords": coords, "lookup": lookup}

func _make_unit(faction: Unit.Faction, wp: int, max_wp: int) -> Unit:
	var u: Unit = Unit.new()
	u.faction = faction
	u.willpower = wp
	u.max_willpower = max_wp
	u.action_range = 1
	add_child(u) # to get instance id
	var query := FakeQueryService.new(u)
	u.query = query
	return u

func after_test() -> void:
	for child in get_children():
		if is_instance_valid(child):
			child.queue_free()

func test_append_combat_actions_includes_adjacent_attack() -> void:
	var calc := CalculatorScript.new()
	var mgr := UnitManager.new()
	add_child(mgr)

	var u1: Unit = _make_unit(Unit.Faction.PLAYER, 10, 10)
	var u2: Unit = _make_unit(Unit.Faction.ENEMY, 10, 10)
	mgr.add_unit(u1, Vector2i(0, 0), true)
	mgr.add_unit(u2, Vector2i(0, 1), false)

	# Setup queries
	u1.query.enemies = [u2]
	u1.query.adjacents[u2] = [u2]

	var actions: Array[Dictionary] = []
	var reachable: Array[Vector2i] = [Vector2i(0, 0)]

	calc.append_combat_actions(actions, u1, mgr, _make_reach_state(reachable), TileSet.TILE_OFFSET_AXIS_VERTICAL)

	assert_int(actions.size()).is_equal(1)
	assert_str(actions[0]["label"]).contains("Attack")
	assert_bool(actions[0]["available"]).is_true()

func test_append_combat_actions_includes_adjacent_aid() -> void:
	var calc := CalculatorScript.new()
	var mgr := UnitManager.new()
	add_child(mgr)

	var u1: Unit = _make_unit(Unit.Faction.PLAYER, 10, 10)
	var u2: Unit = _make_unit(Unit.Faction.PLAYER, 5, 10) # hurt ally
	mgr.add_unit(u1, Vector2i(0, 0), true)
	mgr.add_unit(u2, Vector2i(0, 1), false)

	# Setup queries
	u1.query.friends = [u1, u2]
	u1.query.adjacents[u1] = [u1]
	u1.query.adjacents[u2] = [u2]

	var actions: Array[Dictionary] = []
	var reachable: Array[Vector2i] = [Vector2i(0, 0)]

	calc.append_combat_actions(actions, u1, mgr, _make_reach_state(reachable), TileSet.TILE_OFFSET_AXIS_VERTICAL)

	assert_int(actions.size()).is_equal(1)
	assert_str(actions[0]["label"]).contains("Aid")
	assert_bool(actions[0]["available"]).is_true()

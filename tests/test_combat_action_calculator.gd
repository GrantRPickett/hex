extends GdUnitTestSuite

# Tests for CombatActionCalculator: append_combat_actions

const CalculatorScript := preload("res://Gameplay/turn/combat_action_calculator.gd")

class FakeQueryService extends UnitQueryService:
	var friends: Array[Unit] = []
	var enemies: Array[Unit] = []
	var neutrals: Array[Unit] = []
	var nears: Dictionary = {} # unit -> array of near units

	func get_friendly_units() -> Array[Unit]: return friends
	func get_hostile_units() -> Array[Unit]: return enemies
	func get_near_units(p_units: Array, _max_range: float = 1.0) -> Array[Unit]:
		var result: Array[Unit] = []
		for u in p_units:
			if nears.has(u):
				result.append_array(nears[u])
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

func test_append_combat_actions_includes_near_attack() -> void:
	var calc := CalculatorScript.new()
	var mgr : UnitManager = UnitManager.new()
	add_child(mgr)

	var u1: Unit = _make_unit(GameConstants.Faction.PLAYER, 10, 10)
	var u2: Unit = _make_unit(GameConstants.Faction.ENEMY, 10, 10)
	mgr.add_unit(u1, Vector2i(0, 0), true)
	mgr.add_unit(u2, Vector2i(0, 1), false)

	# Setup queries
	var q1 := u1.query as FakeQueryService
	q1.enemies = [u2]
	q1.nears[u2] = [u2]

	var actions: Array[PlayerAction] = []
	var reachable: Array[Vector2i] = [Vector2i(0, 0)]

	var reach_state := ReachableState.new()
	reach_state.coords = reachable
	reach_state.lookup = _make_reach_state(reachable)["lookup"]

	calc.append_combat_actions(actions, u1, mgr, reach_state, TileSet.TILE_OFFSET_AXIS_VERTICAL)

	assert_int(actions.size()).is_equal(1)
	assert_str(actions[0].label_params.get("imm_label", "")).contains("near")
	assert_bool(actions[0].available).is_true()

func test_append_combat_actions_includes_near_aid() -> void:
	var calc := CalculatorScript.new()
	var mgr := UnitManager.new()
	add_child(mgr)

	var u1: Unit = _make_unit(GameConstants.Faction.PLAYER, 10, 10)
	var u2: Unit = _make_unit(GameConstants.Faction.PLAYER, 5, 10) # hurt ally
	mgr.add_unit(u1, Vector2i(0, 0), true)
	mgr.add_unit(u2, Vector2i(0, 1), false)

	# Setup queries
	var q1 := u1.query as FakeQueryService
	q1.friends = [u1, u2]
	q1.nears[u1] = [u1]
	q1.nears[u2] = [u2]

	var actions: Array[PlayerAction] = []
	var reachable: Array[Vector2i] = [Vector2i(0, 0)]

	var reach_state := ReachableState.new()
	reach_state.coords = reachable
	reach_state.lookup = _make_reach_state(reachable)["lookup"]

	calc.append_combat_actions(actions, u1, mgr, reach_state, TileSet.TILE_OFFSET_AXIS_VERTICAL)

	assert_int(actions.size()).is_equal(1)
	assert_str(actions[0].get_label()).is_not_empty()
	assert_bool(actions[0].available).is_true()

extends GdUnitTestSuite

const ConvinceCommandClass = preload("res://Gameplay/commands/convince_unit_command.gd")
const Stubs = preload("res://tests/fixtures/test_stubs.gd")

class AlwaysNearQueryService extends UnitQueryService:
	func _init(unit: Unit):
		super._init(unit)

	func get_near_units(units: Array, _range: float = 1.5) -> Array[Unit]:
		return units.duplicate()

func test_loot_discovery_range_override() -> void:
	var _um = auto_free(Stubs.FakeUnitManager.new())
	var lm = auto_free(Stubs.FakeLootManager.new())
	var unit = auto_free(Stubs.FakeUnit.new())
	
	var loot = auto_free(Loot.new())
	lm.add_loot(loot, Vector2i(10, 10))
	unit.set_position(Vector2(0, 0)) # Distance will be large
	
	# Default range is 1.5, should not find it
	var targets_default = TargetDiscoveryService.get_potential_loot_items(unit, lm)
	assert_int(targets_default.size()).is_equal(0)
	
	# With range override, should find it
	var targets_far = TargetDiscoveryService.get_potential_loot_items(unit, lm, null, 100.0)
	assert_int(targets_far.size()).is_equal(1)
	assert_object(targets_far[0].item).is_same(loot)

func test_convince_command_signal_emission() -> void:
	var um = auto_free(Stubs.FakeUnitManager.new())
	var tm = auto_free(Stubs.FakeTaskManager.new())
	var tc = auto_free(Node.new()) # Fake TurnController
	
	var initiator = auto_free(Stubs.FakeUnit.new())
	var target = auto_free(Stubs.FakeUnit.new())
	target.neutral_can_be_persuaded = true
	target.faction = GameConstants.Faction.NEUTRAL
	
	# Setup context
	# Setup context with required stubs
	var nav = auto_free(Node.new())
	var cam = auto_free(Node.new())
	var mc = auto_free(Node.new())
	var task_ctrl = auto_free(Node.new())
	var grid = auto_free(Node.new())
	
	var context = GameCommandContext.new(um, nav, cam, mc, tc, task_ctrl, grid)
	context.task_manager = tm
	
	var payload = {
		GameConstants.Payload.INITIATOR_INDEX: 0,
		GameConstants.Payload.TARGET_INDEX: 1
	}
	
	um.add_unit(initiator, Vector2i(0,0), true) # Index 0
	um.add_unit(target, Vector2i(1,1), false)   # Index 1
	
	initiator.query = AlwaysNearQueryService.new(initiator)
	
	# Monitor interaction handler call or signal
	# Since we can't easily spy on the handler without more setup, 
	# we can check if apply_persuasion was called via the interaction handler
	# Actually, the best way is to verify it doesn't crash and the logic flows.
	
	var cmd = ConvinceCommandClass.new()
	var result = cmd.execute(context, payload)
	
	assert_bool(result.is_success()).is_true()
	# Verify loyalty was changed (this confirms apply_persuasion was called)
	# Default neutral loyalty is -1 or 2 (NEUTRAL). apply_persuasion changes it to initiator's faction.
	assert_int(target.loyalty.neutral_loyalty).is_equal(initiator.faction)
func test_convince_command_requires_adjacent_target() -> void:
	var um = auto_free(Stubs.FakeUnitManager.new())
	var tm = auto_free(Stubs.FakeTaskManager.new())
	var tc = auto_free(Node.new())
	
	var initiator = auto_free(Stubs.FakeUnit.new())
	var target = auto_free(Stubs.FakeUnit.new())
	target.neutral_can_be_persuaded = true
	target.faction = GameConstants.Faction.NEUTRAL
	
	var nav = auto_free(Node.new())
	var cam = auto_free(Node.new())
	var mc = auto_free(Node.new())
	var task_ctrl = auto_free(Node.new())
	var grid = auto_free(Node.new())
	var context = GameCommandContext.new(um, nav, cam, mc, tc, task_ctrl, grid)
	context.task_manager = tm
	
	var payload = {
		GameConstants.Payload.INITIATOR_INDEX: 0,
		GameConstants.Payload.TARGET_INDEX: 1
	}
	
	um.add_unit(initiator, Vector2i(0,0), true)
	um.add_unit(target, Vector2i(5,5), false)
	
	var cmd = ConvinceCommandClass.new()
	var result = cmd.execute(context, payload)
	
	assert_bool(result.is_failure()).is_true()
	assert_string(result.get_description()).is_equal("Target is not near")

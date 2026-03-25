extends GdUnitTestSuite

var _combat_system: CombatSystem

func before_test() -> void:
	_combat_system = auto_free(CombatSystem.new())

func test_get_attack_quality_downgrade_to_risky() -> void:
	var attacker = auto_free(Unit.new())
	var defender = auto_free(Unit.new())
	
	# Setup attacker: 10 Grit, 2 Willpower
	attacker.unit_name = "Attacker"
	attacker.max_willpower = 2
	attacker.willpower = 2
	# We need to manually set attributes if it doesn't have a query service yet
	# Unit.get_attribute calls query.get_total_attribute or super.get_attribute
	# Target.get_attribute returns 0 by default.
	
	# Let's use a simpler way if possible, or just mock the attributes
	# Actually, Unit.gd:
	# func get_attribute(idx: GameConstants.AttributeIndex) -> int:
	#    var base = get_base_attribute_from_target(idx)
	#    ...
	# Target.gd:
	# @export var base_grit: int = 0 ...
	# func get_attribute(idx: AttributeIndex) -> int:
	#    match idx: ...
	
	attacker.grit = 10
	attacker.flow = 0
	
	# Setup defender: 5 Flow, 1 Willpower
	defender.unit_name = "Defender"
	defender.base_willpower = 1
	defender.willpower = 1
	defender.grit = 10 
	defender.flow = 5
	
	# PAIRS = [[GRIT, FLOW], [GUSTO, FOCUS], [SHINE, SHADE]]
	# Defense = 0.34 * min + 0.66 * max
	# Defender defense for Grit: 0.34 * 5 + 0.66 * 10 = 1.7 + 6.6 = 8.3 -> 8 (int cast in simulate_attack?)
	# Attacker damage = 10 - 8.3 = 1.7 -> 1
	# Defender damage to attacker (counter):
	# Defender Grit = 10. Attacker defense for Grit: 0.34 * 0 + 0.66 * 10 = 6.6
	# Counter damage = 10 - 6.6 = 3.4 -> 3
	
	# Attacker deals 1 damage. Defender has 1 willpower. -> SUCCESS (Star)
	# Defender deals 3 counter-damage. Attacker has 2 willpower. -> Attacker dies! -> DANGEROUS!
	
	var quality = _combat_system.get_attack_quality(attacker, defender, GameConstants.AttributeIndex.GRIT)
	
	assert_int(quality).is_equal(GameConstants.Combat.AttackQuality.RISKY)
	assert_str(_combat_system.get_quality_symbol(quality)).is_equal(GameConstants.UI.Indicators.RISKY)

func test_get_attack_quality_normal_success() -> void:
	var attacker = auto_free(Unit.new())
	var defender = auto_free(Unit.new())
	
	attacker.base_willpower = 10
	attacker.willpower = 10
	attacker.grit = 10
	
	defender.base_willpower = 1
	defender.willpower = 1
	defender.grit = 0
	defender.flow = 0
	
	# Attacker Grit 10 vs Defender Defense 0 = 10 damage. -> SUCCESS
	# Defender Grit 0 vs Attacker Defense 6.6 = 0 damage. -> No counter.
	
	var quality = _combat_system.get_attack_quality(attacker, defender, GameConstants.AttributeIndex.GRIT)
	assert_int(quality).is_equal(GameConstants.Combat.AttackQuality.SUCCESS)
	assert_str(_combat_system.get_quality_symbol(quality)).is_equal(GameConstants.UI.Indicators.SUCCESS)

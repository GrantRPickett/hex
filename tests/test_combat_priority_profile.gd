extends GdUnitTestSuite

# Tests for CombatPriorityProfile.get_weight() — pure Resource, no Node deps.

const ProfileScript := preload("res://Gameplay/combat/combat_priority_profile.gd")

func _make_profile() -> CombatPriorityProfile:
	var p: CombatPriorityProfile = ProfileScript.new()
	auto_free(p)
	return p

# ---------------------------------------------------------------------------
# get_weight — table lookup branch
# ---------------------------------------------------------------------------

func test_get_weight_attack_returns_10() -> void:
	var p: CombatPriorityProfile = _make_profile()
	assert_int(p.get_weight(&"attack")).is_equal(10)

func test_get_weight_finish_low_hp_returns_6() -> void:
	var p: CombatPriorityProfile = _make_profile()
	assert_int(p.get_weight(&"finish_low_hp")).is_equal(6)

func test_get_weight_protect_ally_returns_5() -> void:
	var p: CombatPriorityProfile = _make_profile()
	assert_int(p.get_weight(&"protect_ally")).is_equal(5)

func test_get_weight_objective_returns_5() -> void:
	var p: CombatPriorityProfile = _make_profile()
	assert_int(p.get_weight(&"objective")).is_equal(5)

func test_get_weight_avoid_risk_returns_4() -> void:
	var p: CombatPriorityProfile = _make_profile()
	assert_int(p.get_weight(&"avoid_risk")).is_equal(4)

func test_get_weight_flank_returns_3() -> void:
	var p: CombatPriorityProfile = _make_profile()
	assert_int(p.get_weight(&"flank")).is_equal(3)

func test_get_weight_retreat_returns_2() -> void:
	var p: CombatPriorityProfile = _make_profile()
	assert_int(p.get_weight(&"retreat")).is_equal(2)

# ---------------------------------------------------------------------------
# get_weight — order-derived fallback (key in priorities but NOT weight_table)
# ---------------------------------------------------------------------------

func test_get_weight_fallback_uses_priority_order() -> void:
	var p: CombatPriorityProfile = _make_profile()
	# Add a key to priorities but NOT to weight_table
	p.priorities.append(&"custom_tactic")
	# It should be at index 7 (0-based), priorities.size() = 8
	# fallback = 8 - 7 = 1
	assert_int(p.get_weight(&"custom_tactic")).is_equal(1)

func test_get_weight_unknown_key_returns_zero() -> void:
	var p: CombatPriorityProfile = _make_profile()
	assert_int(p.get_weight(&"nonexistent")).is_equal(0)

func test_get_weight_custom_weight_table_overrides() -> void:
	var p: CombatPriorityProfile = _make_profile()
	p.weight_table["attack"] = 99
	assert_int(p.get_weight(&"attack")).is_equal(99)

func test_get_weight_earlier_priority_has_higher_fallback() -> void:
	var p: CombatPriorityProfile = _make_profile()
	# Clear weight_table so everything falls back to order
	p.weight_table.clear()
	var w_attack := p.get_weight(&"attack") # index 0 → size - 0 = 7
	var w_retreat := p.get_weight(&"retreat") # index 6 → size - 6 = 1
	assert_int(w_attack).is_greater(w_retreat)

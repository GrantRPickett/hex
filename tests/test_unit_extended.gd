extends GdUnitTestSuite

# Tests for Unit.gd focusing on uncovered pure getters/setters/state methods:
#   is_at_full_willpower, get_combat_profile, set_animation_service, finalize_setup

# Mock components that Unit expects in _ready
class FakeActionPoints extends ActionPointsComponent:
	var _willpower: int = 5
	var _max_willpower: int = 10
	func get_willpower() -> int: return _willpower
	func set_willpower(v: int) -> void: _willpower = v
	func get_max_willpower() -> int: return _max_willpower
	func set_max_willpower(v: int) -> void: _max_willpower = v

class FakeDeathHandler extends UnitDeathHandler:
	var _anim_service = null
	func _init(u: Unit) -> void:
		super (u)
	func set_animation_service(service) -> void:
		_anim_service = service

func _make_unit() -> Unit:
	var u: Unit = Unit.new()
	var ap: FakeActionPoints = FakeActionPoints.new()
	u.action_points_template = ap
	add_child(u) # calls _ready and _init
	u.res = ap
	return u

func after_test() -> void:
	for child in get_children():
		if is_instance_valid(child):
			child.queue_free()

# ---------------------------------------------------------------------------
# is_at_full_willpower & max_willpower zero edge case
# ---------------------------------------------------------------------------

func test_is_at_full_willpower_returns_true_when_equal() -> void:
	var u: Unit = _make_unit()
	u.max_willpower = 10
	u.willpower = 10
	assert_bool(u.is_at_full_willpower()).is_true()

func test_is_at_full_willpower_returns_true_when_greater() -> void:
	var u: Unit = _make_unit()
	u.max_willpower = 10
	u.willpower = 12
	assert_bool(u.is_at_full_willpower()).is_true()

func test_is_at_full_willpower_returns_false_when_less() -> void:
	var u: Unit = _make_unit()
	u.max_willpower = 10
	u.willpower = 9
	assert_bool(u.is_at_full_willpower()).is_false()

func test_is_at_full_willpower_returns_true_if_max_is_zero() -> void:
	# "Units with 0 max willpower are essentially immune to willpower damage"
	var u: Unit = _make_unit()
	u.max_willpower = 0
	u.willpower = 0
	assert_bool(u.is_at_full_willpower()).is_true()

# ---------------------------------------------------------------------------
# get_combat_profile
# ---------------------------------------------------------------------------

func test_get_combat_profile_returns_assigned_profile() -> void:
	var u: Unit = _make_unit()
	var profile: CombatPriorityProfile = CombatPriorityProfile.new()
	u.combat_priority_profile = profile
	assert_object(u.get_combat_profile()).is_equal(profile)

func test_get_combat_profile_returns_default_when_unassigned() -> void:
	var u: Unit = _make_unit()
	u.combat_priority_profile = null
	var profile: CombatPriorityProfile = u.get_combat_profile()
	assert_object(profile).is_not_null()
	# The default is shared across units
	assert_object(profile).is_equal(Unit._default_combat_profile)

# ---------------------------------------------------------------------------
# set_animation_service
# ---------------------------------------------------------------------------

func test_set_animation_service_assigns_internal_var() -> void:
	var u: Unit = _make_unit()
	var service = Node.new()
	u.set_animation_service(service)
	assert_object(u._animation_service).is_equal(service)
	service.queue_free()

func test_set_animation_service_propagates_to_death_handler() -> void:
	var u: Unit = _make_unit()
	var dh := FakeDeathHandler.new(u)
	u.death = dh
	var service = Node.new()
	u.set_animation_service(service)
	assert_object(dh._anim_service).is_equal(service)
	service.queue_free()

# ---------------------------------------------------------------------------
# finalize_setup
# ---------------------------------------------------------------------------

func test_finalize_setup_emits_ready_signal() -> void:
	var u: Unit = _make_unit()
	# u is already ready because add_child hit _ready(), which calls finalize_setup()
	# Let's reset the flag to test manually
	u._setup_finalized = false
	var monitor := monitor_signals(u)
	u.finalize_setup()
	assert_signal(monitor).is_emitted("components_ready")
	assert_bool(u._setup_finalized).is_true()

func test_finalize_setup_idempotent() -> void:
	var u: Unit = _make_unit()
	u._setup_finalized = true # Already finalized
	var monitor := monitor_signals(u)
	u.finalize_setup()
	assert_signal(monitor).is_not_emitted("components_ready")

func test_aid_buffs() -> void:
	var u: Unit = _make_unit()

	u.add_aid_buff("focus", 5)

	# Usually buff applies next check or sets a dictionary.
	# The function might just queue it or modify unit state directly.
	# Assuming it modifies the aid buffs dictionary or similar:
	assert_bool(u.consumables_active.has("aid_buff")).is_true()

	u.consume_aid_buffs()

	assert_bool(u.consumables_active.is_empty()).is_true()

func test_set_location_service() -> void:
	var u: Unit = _make_unit()
	var service = Node.new()
	u.set_location_service(service)
	assert_object(u._location_service).is_equal(service)
	service.queue_free()

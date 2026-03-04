extends GdUnitTestSuite

# Tests for AnimationRequestService — uncovering remaining functions:
# on_unit_moved

const AnimService := preload("res://Gameplay/animation_request_service.gd")

# We mock GameState, UnitManager, and node movement
class FakeGameState extends GameState:
	pass

class FakeConfig extends GameSessionBuilder.Config:
	pass

func _make_service() -> AnimService:
	var s: AnimService = AnimService.new()
	var state := FakeGameState.new({})
	var mgr := UnitManager.new()
	add_child(mgr)
	state.unit_manager = mgr
	var config := FakeConfig.new()
	s.setup(state, config)
	add_child(s)
	return s

func after_test() -> void:
	for child in get_children():
		if is_instance_valid(child):
			child.queue_free()

# ---------------------------------------------------------------------------
# on_unit_moved
# ---------------------------------------------------------------------------

func test_on_unit_moved_emits_animation_requested() -> void:
	var svc: AnimService = _make_service()
	var mgr: UnitManager = svc._unit_manager
	var unit = auto_free(Unit.new())
	add_child(unit)
	unit.action_points_template = ActionPointsComponent.new()
	unit.res = unit.action_points_template
	mgr.add_unit(unit, Vector2i(0, 0), true)

	var monitor := monitor_signals(svc)
	svc.on_unit_moved(0, Vector2i(1, 1))

	# The signal should fire
	assert_signal(monitor).is_emitted("animation_requested")
	# Since we pass index 0, unit manager fetched the unit and requested a move.

func test_on_unit_moved_ignores_invalid_index() -> void:
	var svc: AnimService = _make_service()
	var monitor := monitor_signals(svc)
	svc.on_unit_moved(99, Vector2i(1, 1)) # invalid index
	assert_signal(monitor).is_not_emitted("animation_requested")

func test_on_unit_moved_ignores_null_unit_manager() -> void:
	var svc: AnimService = _make_service()
	# remove the manager explicitly
	svc._unit_manager.queue_free()
	svc._unit_manager = null
	var monitor := monitor_signals(svc)
	svc.on_unit_moved(0, Vector2i(1, 1))
	assert_signal(monitor).is_not_emitted("animation_requested")

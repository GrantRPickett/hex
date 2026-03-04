extends GdUnitTestSuite

# Tests for HUDHoverService.update_hover_info() and force_hover_update().
# We use a minimal fake controller that matches the duck-typed interface
# expected by HUDHoverService and the HoverState subclasses.

const HoverServiceScript := preload("res://GUI/HUD/hud_hover_service.gd")

# Minimal fake HoverState for tracking calls
class FakeHoverState extends HoverState:
	var can_enter_result: bool = false
	var entered: bool = false
	var updated: bool = false
	var exited: bool = false

	func can_enter(_controller: Node, _cell: Vector2i) -> bool:
		return can_enter_result

	func update(_controller: Node, _cell: Vector2i) -> void:
		updated = true

	func enter(_controller: Node, _cell: Vector2i) -> void:
		entered = true

	func exit(_controller: Node) -> void:
		exited = true

# Minimal fake controller — duck-typed to satisfy HUDHoverService checks
class FakeHoverController extends Node:
	var _unit_manager: Node = null
	var _grid: Node = null
	@warning_ignore("unused_private_class_variable")
	var _logged_warnings: Dictionary = {}

var _service: HUDHoverService
var _ctrl: FakeHoverController

func before_test() -> void:
	_ctrl = FakeHoverController.new()
	add_child(_ctrl)
	_service = HoverServiceScript.new()
	add_child(_service)
	# Bypass setup() and _init_hover_states() by setting controller directly
	_service._controller = _ctrl
	_service._hover_states = []
	_service._active_hover_states = []

func after_test() -> void:
	if is_instance_valid(_service):
		_service.queue_free()
	if is_instance_valid(_ctrl):
		_ctrl.queue_free()

# ---------------------------------------------------------------------------
# update_hover_info — dependency validation
# ---------------------------------------------------------------------------

func test_update_hover_info_clears_states_when_no_unit_manager() -> void:
	_ctrl._unit_manager = null
	_ctrl._grid = Node.new()
	add_child(_ctrl._grid)
	var state: FakeHoverState = FakeHoverState.new()
	state.can_enter_result = true
	_service._active_hover_states = [state as HoverState]
	_service.update_hover_info(Vector2i.ZERO)
	# Dependencies invalid → should exit active states
	assert_bool(state.exited).is_true()
	assert_int(_service._active_hover_states.size()).is_equal(0)
	_ctrl._grid.queue_free()

func test_update_hover_info_clears_states_when_no_grid() -> void:
	_ctrl._unit_manager = Node.new()
	add_child(_ctrl._unit_manager)
	_ctrl._grid = null
	var state: FakeHoverState = FakeHoverState.new()
	_service._active_hover_states = [state as HoverState]
	_service.update_hover_info(Vector2i.ZERO)
	assert_bool(state.exited).is_true()
	_ctrl._unit_manager.queue_free()

# ---------------------------------------------------------------------------
# update_hover_info — entering / updating / exiting states
# ---------------------------------------------------------------------------

func _setup_valid_deps() -> void:
	_ctrl._unit_manager = Node.new()
	_ctrl._grid = Node.new()
	add_child(_ctrl._unit_manager)
	add_child(_ctrl._grid)

func _cleanup_valid_deps() -> void:
	if is_instance_valid(_ctrl._unit_manager):
		_ctrl._unit_manager.queue_free()
	if is_instance_valid(_ctrl._grid):
		_ctrl._grid.queue_free()

func test_update_hover_enters_state_when_can_enter_true() -> void:
	_setup_valid_deps()
	var state: FakeHoverState = FakeHoverState.new()
	state.can_enter_result = true
	_service._hover_states = [state as HoverState]
	_service.update_hover_info(Vector2i.ZERO)
	assert_bool(state.entered).is_true()
	assert_int(_service._active_hover_states.size()).is_equal(1)
	_cleanup_valid_deps()

func test_update_hover_does_not_enter_state_when_can_enter_false() -> void:
	_setup_valid_deps()
	var state: FakeHoverState = FakeHoverState.new()
	state.can_enter_result = false
	_service._hover_states = [state as HoverState]
	_service.update_hover_info(Vector2i.ZERO)
	assert_bool(state.entered).is_false()
	assert_int(_service._active_hover_states.size()).is_equal(0)
	_cleanup_valid_deps()

func test_update_hover_exits_state_that_no_longer_can_enter() -> void:
	_setup_valid_deps()
	var state: FakeHoverState = FakeHoverState.new()
	state.can_enter_result = true
	_service._hover_states = [state as HoverState]
	_service.update_hover_info(Vector2i.ZERO) # enters
	state.can_enter_result = false
	_service.update_hover_info(Vector2i(1, 1)) # should now exit
	assert_bool(state.exited).is_true()
	assert_int(_service._active_hover_states.size()).is_equal(0)
	_cleanup_valid_deps()

func test_update_hover_calls_update_for_already_active_state() -> void:
	_setup_valid_deps()
	var state: FakeHoverState = FakeHoverState.new()
	state.can_enter_result = true
	_service._hover_states = [state as HoverState]
	_service._active_hover_states = [state as HoverState] # pre-populate as active
	_service.update_hover_info(Vector2i.ZERO)
	# State was already active → should call update(), not enter()
	assert_bool(state.updated).is_true()
	assert_bool(state.entered).is_false()
	_cleanup_valid_deps()

func test_update_hover_multiple_states_only_active_ones_entered() -> void:
	_setup_valid_deps()
	var active_state: FakeHoverState = FakeHoverState.new()
	active_state.can_enter_result = true
	var inactive_state: FakeHoverState = FakeHoverState.new()
	inactive_state.can_enter_result = false
	_service._hover_states = [active_state as HoverState, inactive_state as HoverState]
	_service.update_hover_info(Vector2i.ZERO)
	assert_bool(active_state.entered).is_true()
	assert_bool(inactive_state.entered).is_false()
	assert_int(_service._active_hover_states.size()).is_equal(1)
	_cleanup_valid_deps()

# ---------------------------------------------------------------------------
# force_hover_update — no grid → early return
# ---------------------------------------------------------------------------

func test_force_hover_update_does_nothing_when_grid_invalid() -> void:
	_ctrl._grid = null
	_ctrl._unit_manager = Node.new()
	add_child(_ctrl._unit_manager)
	var state: FakeHoverState = FakeHoverState.new()
	_service._active_hover_states = [state as HoverState]
	_service.force_hover_update()
	# Should not crash; warning logged; no state changes
	assert_bool(state.exited).is_false()
	_ctrl._unit_manager.queue_free()

extends GdUnitTestSuite

# Tests for AnimationStyleSet.get_style() and related HoverState can_enter/update logic.
# HoverState subclasses use a plain Node as their controller with duck-typed properties —
# we supply minimal fake controllers to exercise each branch.

const AnimationStyleSetScript := preload("res://Resources/animation_styles/animation_style_set.gd")
const AnimationStyleScript := preload("res://Resources/animation_styles/animation_style.gd")

# ============================================================================
# AnimationStyleSet.get_style
# ============================================================================

func _make_style(id: StringName) -> AnimationStyle:
	var s: AnimationStyle = AnimationStyleScript.new()
	s.style_id = id
	auto_free(s)
	return s

func test_get_style_finds_matching_style() -> void:
	var style_set: AnimationStyleSet = AnimationStyleSetScript.new()
	auto_free(style_set)
	var s: AnimationStyle = _make_style(&"bounce")
	style_set.styles.append(s)
	var found: AnimationStyle = style_set.get_style(&"bounce")
	assert_object(found).is_not_null()
	assert_str(String(found.style_id)).is_equal("bounce")

func test_get_style_returns_null_for_unknown_id() -> void:
	var style_set: AnimationStyleSet = AnimationStyleSetScript.new()
	auto_free(style_set)
	var s: AnimationStyle = _make_style(&"fade")
	style_set.styles.append(s)
	assert_object(style_set.get_style(&"unknown")).is_null()

func test_get_style_returns_null_for_empty_set() -> void:
	var style_set: AnimationStyleSet = AnimationStyleSetScript.new()
	auto_free(style_set)
	assert_object(style_set.get_style(&"anything")).is_null()

func test_get_style_returns_first_match() -> void:
	var style_set: AnimationStyleSet = AnimationStyleSetScript.new()
	auto_free(style_set)
	var s1: AnimationStyle = _make_style(&"slide")
	var s2: AnimationStyle = _make_style(&"slide")
	s2.duration = 9.9
	style_set.styles.append(s1)
	style_set.styles.append(s2)
	var found: AnimationStyle = style_set.get_style(&"slide")
	# Should return the first one (duration 0.3 default)
	assert_float(found.duration).is_not_equal(9.9)

func test_get_style_skips_null_entries() -> void:
	var style_set: AnimationStyleSet = AnimationStyleSetScript.new()
	auto_free(style_set)
	style_set.styles.append(null) # null guard in the loop
	var s: AnimationStyle = _make_style(&"pop")
	style_set.styles.append(s)
	assert_object(style_set.get_style(&"pop")).is_not_null()

# ============================================================================
# HoverState subclasses — can_enter / update with fake controllers
# ============================================================================

# Minimal fake controller that satisfies duck-typing for the hover states.
# Each state accesses _components.<panel>, _terrain_map, _location_service, etc.
class FakeComponents extends RefCounted:
	var terrain_details: Node = Node.new()
	var unit_details: Node = Node.new()
	var location_details: Node = Node.new()
	var task_details: Node = Node.new()

class FakeTerrainMapForHover extends RefCounted:
	var _terrain: Variant = null
	func get_terrain(_cell: Vector2i) -> Variant:
		return _terrain

class FakeUnitManagerForHover extends RefCounted:
	var _unit_index: int = -1
	var _unit: Variant = null
	func index_of_unit_at(_cell: Vector2i) -> int:
		return _unit_index
	func get_unit(_idx: int) -> Variant:
		return _unit

class FakeLocationService extends RefCounted:
	var _data: Dictionary = {}
	func get_location_data_at_coordinate(_cell: Vector2i) -> Dictionary:
		return _data

class FakeTaskController extends RefCounted:
	var _task_data: Dictionary = {}
	func get_task_at_coord(_cell: Vector2i) -> Dictionary:
		return _task_data

class FakeController extends Node:
	# _components is accessed by hover states via controller._components.<panel>
	var _components: FakeComponents
	var _terrain_map: FakeTerrainMapForHover = null
	var _location_service: FakeLocationService = null
	var _task_controller: FakeTaskController = null
	@warning_ignore("unused_signal")
	signal terrain_details_updated(terrain, dist_str)
	@warning_ignore("unused_signal")
	signal unit_details_updated(unit, terrain_map, unit_manager)
	@warning_ignore("unused_signal")
	signal location_details_updated(data)
	@warning_ignore("unused_signal")
	signal task_details_updated(data)
	func _init() -> void:
		_components = FakeComponents.new()
	func calculate_distance_to_cell(_cell: Vector2i) -> String:
		return "2 tiles"

# --- TerrainHoverState ---

func test_terrain_hover_can_enter_false_when_no_terrain_map() -> void:
	var state: TerrainHoverState = TerrainHoverState.new()
	auto_free(state)
	var ctrl: FakeController = FakeController.new()
	add_child(ctrl)
	ctrl._terrain_map = null
	assert_bool(state.can_enter(ctrl, Vector2i.ZERO)).is_false()
	ctrl.queue_free()

func test_terrain_hover_can_enter_false_when_null_terrain() -> void:
	var state: TerrainHoverState = TerrainHoverState.new()
	auto_free(state)
	var ctrl: FakeController = FakeController.new()
	add_child(ctrl)
	var tm: FakeTerrainMapForHover = FakeTerrainMapForHover.new()
	tm._terrain = null
	ctrl._terrain_map = tm
	assert_bool(state.can_enter(ctrl, Vector2i.ZERO)).is_false()
	ctrl.queue_free()

func test_terrain_hover_update_emits_signal() -> void:
	var state: TerrainHoverState = TerrainHoverState.new()
	auto_free(state)
	var ctrl: FakeController = FakeController.new()
	add_child(ctrl)
	var tm: FakeTerrainMapForHover = FakeTerrainMapForHover.new()
	# Provide a real TerrainTile-like object that isn't NullTerrain
	var tile: TerrainTile = TerrainTile.new()
	add_child(tile)
	tm._terrain = tile
	ctrl._terrain_map = tm
	var monitor := monitor_signals(ctrl)
	state.update(ctrl, Vector2i.ZERO)
	assert_signal(monitor).is_emitted("terrain_details_updated")
	tile.queue_free()
	ctrl.queue_free()

# --- LocationHoverState ---

func test_location_hover_can_enter_false_when_no_service() -> void:
	var state: LocationHoverState = LocationHoverState.new()
	auto_free(state)
	var ctrl: FakeController = FakeController.new()
	add_child(ctrl)
	ctrl._location_service = null
	assert_bool(state.can_enter(ctrl, Vector2i.ZERO)).is_false()
	ctrl.queue_free()

func test_location_hover_can_enter_false_when_empty_data() -> void:
	var state: LocationHoverState = LocationHoverState.new()
	auto_free(state)
	var ctrl: FakeController = FakeController.new()
	add_child(ctrl)
	var svc: FakeLocationService = FakeLocationService.new()
	svc._data = {}
	ctrl._location_service = svc
	assert_bool(state.can_enter(ctrl, Vector2i.ZERO)).is_false()
	ctrl.queue_free()

func test_location_hover_can_enter_true_when_data_present() -> void:
	var state: LocationHoverState = LocationHoverState.new()
	auto_free(state)
	var ctrl: FakeController = FakeController.new()
	add_child(ctrl)
	var svc: FakeLocationService = FakeLocationService.new()
	svc._data = {"name": "Village", "coord": Vector2i(1, 1)}
	ctrl._location_service = svc
	assert_bool(state.can_enter(ctrl, Vector2i.ZERO)).is_true()
	ctrl.queue_free()

func test_location_hover_update_emits_signal() -> void:
	var state: LocationHoverState = LocationHoverState.new()
	auto_free(state)
	var ctrl: FakeController = FakeController.new()
	add_child(ctrl)
	var svc: FakeLocationService = FakeLocationService.new()
	svc._data = {"name": "Village"}
	ctrl._location_service = svc
	var monitor := monitor_signals(ctrl)
	state.update(ctrl, Vector2i.ZERO)
	assert_signal(monitor).is_emitted("location_details_updated")
	ctrl.queue_free()

# --- TaskHoverState ---

func test_task_hover_can_enter_false_when_no_task_controller() -> void:
	var state: TaskHoverState = TaskHoverState.new()
	auto_free(state)
	var ctrl: FakeController = FakeController.new()
	add_child(ctrl)
	ctrl._task_controller = null
	assert_bool(state.can_enter(ctrl, Vector2i.ZERO)).is_false()
	ctrl.queue_free()

func test_task_hover_can_enter_false_when_no_task_at_coord() -> void:
	var state: TaskHoverState = TaskHoverState.new()
	auto_free(state)
	var ctrl: FakeController = FakeController.new()
	add_child(ctrl)
	var tc: FakeTaskController = FakeTaskController.new()
	tc._task_data = {} # empty = no task
	ctrl._task_controller = tc
	assert_bool(state.can_enter(ctrl, Vector2i.ZERO)).is_false()
	ctrl.queue_free()

func test_task_hover_can_enter_true_when_task_present() -> void:
	var state: TaskHoverState = TaskHoverState.new()
	auto_free(state)
	var ctrl: FakeController = FakeController.new()
	add_child(ctrl)
	var tc: FakeTaskController = FakeTaskController.new()
	tc._task_data = {"title": "Fetch Quest"}
	ctrl._task_controller = tc
	assert_bool(state.can_enter(ctrl, Vector2i.ZERO)).is_true()
	ctrl.queue_free()

func test_task_hover_update_emits_signal() -> void:
	var state: TaskHoverState = TaskHoverState.new()
	auto_free(state)
	var ctrl: FakeController = FakeController.new()
	add_child(ctrl)
	var tc: FakeTaskController = FakeTaskController.new()
	tc._task_data = {"title": "Patrol"}
	ctrl._task_controller = tc
	var monitor := monitor_signals(ctrl)
	state.update(ctrl, Vector2i.ZERO)
	assert_signal(monitor).is_emitted("task_details_updated")
	ctrl.queue_free()

func after_test() -> void:
	for child in get_children():
		if is_instance_valid(child):
			child.queue_free()

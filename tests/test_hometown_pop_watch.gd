extends GdUnitTestSuite

# Tests for HometownProgressionService.pop_skit() and watch_skit() —
# the two remaining uncovered functions in that service.
# Uses the same FakeCatalog/FakeSaveManager pattern from test_hometown_progression_service.gd.

const ServiceScript := preload("res://Gameplay/hometown_progression_service.gd")
const SkitScript := preload("res://Gameplay/narrative/dialogue/skit.gd")
const SaveManagerScript := preload("res://Autoloads/save_manager.gd")

class FakeCatalog extends LevelCatalog:
	var _levels_override: Array[Dictionary] = []
	func get_levels() -> Array[Dictionary]:
		return _levels_override

class FakeSaveManager extends SaveManagerScript:
	var _skits: Array[Skit] = []
	func get_all_skits() -> Array[Skit]:
		return _skits
	func mark_skit_seen(_id: String) -> void:
		pass

var _save_node: FakeSaveManager

func before_test() -> void:
	_save_node = FakeSaveManager.new()
	add_child(_save_node)

func after_test() -> void:
	if is_instance_valid(_save_node):
		_save_node.queue_free()

func _make_service(level_ids: Array, skits: Array[Skit]) -> HometownProgressionService:
	var catalog: FakeCatalog = FakeCatalog.new()
	auto_free(catalog)
	for lid in level_ids:
		catalog._levels_override.append({"id": lid})
	_save_node._skits = skits
	return auto_free(ServiceScript.new(catalog, _save_node))

func _make_skit(level_id: String, seen: bool, unlocked: bool, path: String = "res://d.dialogue") -> Skit:
	var s: Skit = SkitScript.new()
	s.level_id = level_id
	s.seen = seen
	s.unlocked = unlocked
	s.dialogue_path = path
	return s

# ---------------------------------------------------------------------------
# pop_skit
# ---------------------------------------------------------------------------

func test_pop_skit_returns_null_when_no_skits() -> void:
	var service: HometownProgressionService = _make_service([], [])
	assert_object(service.pop_skit()).is_null()

func test_pop_skit_returns_null_when_all_locked() -> void:
	var s: Skit = _make_skit("lv1", false, false)
	var service: HometownProgressionService = _make_service(["lv1"], [s])
	assert_object(service.pop_skit()).is_null()

func test_pop_skit_returns_null_when_all_seen() -> void:
	var s: Skit = _make_skit("lv1", true, true)
	var service: HometownProgressionService = _make_service(["lv1"], [s])
	assert_object(service.pop_skit()).is_null()

func test_pop_skit_returns_first_unlocked_unseen_skit() -> void:
	var s1: Skit = _make_skit("lv1", false, true)
	var s2: Skit = _make_skit("lv2", false, true)
	var service: HometownProgressionService = _make_service(["lv1", "lv2"], [s1, s2])
	var popped: Skit = service.pop_skit()
	assert_object(popped).is_not_null()
	assert_str(popped.level_id).is_equal("lv1")

func test_pop_skit_returns_earliest_by_level_order() -> void:
	# s2 is at lv1 (earlier), s1 is at lv2
	var s1: Skit = _make_skit("lv2", false, true)
	var s2: Skit = _make_skit("lv1", false, true)
	var service: HometownProgressionService = _make_service(["lv1", "lv2"], [s1, s2])
	var popped: Skit = service.pop_skit()
	assert_str(popped.level_id).is_equal("lv1")

func test_pop_skit_skips_locked_prefers_unlocked() -> void:
	var locked: Skit = _make_skit("lv1", false, false)
	var unlocked: Skit = _make_skit("lv2", false, true)
	var service: HometownProgressionService = _make_service(["lv1", "lv2"], [locked, unlocked])
	var popped: Skit = service.pop_skit()
	assert_str(popped.level_id).is_equal("lv2")

# ---------------------------------------------------------------------------
# watch_skit
# ---------------------------------------------------------------------------

func test_watch_skit_queues_dialogue_for_first_skit() -> void:
	var s: Skit = _make_skit("lv1", false, true, "res://Dialogues/intro.dialogue")
	var service: HometownProgressionService = _make_service(["lv1"], [s])
	var monitor := monitor_signals(service)
	service.watch_skit()
	assert_signal(monitor).is_emitted("dialogue_queued")
	assert_signal(monitor).is_emitted("all_dialogues_queued")
	assert_int(service._queued_dialogues.size()).is_equal(1)
	assert_str(service._queued_dialogues[0]).is_equal("res://Dialogues/intro.dialogue")

func test_watch_skit_does_nothing_when_no_skit_available() -> void:
	var service: HometownProgressionService = _make_service([], [])
	var monitor := monitor_signals(service)
	service.watch_skit()
	assert_signal(monitor).is_not_emitted("dialogue_queued")
	assert_signal(monitor).is_not_emitted("all_dialogues_queued")
	assert_int(service._queued_dialogues.size()).is_equal(0)

func test_watch_skit_does_not_add_duplicate_if_called_twice() -> void:
	var s: Skit = _make_skit("lv1", false, true, "res://Dialogues/intro.dialogue")
	var service: HometownProgressionService = _make_service(["lv1"], [s])
	service.watch_skit()
	service.watch_skit() # second call: same path → deduped
	assert_int(service._queued_dialogues.size()).is_equal(1)

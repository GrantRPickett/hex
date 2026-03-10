extends GdUnitTestSuite

# Tests for HometownProgressionService — pure RefCounted logic.
# Uses subclassed fakes to satisfy static type requirements.
# Focus: sort_skits_by_level, filter_skits_by_unseen, filter_skits_by_unlocked,
#		 queue_dialogue, get_all_level_ids

const ServiceScript := preload("res://Gameplay/hometown_progression_service.gd")
const SkitScript := preload("res://Gameplay/narrative/dialogue/skit.gd")

# Extends LevelCatalog (RefCounted) to override get_levels().
class FakeCatalog extends LevelCatalog:
	var _levels: Array[Dictionary] = []
	func get_levels() -> Array[Dictionary]:
		return _levels

# Extends the SaveManager Node script to satisfy static typing in HometownProgressionService._init().
# We override get_all_skits() so no real save file is needed.
const SaveManagerScript := preload("res://Autoloads/save_manager.gd")
class FakeSaveManager extends SaveManagerScript:
	var _skits: Array[Skit] = []
	func get_all_skits() -> Array[Skit]:
		return _skits
	func mark_skit_seen(_id: String) -> void:
		pass

var _save_manager_node: FakeSaveManager

func before_test() -> void:
	_save_manager_node = FakeSaveManager.new()
	add_child(_save_manager_node)

func after_test() -> void:
	if is_instance_valid(_save_manager_node):
		_save_manager_node.queue_free()

func _make_service(level_ids: Array, skits: Array[Skit]) -> HometownProgressionService:
	var catalog: FakeCatalog = FakeCatalog.new()
	auto_free(catalog)
	for lid in level_ids:
		catalog._levels.append({"id": lid})
	_save_manager_node._skits = skits
	var service: HometownProgressionService = ServiceScript.new(catalog, _save_manager_node)
	auto_free(service)
	return service

func _make_skit(level_id: String, seen: bool = false, unlocked: bool = true, path: String = "") -> Skit:
	var s: Skit = SkitScript.new()
	s.level_id = level_id
	s.seen = seen
	s.unlocked = unlocked
	s.dialogue_path = path
	return s

# ---------------------------------------------------------------------------
# get_all_level_ids
# ---------------------------------------------------------------------------

func test_get_all_level_ids_returns_ids_in_order() -> void:
	var service: HometownProgressionService = _make_service(["lv1", "lv2", "lv3"], [])
	var ids := service.get_all_level_ids()
	assert_int(ids.size()).is_equal(3)
	assert_str(ids[0]).is_equal("lv1")
	assert_str(ids[2]).is_equal("lv3")

func test_get_all_level_ids_empty_catalog() -> void:
	var service: HometownProgressionService = _make_service([], [])
	assert_int(service.get_all_level_ids().size()).is_equal(0)

# ---------------------------------------------------------------------------
# sort_skits_by_level
# ---------------------------------------------------------------------------

func test_sort_skits_by_level_orders_by_catalog_index() -> void:
	var s1: Skit = _make_skit("lv3")
	var s2: Skit = _make_skit("lv1")
	var s3: Skit = _make_skit("lv2")
	var service: HometownProgressionService = _make_service(["lv1", "lv2", "lv3"], [])
	var sorted := service.sort_skits_by_level([s1, s2, s3])
	assert_str(sorted[0].level_id).is_equal("lv1")
	assert_str(sorted[1].level_id).is_equal("lv2")
	assert_str(sorted[2].level_id).is_equal("lv3")

func test_sort_skits_does_not_mutate_original_array() -> void:
	var s1: Skit = _make_skit("lv2")
	var s2: Skit = _make_skit("lv1")
	var original := [s1, s2]
	var service: HometownProgressionService = _make_service(["lv1", "lv2"], [])
	service.sort_skits_by_level(original)
	# Original should still start with s1 (lv2)
	assert_str(original[0].level_id).is_equal("lv2")

# ---------------------------------------------------------------------------
# filter_skits_by_unseen
# ---------------------------------------------------------------------------

func test_filter_skits_by_unseen_returns_only_unseen() -> void:
	var seen_skit: Skit = _make_skit("lv1", true)
	var unseen_skit: Skit = _make_skit("lv2", false)
	var service: HometownProgressionService = _make_service(["lv1", "lv2"], [])
	var result := service.filter_skits_by_unseen([seen_skit, unseen_skit])
	assert_int(result.size()).is_equal(1)
	assert_str(result[0].level_id).is_equal("lv2")

func test_filter_skits_by_unseen_empty_when_all_seen() -> void:
	var s: Skit = _make_skit("lv1", true)
	var service: HometownProgressionService = _make_service(["lv1"], [])
	assert_int(service.filter_skits_by_unseen([s]).size()).is_equal(0)

func test_filter_skits_by_unseen_returns_all_when_none_seen() -> void:
	var skits: Array[Skit] = [_make_skit("lv1", false), _make_skit("lv2", false)]
	var service: HometownProgressionService = _make_service(["lv1", "lv2"], [])
	assert_int(service.filter_skits_by_unseen(skits).size()).is_equal(2)

# ---------------------------------------------------------------------------
# filter_skits_by_unlocked
# ---------------------------------------------------------------------------

func test_filter_skits_by_unlocked_returns_only_unlocked() -> void:
	var locked: Skit = _make_skit("lv1", false, false)
	var unlocked: Skit = _make_skit("lv2", false, true)
	var service: HometownProgressionService = _make_service(["lv1", "lv2"], [])
	var result := service.filter_skits_by_unlocked([locked, unlocked])
	assert_int(result.size()).is_equal(1)
	assert_str(result[0].level_id).is_equal("lv2")

func test_filter_skits_by_unlocked_empty_when_all_locked() -> void:
	var s: Skit = _make_skit("lv1", false, false)
	var service: HometownProgressionService = _make_service(["lv1"], [])
	assert_int(service.filter_skits_by_unlocked([s]).size()).is_equal(0)

# ---------------------------------------------------------------------------
# queue_dialogue
# ---------------------------------------------------------------------------

func test_queue_dialogue_adds_path_and_emits_signal() -> void:
	var service: HometownProgressionService = _make_service([], [])
	var monitor := monitor_signals(service)
	service.queue_dialogue("res://Dialogues/intro.dialogue")
	assert_signal(monitor).is_emitted("dialogue_queued")
	assert_int(service._queued_dialogues.size()).is_equal(1)

func test_queue_dialogue_deduplicates_same_path() -> void:
	var service: HometownProgressionService = _make_service([], [])
	service.queue_dialogue("res://Dialogues/intro.dialogue")
	service.queue_dialogue("res://Dialogues/intro.dialogue")
	assert_int(service._queued_dialogues.size()).is_equal(1)

func test_queue_dialogue_allows_different_paths() -> void:
	var service: HometownProgressionService = _make_service([], [])
	service.queue_dialogue("res://Dialogues/a.dialogue")
	service.queue_dialogue("res://Dialogues/b.dialogue")
	assert_int(service._queued_dialogues.size()).is_equal(2)

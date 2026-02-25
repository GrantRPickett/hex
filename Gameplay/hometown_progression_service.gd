class_name HometownProgressionService
extends RefCounted

signal dialogue_queued(dialogue_path: String)
signal all_dialogues_queued

var _catalog: LevelCatalog
var _save_manager: SaveManager
var _queued_dialogues: Array[String] = []
var level_ids_cache: Array[String] = []

func _init(catalog: LevelCatalog, save_manager: SaveManager) -> void:
	_catalog = catalog
	_save_manager = save_manager
	get_all_level_ids() # cache level ids for sorting skits

func get_all_level_ids() -> Array[String]:
	var level_ids: Array[String] = []
	for level in _catalog.get_levels():
		level_ids.append(level.get("id", ""))
	level_ids_cache = level_ids
	return level_ids

func get_all_skits() -> Array[Skit]:
	return _save_manager.get_all_skits()

func sort_skits_by_level(skits: Array[Skit]) -> Array[Skit]:
	var sorted_skits = skits.duplicate()
	sorted_skits.sort_custom(func(a, b):
		var level_a = level_ids_cache.find(a.level_id)
		var level_b = level_ids_cache.find(b.level_id)
		return level_a < level_b
	)
	return sorted_skits

func filter_skits_by_unseen(skits: Array[Skit]) -> Array[Skit]:
	return skits.filter(func(skit):
		return not skit.seen
	)
func filter_skits_by_unlocked(skits: Array[Skit]) -> Array[Skit]:
	return skits.filter(func(skit):
		return skit.unlocked
	)

func queue_dialogue(dialogue_path: String) -> void:
	if dialogue_path in _queued_dialogues:
		return
	_queued_dialogues.append(dialogue_path)
	dialogue_queued.emit(dialogue_path)

func pop_skit() -> Skit:
	var available_skits = get_all_skits()
	# show unlocked skits by checking unlocked filter for unseen skits, then by level order
	available_skits = filter_skits_by_unlocked(available_skits)
	available_skits = filter_skits_by_unseen(available_skits)
	available_skits = sort_skits_by_level(available_skits)

	if available_skits.is_empty():
		return null
	return available_skits.front()

func watch_skit() -> void:
	var skit = pop_skit()
	if skit:
		queue_dialogue(skit.dialogue_path)
		all_dialogues_queued.emit()

func mark_skit_seen(skit_id: String) -> void:
	_save_manager.mark_skit_seen(skit_id)

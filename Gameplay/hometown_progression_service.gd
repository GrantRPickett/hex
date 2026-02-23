class_name HometownProgressionService
extends RefCounted

signal dialogue_queued(dialogue_path: String)
signal all_dialogues_queued

var _catalog: LevelCatalog
var _save_manager: SaveManager
var _queued_dialogues: Array[String] = []
var skits: Array[Skit] = []
var level_ids_cache: Array[String] = []

func _init(catalog: LevelCatalog, save_manager: SaveManager) -> void:
	_catalog = catalog
	_save_manager = save_manager

func get_all_level_ids() -> Array[String]:
	var level_ids: Array[String] = []
	for level in _catalog.get_all_levels():
		level_ids.append(level.id)
	level_ids_cache = level_ids
	return level_ids

class Skit:
	var id: String
	var dialogue_path: String
	var seen: bool
	var unlocked: bool
	var level_id: String

func get_all_skits() -> Array[Skit]:
	var skits: Array[Skit] = []
	skits = _save_manager.get_all_skits()
	return skits

func sort_skits_by_level(skits: Array[Skit]) -> Array[Skit]:
	return skits.sorted(func(a, b):
		var level_a = level_ids_cache.find(a.level_id)
		var level_b = level_ids_cache.find(b.level_id)
		return level_a < level_b
	)

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
	emit_signal("dialogue_queued", dialogue_path)

func pop_skit() -> Skit:
	var skits = get_all_skits()
	#show unlocked skits by checking unlocked filter for unseen skits, then by level order
	skits = filter_skits_by_unlocked(skits)
	skits = filter_skits_by_unseen(skits)
	skits = sort_skits_by_level(skits)
	for skit in skits:
		return skit
	#log if we got here, then there are no skits to show
	print_debug("No skits to show")
	return null

func watch_skit() -> void:
	var skit = pop_skit()
	if skit:
		queue_dialogue(skit.dialogue_path)
		emit_signal("all_dialogues_queued")

func mark_skit_seen(skit_id: String) -> void:
	_save_manager.mark_skit_seen(skit_id)
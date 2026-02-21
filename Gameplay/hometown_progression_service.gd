class_name HometownProgressionService
extends RefCounted

signal dialogue_queued(dialogue_path: String)
signal all_dialogues_queued

var _catalog: LevelCatalog
var _save_manager: Node
var _progress_store
var _queued_dialogues: Array[String] = []

func _init(catalog: LevelCatalog, save_manager: Node, progress_store) -> void:
	_catalog = catalog
	_save_manager = save_manager
	_progress_store = progress_store

func queue_newly_unlocked_dialogues() -> Array[String]:
	"""
	For each level that just became complete, check if it has a
	hometown dialogue skit and queue it.
	Returns array of dialogue paths ready to be played.
	"""
	_queued_dialogues.clear()

	# Load tracking of which skits we've already shown
	var shown_skits: Dictionary = _save_manager.get_data("hometown_skits_shown", {}) if _save_manager else {}

	for level_entry in _catalog.get_levels():
		var level_id: String = level_entry.get("id", "")
		if level_id.is_empty() or level_id == "hometown":
			continue

		# Check if this level is complete
		if not _progress_store or not _progress_store.is_level_completed(level_id):
			continue

		# Check if we've already shown its skit
		var skit_key := level_id + "_hometown_skit"
		if shown_skits.get(skit_key, false):
			continue

		# Look for dialogue_resource_path on a "completion_skit" entry
		var skit_path: String = _get_level_completion_skit(level_id)
		if not skit_path.is_empty():
			_queued_dialogues.append(skit_path)
			shown_skits[skit_key] = true
			dialogue_queued.emit(skit_path)

	# Save updated skit tracking
	if _save_manager:
		_save_manager.set_data("hometown_skits_shown", shown_skits)

	all_dialogues_queued.emit()
	return _queued_dialogues

func get_queued_dialogues() -> Array[String]:
	"""Returns the most recently queued dialogues."""
	return _queued_dialogues.duplicate()

func _get_level_completion_skit(level_id: String) -> String:
	"""
	Fetch the hometown-return dialogue for this level.
	Convention: LevelDialogueRow with entry_id = "{level_id}_hometown_skit"
	or load from a dedicated homepage dialogue registry.

	This is a placeholder that can be extended to load from ResourceTables.
	"""
	# Use FilePaths helper for hometown-prefixed dialogue files
	var skit_map := {
		"level_1": FilePaths.DynamicPaths.get_dialogue_path("hometown", "level_1_return"),
		"level_2": FilePaths.DynamicPaths.get_dialogue_path("hometown", "level_2_return"),
		"level_3": FilePaths.DynamicPaths.get_dialogue_path("hometown", "level_3_return"),
		"test_level": FilePaths.DynamicPaths.get_dialogue_path("hometown", "test_level_return"),
	}
	return skit_map.get(level_id, "")

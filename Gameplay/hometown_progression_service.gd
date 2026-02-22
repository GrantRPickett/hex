class_name HometownProgressionService
extends RefCounted

signal dialogue_queued(dialogue_path: String)
signal all_dialogues_queued

var _catalog: LevelCatalog
var _save_manager: SaveManager
var _progress_store
var _queued_dialogues: Array[String] = []

func _init(catalog: LevelCatalog, save_manager: SaveManager, progress_store) -> void:
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

	# Get all levels from the catalog
	var all_levels: Array[Dictionary] = _catalog.get_levels()
	var skits_to_update_seen_status: Dictionary = {}

	for level_info in all_levels:
		var level_id: String = level_info.get("id", "")
		if level_id.is_empty():
			continue

		# Check if the level is completed
		if _progress_store and _progress_store.is_level_completed(level_id):
			# Get the corresponding hometown skit path
			var skit_path: String = _get_level_completion_skit(level_id)

			if not skit_path.is_empty():
				# Check if this skit has already been shown
				var skits_shown: Dictionary = _save_manager.get_hometown_skits() if _save_manager else {}
				if not skits_shown.get(skit_path, false): # If false, it hasn't been shown
					_queued_dialogues.append(skit_path)
					skits_to_update_seen_status[skit_path] = true

	# Update the seen status for all newly queued skits
	if _save_manager:
		for skit_path in skits_to_update_seen_status.keys():
			_save_manager.set_hometown_skit_shown(skit_path, true)

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

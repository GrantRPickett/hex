extends Node

const AchievementResource := preload("res://Gameplay/Achievements/achievement.gd")

var achievements: Dictionary = {} # id -> Achievement

signal achievement_unlocked(achievement: AchievementResource)

# Using a recursive resource collector like JournalManager
func _collect_resources_recursive(path: String) -> Array[Resource]:
	var resources: Array[Resource] = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if not file_name.begins_with("."):
					resources.append_array(_collect_resources_recursive(path.path_join(file_name)))
			elif file_name.ends_with(".tres"):
				var res = load(path.path_join(file_name))
				if res:
					resources.append(res)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("AchievementManager: Could not open directory at %s" % path)
	return resources

func _ready() -> void:
	# Create editable instances from all achievement resources found
	var all_resources = _collect_resources_recursive("res://Resources/achievements/")
	for res in all_resources:
		if res is AchievementResource:
			var achievement_instance := res.duplicate() as AchievementResource
			if achievement_instance.id.is_empty():
				push_warning("Achievement resource has no ID: %s" % achievement_instance.resource_path)
				continue
			if not achievements.has(achievement_instance.id):
				achievements[achievement_instance.id] = achievement_instance
			else:
				push_warning("Duplicate achievement ID found: '%s'" % achievement_instance.id)

func unlock_achievement(achievement_id: String) -> bool:
	var achievement: AchievementResource = achievements.get(achievement_id)
	if achievement and not achievement.unlocked:
		achievement.unlocked = true
		achievement_unlocked.emit(achievement)
		print("AchievementManager: Unlocked achievement: %s" % achievement.title)
		return true
	elif achievement and achievement.unlocked:
		print("AchievementManager: Achievement '%s' already unlocked." % achievement_id)
	else:
		push_warning("AchievementManager: Attempted to unlock non-existent achievement: %s" % achievement_id)
	return false

func get_savable_data() -> Dictionary:
	var unlocked_ids: Array[String] = []
	for achievement in achievements.values():
		if achievement.unlocked:
			unlocked_ids.append(achievement.id)
	return {"unlocked_achievements": unlocked_ids}

func load_savable_data(data: Dictionary):
	if data.has("unlocked_achievements"):
		var unlocked_ids = data.get("unlocked_achievements", [])
		for achievement_id in unlocked_ids:
			var achievement: AchievementResource = achievements.get(achievement_id)
			if achievement:
				achievement.unlocked = true
			else:
				push_warning("AchievementManager: Saved data refers to non-existent achievement ID: %s" % achievement_id)
extends Node

var achievements: Dictionary = {} # id -> Resource (Achievement)

signal achievement_unlocked(achievement: Resource)

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
	var all_resources = _collect_resources_recursive("res://Resources/achievements/")
	for res in all_resources:
		if is_instance_valid(res):
			var ach_id = res.get("id")
			if ach_id == null or str(ach_id).is_empty():
				# Skip resources that aren't achievements
				continue

			var achievement_instance := res.duplicate() as Resource
			if not achievements.has(ach_id):
				achievements[ach_id] = achievement_instance
			else:
				push_warning("Duplicate achievement ID found: '%s'" % ach_id)

func unlock_achievement(achievement_id: String) -> bool:
	var achievement := achievements.get(achievement_id) as Resource
	if achievement and not achievement.get("unlocked"):
		achievement.set("unlocked", true)
		achievement_unlocked.emit(achievement)
		var title = achievement.get("title")
		print("AchievementManager: Unlocked achievement: %s" % (title if title else achievement_id))
		return true
	elif achievement and achievement.get("unlocked"):
		print("AchievementManager: Achievement '%s' already unlocked." % achievement_id)
	else:
		push_warning("AchievementManager: Attempted to unlock non-existent achievement: %s" % achievement_id)
	return false

func get_savable_data() -> Dictionary:
	var unlocked_ids: Array[String] = []
	for achievement in achievements.values():
		if achievement.get("unlocked"):
			var ach_id = achievement.get("id")
			if ach_id:
				unlocked_ids.append(ach_id)
	return {"unlocked_achievements": unlocked_ids}

func load_savable_data(data: Dictionary):
	if data.has("unlocked_achievements"):
		var unlocked_ids = data.get("unlocked_achievements", [])
		for achievement_id in unlocked_ids:
			var achievement: Resource = achievements.get(achievement_id)
			if achievement:
				achievement.set("unlocked", true)
			else:
				push_warning("AchievementManager: Saved data refers to non-existent achievement ID: %s" % achievement_id)

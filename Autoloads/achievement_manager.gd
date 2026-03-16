extends Node

var achievements: Dictionary = {} # id -> Resource (Achievement)

signal achievement_unlocked(achievement: Resource)

func _ready() -> void:
	var all_resources: Array = ResourceLoaderService.collect_resources_recursive("res://Resources/achievements/")
	for res in all_resources:
		if res is Resource and is_instance_valid(res):
			var ach_id: Variant = res.get("id")
			if ach_id == null or str(ach_id).is_empty():
				# Skip resources that aren't achievements
				continue

			var achievement_instance = res.duplicate()
			if achievement_instance is Resource:
				if not achievements.has(ach_id):
					achievements[ach_id] = achievement_instance
				else:
					push_warning("Duplicate achievement ID found: '%s'" % ach_id)

func unlock_achievement(achievement_id: String) -> bool:
	var achievement = achievements.get(achievement_id)
	if achievement is Resource:
		if not achievement.get("unlocked"):
			achievement.set("unlocked", true)
			achievement_unlocked.emit(achievement)
			var title: Variant = achievement.get("title")
			print("AchievementManager: Unlocked achievement: %s" % (title if title else achievement_id))
			return true
		else:
			print("AchievementManager: Achievement '%s' already unlocked." % achievement_id)
	else:
		push_warning("AchievementManager: Attempted to unlock non-existent achievement: %s" % achievement_id)
	return false

func get_savable_data() -> Dictionary:
	var unlocked_ids: Array[String] = []
	for achievement in achievements.values():
		if achievement is Resource and achievement.get("unlocked"):
			var ach_id: Variant = achievement.get("id")
			if ach_id:
				unlocked_ids.append(str(ach_id))
	return {"unlocked_achievements": unlocked_ids}

func load_savable_data(data: Dictionary) -> void:
	if data.has("unlocked_achievements"):
		var unlocked_ids: Array = data.get("unlocked_achievements", [])
		for achievement_id: String in unlocked_ids:
			var achievement = achievements.get(achievement_id)
			if achievement is Resource:
				achievement.set("unlocked", true)
			else:
				push_warning("AchievementManager: Saved data refers to non-existent achievement ID: %s" % achievement_id)

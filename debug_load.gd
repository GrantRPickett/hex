extends SceneTree

func _init():
	var script = load("res://level/level_auto_fix_service.gd")
	if script == null:
		print("Failed to load script")
	else:
		var instance = script.new()
		if instance == null:
			print("Failed to instantiate script")
		else:
			print("Successfully instantiated LevelAutoFixService")
	quit()

extends SceneTree

func _init():
	var res: Resource = load("res://Gameplay/narrative/task/task.gd")
	if res == null:
		printerr("Failed to load task.gd")
	quit()

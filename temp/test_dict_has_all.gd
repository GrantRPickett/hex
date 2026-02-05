extends SceneTree
func _init():
	var dict = {"player_progress": 1, "enemy_progress": 2, "neutral_progress": 0, "max": 5, "type": "grit"}
	print("has_all=", dict.has_all(["type", "player_progress", "enemy_progress", "neutral_progress", "max"]))
	quit()

class_name CaveEntranceTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 0
	movement_bonus = 0
	status_effect = StringName()
	blocks_action_after_move = false
	color = Color.DARK_SLATE_GRAY
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Rockface/Rock_Grey_Boulder_01.png"
	description = "The dark maw of a cave, leading to unknown depths."


class_name StoneTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 0
	movement_bonus = 0
	status_effect = StringName()
	blocks_action_after_move = false
	color = Color.SLATE_GRAY
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Stones/Stones_Loose_01_Grey_1.png"
	description = "Solid stone ground."

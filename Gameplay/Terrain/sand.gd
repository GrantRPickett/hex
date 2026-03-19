class_name SandTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 1
	movement_bonus = 0
	status_effect = StringName()
	blocks_action_after_move = false
	color = Color.SANDY_BROWN
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Sand/Sand_01_Yellow_1.png"
	description = "Soft desert sand, slowing movement."

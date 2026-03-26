class_name MudTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 1
	movement_bonus = 0
	status_effect = StringName()
	blocks_action_after_move = true
	color = GameColors.TERRAIN_MUD
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Dirt/Dirt_Silt_01_Brown_1.png"
	description = "Thick mud, slowing movement and blocking actions."

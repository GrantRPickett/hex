class_name MountainPeakTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 2
	movement_bonus = 0
	status_effect = StringName("HeightAdvantage")
	blocks_action_after_move = false
	color = GameColors.TERRAIN_MOUNTAIN_PEAK
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Rockface/Rock_Grey_01.png"
	description = "terrain.mountain_peak.description"

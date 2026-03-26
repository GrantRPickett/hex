class_name BridgeCausewayTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 0
	movement_bonus = 1
	status_effect = StringName()
	blocks_action_after_move = false
	color = GameColors.TERRAIN_BRIDGE_CAUSEWAY
	texture_path = "res://Resources/art/placeholder/PNG - Pixel Art Textures/PNGs/Wood/Wood_Planks_01_Brown_1.png"
	description = "A sturdy bridge or causeway, speeding movement."

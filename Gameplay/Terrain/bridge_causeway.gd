class_name BridgeCausewayTerrain
extends TerrainTile

func _init() -> void:
	passable = true
	movement_penalty = 0
	movement_bonus = 1
	status_effect = StringName()
	blocks_action_after_move = false
	color = Color.SIENNA
	description = "A sturdy bridge or causeway, speeding movement."

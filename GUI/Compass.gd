extends CanvasLayer

func _ready() -> void:
	# Position the compass in the top-left corner
	var control_node = $"Control"
	if control_node:
		control_node.set_position(Vector2(20, 20))

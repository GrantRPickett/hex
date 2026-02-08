extends RefCounted
class_name FeedbackDisplay

# This class will be responsible for displaying temporary feedback messages.

func _init():
	pass

func show_feedback(text: String, hud_node: Node, animation_service = null) -> void:
	if not is_instance_valid(hud_node):
		return

	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)

	hud_node.add_child(label)

	if hud_node is Control:
		label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		label.position = Vector2(hud_node.size.x / 2 - label.size.x / 2, hud_node.size.y / 2 - label.size.y / 2) # Center position
	elif hud_node is CanvasLayer:
		var viewport_size = hud_node.get_viewport().get_visible_rect().size
		label.position = Vector2(viewport_size.x / 2 - label.size.x / 2, viewport_size.y / 2 - label.size.y / 2)
	else:
		label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

	if animation_service:
		animation_service.request_feedback_float(label, Vector2(0, -50))
	else:
		var tree: SceneTree = hud_node.get_tree()
		if tree:
			var timer: SceneTreeTimer = tree.create_timer(1.0)
			timer.timeout.connect(func():
				if is_instance_valid(label):
					label.queue_free()
			)

extends RefCounted
class_name FeedbackDisplay

# This class will be responsible for displaying temporary feedback messages.

func _init():
	pass

func show_feedback(text: String, hud_node: Control) -> void:
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
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.position = Vector2(hud_node.size.x / 2 - label.size.x / 2, hud_node.size.y / 2 - label.size.y / 2) # Center position

	var tween = label.create_tween() # Tween the label directly
	tween.tween_property(label, "position", label.position + Vector2(0, -50), 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN)
	tween.tween_callback(label.queue_free)

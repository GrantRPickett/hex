class_name AnimationStyleSet
extends Resource

@export var styles: Array[AnimationStyle] = []

func get_style(style_id: StringName) -> AnimationStyle:
	for style in styles:
		if style and style.style_id == style_id:
			return style
	return null

class_name HoverInfoPanel
extends PanelContainer

@onready var _info_label: Label = %InfoLabel

func set_info(text: String) -> void:
	_info_label.text = text

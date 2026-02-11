# locationDisplayItem.gd
extends HBoxContainer

var _type_label: Label
var _progress_label: Label

func _ready() -> void:
	_type_label = get_node("TypeLabel")
	_progress_label = get_node("ProgressLabel")

func set_location_data(location_data: Dictionary) -> void:
	var required_keys = ["type", "player_progress", "enemy_progress", "neutral_progress", "max"]
	if not location_data.has_all(required_keys):
		push_error("Invalid location_data provided to locationDisplayItem.")
		return

	if _type_label and _progress_label:
		_type_label.text = location_data.type
		_progress_label.text = "P:%d/%d  E:%d  N:%d" % [
			location_data.player_progress,
			location_data.max,
			location_data.enemy_progress,
			location_data.neutral_progress
		]
	else:
		push_error("Labels not initialized in locationDisplayItem when trying to set data.")

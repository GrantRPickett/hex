# locationDisplayItem.gd
class_name LocationDisplayItem
extends HBoxContainer

signal selected(location_data: Dictionary)

var _name_label: Label
var _description_label: Label 
var _data: Dictionary

func _ready() -> void:
	_name_label = get_node("NameLabel")
	_description_label = get_node("DescriptionLabel")
	
	gui_input.connect(_on_gui_input)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected.emit(_data)

func set_location_data(location_data: Dictionary) -> void:
	_data = location_data
	if not is_instance_valid(_name_label) or not is_instance_valid(_description_label):
		push_error("Labels not initialized in LocationDisplayItem when trying to set data.")
		return

	_name_label.text = location_data.get("name", "Unknown Location")
	_description_label.text = location_data.get("description", "No description.")

# locationDisplayItem.gd
class_name LocationDisplayItem
extends HBoxContainer

var _name_label: Label
var _description_label: Label # Added for description display

func _ready() -> void:
	_name_label = get_node("NameLabel")
	_description_label = get_node("DescriptionLabel") # Get the new description label

func set_location_data(location_data: Dictionary) -> void:
	if not is_instance_valid(_name_label) or not is_instance_valid(_description_label):
		push_error("Labels not initialized in LocationDisplayItem when trying to set data.")
		return

	_name_label.text = location_data.get("name", "Unknown Location")
	_description_label.text = location_data.get("description", "No description.")

class_name LocationDetailsPanel
extends CustomResizablePanel

@onready var _location_name_label: Label = %TaskNameLabel
@onready var _location_description_label: Label = %TaskDescriptionLabel
@onready var _location_stat_boost_label: Label = %LocationStatBoostLabel # New label for stat boosts

func setup(services: GameSessionServices, config: GameSessionBuilder.Config) -> void:
	pass # No specific setup needed as location manager is not used directly

func update_details(location_data: Dictionary) -> void:
	if not is_node_ready():
		return
	if location_data == null:
		hide()
		return

	show()
	var name_text = location_data.get("name", "Unknown Location")
	_location_name_label.text = "Location Name: " + name_text
	var description_text = location_data.get("description", "No description provided.")
	_location_description_label.text = "Description: " + description_text

	var stat_boosts = location_data.get("stat_boosts", {})
	if stat_boosts is Dictionary and not stat_boosts.is_empty():
		var boost_text = "Stat Boosts:\n"
		for stat_name in stat_boosts.keys():
			boost_text += "  - %s: %s\n" % [stat_name.capitalize(), str(stat_boosts[stat_name])]
		_location_stat_boost_label.text = boost_text
		_location_stat_boost_label.show()
	else:
		_location_stat_boost_label.hide()

	force_fit_content()

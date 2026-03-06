class_name LocationDetailsPanel
extends CustomResizablePanel

const LocalizationStrings := preload(FilePaths.Resources.LOCALIZATION_STRINGS)


@onready var _location_name_label: Label = %LocationNameLabel
@onready var _location_description_label: Label = %LocationDescriptionLabel
@onready var _location_stat_boost_label: Label = %LocationStatBoostLabel
@onready var _task_label: Label = %TaskLabel # New label for tasks

func setup(_state: GameState, _config: GameSessionBuilder.Config) -> void:
	pass # No specific setup needed

var _pending_update = null

func _ready() -> void:
	super._ready()
	if _pending_update:
		update_details(_pending_update)
		_pending_update = null

func update_details(location_data: Variant) -> void:
	if not is_node_ready():
		_pending_update = location_data
		return
	if location_data == null:
		hide()
		return

	show()
	var name_text = location_data.get("name", LocalizationStrings.get_text("hud.location_fallback_name"))
	_location_name_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_LOCATION_NAME_LABEL).format({"name": name_text})
	var description_text = location_data.get("description", "No description provided.") # This might come from data, leave for now unless it's a fixed string
	_location_description_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_LOCATION_DESCRIPTION_LABEL).format({"description": description_text})


	# Task Info
	var task_data = location_data.get("task", {})
	if not task_data.is_empty():
		var task_title = task_data.get("title", LocalizationStrings.get_text("hud.active_unit_summary").split(":")[0]) # Fallback
		if task_title == "": task_title = "Task"
		var current = task_data.get("current_effort", 0)
		var required = task_data.get("effort_required", 0)
		_task_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_LOCATION_TASK_LABEL).format({
			"title": task_title,
			"current": current,
			"required": required
		})

		if location_data.get("can_explore", false):
			_task_label.text += "\n" + LocalizationStrings.get_text(LocalizationStrings.HUD_LOCATION_ACTION_AVAILABLE_EXPLORE)

			_task_label.modulate = Color(0.8, 1.0, 0.8) # Light green
		else:
			_task_label.modulate = Color(1, 1, 1)

		_task_label.show()
	else:
		_task_label.hide()

	var stat_boosts = location_data.get("stat_boosts", {})
	if stat_boosts is Dictionary and not stat_boosts.is_empty():
		var boost_text = LocalizationStrings.get_text(LocalizationStrings.HUD_LOCATION_STAT_BOOSTS) + "\n"
		for stat_name in stat_boosts.keys():
			boost_text += "  - %s: %s\n" % [stat_name.capitalize(), str(stat_boosts[stat_name])]
		_location_stat_boost_label.text = boost_text

		_location_stat_boost_label.show()
	else:
		_location_stat_boost_label.hide()

	force_fit_content()

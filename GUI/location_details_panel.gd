class_name LocationDetailsPanel
extends CustomResizablePanel

const LocalizationStrings := preload(FilePaths.Resources.LOCALIZATION_STRINGS)


@onready var _location_name_label: Label = %LocationNameLabel
@onready var _location_description_label: Label = %LocationDescriptionLabel
@onready var _location_stat_boost_label: Label = %LocationStatBoostLabel
@onready var _task_label: Label = %TaskLabel 

var _back_button: Button
var _pending_update: Variant = null
var _last_location_data: Variant = null

func setup(_state: GameState, _config: GameSessionBuilder.Config) -> void:
	pass 

func _ready() -> void:
	super._ready()
	hide()
	_setup_back_button()
	LocaleService.locale_changed.connect(_on_locale_changed)
	if _pending_update:
		update_details(_pending_update)
		_pending_update = null

func _setup_back_button() -> void:
	_back_button = Button.new()
	_back_button.text = tr("hud.action_back_to_list")
	_back_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_back_button.pressed.connect(_on_back_pressed)
	
	# Match the structure from the .tscn: VBoxContainer is a direct child
	var vbox = get_node_or_null("VBoxContainer")
	if not vbox:
		# Fallback: check if it's inside a MarginContainer
		vbox = get_node_or_null("MarginContainer/VBoxContainer")
	
	if vbox:
		vbox.add_child(_back_button)
		vbox.move_child(_back_button, 0)

func _on_back_pressed() -> void:
	hide()
	# The controller will handle showing the list via signal if needed, 
	# but we can also just emit a signal or call it directly if we have a ref.
	# For simplicity, we'll let the HUDController handle it if we add a signal here.
	if owner and is_instance_valid(owner) and owner.has_method("_on_portrait_tab_pressed"):
		owner._on_portrait_tab_pressed(GameConstants.UI.TAB_LOCATIONS)
	else:
		# Fallback: find HUDController
		var hud = get_viewport().get_node_or_null("HUD")
		if hud and hud.has_method("_on_portrait_tab_pressed"):
			hud._on_portrait_tab_pressed(GameConstants.UI.TAB_LOCATIONS)

func _on_locale_changed() -> void:
	if visible and _last_location_data:
		update_details(_last_location_data)

func update_details(location_data: Variant) -> void:
	if not is_node_ready():
		_pending_update = location_data
		return
	if location_data == null:
		hide()
		_last_location_data = null
		return

	_last_location_data = location_data
	show()
	var name_text = location_data.get("name", LocalizationStrings.get_text("hud.location_fallback_name"))
	_location_name_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_LOCATION_NAME_LABEL).format({"name": name_text})
	var description_text: String = location_data.get("description", tr("hud.location_no_description"))
	_location_description_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_LOCATION_DESCRIPTION_LABEL).format({"description": description_text})


	# Task Info
	var task_data = location_data.get("task", {})
	if not task_data.is_empty():
		var task_title: String = task_data.get("title", tr("hud.active_unit_summary").split(":")[0]) # Fallback
		if task_title == "": task_title = tr("hud.active_task_label")
		var current = task_data.get("current_effort", 0)
		var required = task_data.get("effort_required", 0)
		_task_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_LOCATION_TASK_LABEL).format({
			"title": task_title,
			"current": current,
			"required": required
		})

		if location_data.get("can_explore", false):
			_task_label.text += "\n" + LocalizationStrings.get_text(LocalizationStrings.HUD_LOCATION_ACTION_AVAILABLE_EXPLORE)

			_task_label.modulate = GameColors.TASK_LOCATION_TEXT # Light green
		else:
			_task_label.modulate = GameColors.WHITE

		_task_label.show()
	else:
		_task_label.hide()

	var stat_boosts = location_data.get("stat_boosts", {})
	if stat_boosts is Dictionary and not stat_boosts.is_empty():
		var boost_text = LocalizationStrings.get_text(LocalizationStrings.HUD_LOCATION_STAT_BOOSTS) + "\n"
		for stat_name in stat_boosts.keys():
			var display_name: String = tr("attr." + stat_name.to_lower())
			boost_text += "  - %s: %s\n" % [display_name, str(stat_boosts[stat_name])]
		_location_stat_boost_label.text = boost_text

		_location_stat_boost_label.show()
	else:
		_location_stat_boost_label.hide()

	force_fit_content()

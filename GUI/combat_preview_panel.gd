class_name CombatPreviewPanel
extends CustomResizablePanel

const LocalizationStrings := preload(FilePaths.Resources.LOCALIZATION_STRINGS)

@onready var _vbox: VBoxContainer = %VBoxContainer
@onready var _attacker_label: Label = _vbox.get_node("AttackerLabel")
@onready var _defender_label: Label = _vbox.get_node("DefenderLabel")
@onready var _forecast_label: Label = _vbox.get_node("ForecastLabel")

var _last_attacker: Target
var _last_defender: Target
var _last_forecast: Dictionary

func _ready() -> void:
	super._ready()
	hide()
	LocaleService.locale_changed.connect(_on_locale_changed)
	# Ensure some baseline visibility and styling
	_vbox.add_theme_constant_override("separation", 10)
	
	if DisplaySettings:
		DisplaySettings.display_settings_changed.connect(_on_display_settings_changed)
	
	_update_layout()

func _on_locale_changed() -> void:
	if visible and _last_attacker and _last_defender:
		if _last_forecast.is_empty():
			show_preview(_last_attacker, _last_defender)
		else:
			show_forecast(_last_attacker, _last_defender, _last_forecast)

func show_preview(attacker: Target, defender: Target) -> void:
	if not is_node_ready():
		return

	if _last_attacker == attacker and _last_defender == defender and _forecast_label.text == LocalizationStrings.get_text(LocalizationStrings.HUD_FORECAST_HOVER):
		return


	_last_attacker = attacker
	_last_defender = defender
	_last_forecast = {}

	show()
	_attacker_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_ATTACKER).format({"name": _get_target_name(attacker)})
	_defender_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_DEFENDER).format({"name": _get_target_name(defender)})
	_forecast_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_FORECAST_HOVER)


	_update_panel_layout()

func show_forecast(attacker: Target, defender: Target, forecast: Dictionary) -> void:
	if not is_node_ready(): return

	var is_data_unchanged = _last_attacker == attacker and _last_defender == defender and _last_forecast == forecast
	if is_data_unchanged and visible:
		return


	_last_attacker = attacker
	_last_defender = defender
	_last_forecast = forecast.duplicate()

	show()
	_attacker_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_ATTACKER).format({"name": _get_target_name(attacker)})
	_defender_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_DEFENDER).format({"name": _get_target_name(defender)})

	if forecast.is_empty():
		_forecast_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_NO_FORECAST)
	else:
		var dmg = forecast.get("damage_to_target", 0)
		var self_dmg = forecast.get("counter_damage_to_self", 0)
		_forecast_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_FORECAST_POTENTIAL_DAMAGE).format({"dmg": dmg}) + "\n" + LocalizationStrings.get_text(LocalizationStrings.HUD_FORECAST_COUNTER_DAMAGE).format({"counter": self_dmg})


	_update_panel_layout()

func show_aid_forecast(attacker: Target, defender: Target, pair_names: Array, bonus: int) -> void:
	if not is_node_ready(): return

	show()
	_attacker_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_ATTACKER).format({"name": _get_target_name(attacker)})
	_defender_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_DEFENDER).format({"name": _get_target_name(defender)})

	var stats_text: String = "%s & %s" % [_format_attribute_name(pair_names[0]), _format_attribute_name(pair_names[1])]
	_forecast_label.text = tr("hud.action_aid_bonus").format({"bonus": bonus, "stat": stats_text})

	_update_panel_layout()

func _format_attribute_name(value) -> String:
	var internal_name: String = ""
	if typeof(value) in [TYPE_INT, TYPE_FLOAT]:
		internal_name = GameConstants.get_attribute_name(int(value))
	else:
		internal_name = str(value)
	return tr("attr." + internal_name.to_lower())

func _get_target_name(target: Target) -> String:
	if not target: return LocalizationStrings.get_text(LocalizationStrings.HUD_TARGET_NA)

	if target is Unit:
		var faction_name:  = GameConstants.get_faction_name(int(target.faction))
		return tr("hud.action_format_unit").format({"name": target.unit_name, "faction": faction_name})

	if target is Location:
		return tr("hud.action_format_location").format({"name": target.loc_name})

	if target is Loot:
		return LocalizationStrings.get_text(LocalizationStrings.HUD_TARGET_TRAPPED_LOOT)

	return LocalizationStrings.get_text(LocalizationStrings.HUD_TARGET_GENERIC)


func _update_panel_layout() -> void:
	# Ensure the panel stays within screen bounds and fits content
	force_fit_content()

func _on_display_settings_changed(_orientation: int, _resolution: Vector2i) -> void:
	_update_layout()

func _update_layout() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var is_portrait = viewport_size.y > viewport_size.x
	
	var font_size = 14 if is_portrait and viewport_size.x < 500 else 18
	var small_font_size = 12 if is_portrait and viewport_size.x < 500 else 14
	
	if _attacker_label: _attacker_label.add_theme_font_size_override("font_size", font_size)
	if _defender_label: _defender_label.add_theme_font_size_override("font_size", font_size)
	if _forecast_label: _forecast_label.add_theme_font_size_override("font_size", small_font_size)
	
	if _vbox:
		_vbox.add_theme_constant_override("separation", 5 if is_portrait else 10)

	force_fit_content()

	# Safeguard against extremely long names/text pushing it off screen
	var viewport_width = get_viewport_rect().size.x
	var max_width = viewport_width * 0.45 # Allow up to 45% of screen width

	if size.x > max_width:
		custom_minimum_size.x = max_width
	elif custom_minimum_size.x < min_width:
		custom_minimum_size.x = min_width


func hide_preview() -> void:
	_last_attacker = null
	_last_defender = null
	_last_forecast = {}
	hide()

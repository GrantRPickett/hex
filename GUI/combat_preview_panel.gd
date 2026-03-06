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
	# Ensure some baseline visibility and styling
	_vbox.add_theme_constant_override("separation", 10)

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

func _get_target_name(target: Target) -> String:
	if not target: return LocalizationStrings.get_text(LocalizationStrings.HUD_TARGET_NA)
	if target is Unit:
		return target.unit_name
	if target is Location:
		return target.loc_name
	if target is Loot:
		return LocalizationStrings.get_text(LocalizationStrings.HUD_TARGET_TRAPPED_LOOT)
	return LocalizationStrings.get_text(LocalizationStrings.HUD_TARGET_GENERIC)


func _update_panel_layout() -> void:
	# Ensure the panel stays within screen bounds and fits content
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

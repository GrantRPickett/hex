class_name CombatPreviewPanel
extends CustomResizablePanel

@onready var _vbox: VBoxContainer = %VBoxContainer
@onready var _attacker_label: Label = _vbox.get_node("AttackerLabel")
@onready var _defender_label: Label = _vbox.get_node("DefenderLabel")
@onready var _forecast_label: Label = _vbox.get_node("ForecastLabel")

func show_preview(attacker: Unit, defender: Unit) -> void:
	if not is_node_ready():
		return
	show()
	_attacker_label.text = "Attacker: " + attacker.unit_name if attacker else "N/A"
	_defender_label.text = "Defender: " + defender.unit_name if defender else "N/A"
	_forecast_label.text = "Hover to see forecast"
	force_fit_content()

func show_forecast(attacker: Unit, defender: Unit, forecast: Dictionary) -> void:
	if not is_node_ready(): return
	show()
	_attacker_label.text = "Attacker: " + (attacker.unit_name if attacker else "N/A")
	_defender_label.text = "Defender: " + (defender.unit_name if defender else "N/A")

	if forecast.is_empty():
		_forecast_label.text = "No forecast data"
	else:
		var dmg = forecast.get("damage_to_target", 0)
		var self_dmg = forecast.get("counter_damage_to_self", 0)
		_forecast_label.text = "Deal: %d Dmg\nReceived: %d Dmg" % [dmg, self_dmg]

	force_fit_content()

func hide_preview() -> void:
	hide()

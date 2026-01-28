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
	# TODO: Replace with actual combat forecast calculation
	_forecast_label.text = "Forecast: (Implement Combat Forecast)"
	force_fit_content()

func hide_preview() -> void:
	hide()

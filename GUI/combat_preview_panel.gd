class_name CombatPreviewPanel
extends ResizablePanel

@onready var _attacker_label: Label = %AttackerLabel
@onready var _defender_label: Label = %DefenderLabel
@onready var _forecast_label: Label = %ForecastLabel

func show_preview(attacker: Unit, defender: Unit) -> void:
	show()
	_attacker_label.text = "Attacker: " + attacker.unit_name if attacker else "N/A"
	_defender_label.text = "Defender: " + defender.unit_name if defender else "N/A"
	# TODO: Replace with actual combat forecast calculation
	_forecast_label.text = "Forecast: (Implement Combat Forecast)"

func hide_preview() -> void:
	hide()
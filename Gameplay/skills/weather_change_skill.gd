# Gameplay/WeatherChangeSkill.gd
class_name WeatherChangeSkill extends Skill

@export_enum("shine", "shade", "flow", "grit", "gusto", "focus") var pressure_type: String = GameConstants.Attributes.SHINE

func activate(user: Unit, _target: Variant) -> bool:
	var weather_manager = user.get_node_or_null("/root/WeatherManager")
	if not weather_manager:
		return false

	# Try to start channeling (contested rule)
	if not weather_manager.start_channeling(user):
		if user.get_node_or_null("/root/EventBus"):
			EventBus.emit_event("show_feedback_message", "Weather is already being channeled!")
		return false

	# Add the pressure to the forecast
	weather_manager.add_pressure(pressure_type, true)

	# Consume actions
	user.res.consume_action()
	user.block_movement_this_turn()

	print(user.unit_name, " is channeling ", pressure_type)
	return true

func get_tooltip_text() -> String:
	var base_tooltip = super.get_tooltip_text()
	return base_tooltip + "\n\nChannel [b]" + pressure_type.capitalize() + "[/b] pressure for next round.\n[i]Uses entire action.[/i]"

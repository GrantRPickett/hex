# Gameplay/WeatherChangeSkill.gd
class_name WeatherChangeSkill extends Skill

@export_enum("shine", "shade", "flow", "grit", "gusto", "focus") var pressure_type: String = "shine"

func activate(user: Unit, target: Variant) -> bool:
	if not WeatherManager:
		return false

	# Try to start channeling (contested rule)
	if not WeatherManager.start_channeling(user):
		# TODO: Show message that weather is already being channeled
		return false

	# Add the pressure to the forecast
	WeatherManager.add_pressure(pressure_type, true)

	# Consume actions
	user.consume_action()
	user.block_movement_this_turn()

	print(user.unit_name, " is channeling ", pressure_type)
	return true

func get_tooltip_text() -> String:
	var base_tooltip = super.get_tooltip_text()
	return base_tooltip + "\n\nChannel [b]" + pressure_type.capitalize() + "[/b] pressure for next round.\n[i]Uses entire action.[/i]"

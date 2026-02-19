class_name DefeatEnemiesTask
extends Task

@export var enemies_to_defeat: int = 1

func handle_event(type: String, data: Dictionary) -> void:
	if status != Status.ACTIVE:
		return

	if type == "unit_defeated":
		var unit_defeated_event_data = data.get("unit") as Unit
		if unit_defeated_event_data and unit_defeated_event_data.faction == Unit.Faction.ENEMY:
			current_effort += 1
			progress_changed.emit(current_effort, enemies_to_defeat, -1) # Faction -1 for global progress
			if current_effort >= enemies_to_defeat:
				_complete_task(-1) # Faction -1 for global completion

	# Allow base Task class to handle other events if necessary
	# super.handle_event(type, data)

class_name locationActionProvider
extends RefCounted

func append_location_action(actions: Array[Dictionary], unit: Unit, action_origin: Vector2i) -> void:
	var location := _find_location_at_position(unit, action_origin)
	_add_location_action(actions, location, unit)

func _find_location_at_position(unit: Unit, action_origin: Vector2i) -> Node:
	var task_manager = unit.get_task_manager()
	if not task_manager:
		return null
	var location = task_manager.get_location_at_cell(action_origin)
	if location != null and location.can_be_worked_on_by(unit):
		return location
	return null

func _add_location_action(actions: Array[Dictionary], location: Node, unit: Unit = null) -> void:
	if not location:
		return

	var label = "Work on location"
	var hint = ""

	if unit:
		var task_manager = unit.get_task_manager()
		if task_manager:
			var location_index = task_manager.get_location_node_index(location)
			if location_index != -1:
				var attr_type = task_manager.get_required_type(location_index, unit.faction)
				if not attr_type.is_empty():
					var attrs = unit.get_attributes()
					var val = 0
					if attrs:
						val = attrs.get_attribute(attr_type)

					# Ensure a minimum of 1 contribution
					if val <= 0: val = 1

					label = "Use %s (%d)" % [attr_type.capitalize(), val]
					hint = "Contributes %d points to %s requirement" % [val, attr_type]

	actions.append({
		"type": "work_on_location",
		"label": label,
		"available": true,
		"target": location,
		"hint": hint
	})

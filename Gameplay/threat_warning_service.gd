class_name ThreatWarningService
extends RefCounted

const WARNING_MESSAGE := "Leaving a threatened hex may provoke an attack of opportunity. Press confirm again to accept."
const ACK_MESSAGE := "Attack of opportunity risk! Confirm again to move."

var _pending := false
var _acknowledged := false

func evaluate(unit, origin: Vector2i, unit_manager, terrain_map) -> String:
	var warning_message := ""
	if terrain_map and unit and is_instance_valid(unit_manager):
		if unit.movement_behavior:
			var threatened_hexes = unit.movement_behavior.get_threatened_hexes(unit_manager, terrain_map)
			if threatened_hexes.has(origin):
				warning_message = WARNING_MESSAGE
	_pending = not warning_message.is_empty()
	_acknowledged = false
	return warning_message

func needs_confirmation() -> bool:
	return _pending and not _acknowledged

func acknowledge_warning() -> String:
	_acknowledged = true
	return ACK_MESSAGE if _pending else ""

func reset() -> void:
	_pending = false
	_acknowledged = false

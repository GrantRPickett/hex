class_name ThreatWarningService
extends RefCounted

const WARNING_MESSAGE := "Leaving a threatened hex may provoke an attack of opportunity. Press confirm again to accept."
const ACK_MESSAGE := "Attack of opportunity risk! Confirm again to move."

var _pending : bool = false
var _acknowledged : bool = false

func evaluate(unit, origin: Vector2i, path: Array[Vector2i], unit_manager, terrain_map) -> Dictionary:
	var warning_message := ""
	var threatened_coord := Vector2i()
	if terrain_map and unit and is_instance_valid(unit_manager):
		if unit.movement_behavior:
			var threatened_hexes = unit.movement_behavior.get_threatened_hexes(unit_manager, terrain_map)

			var full_path_to_check = [origin]
			full_path_to_check.append_array(path)

			# We only care about hexes we are *leaving*. The last hex is the destination, we don't leave it during this move.
			for i in range(full_path_to_check.size() - 1):
				if threatened_hexes.has(full_path_to_check[i]):
					warning_message = WARNING_MESSAGE
					threatened_coord = full_path_to_check[i]
					break
	_pending = not warning_message.is_empty()
	_acknowledged = false
	return {"message": warning_message, "coord": threatened_coord}

func needs_confirmation() -> bool:
	return _pending and not _acknowledged

func acknowledge_warning() -> String:
	_acknowledged = true
	return ACK_MESSAGE if _pending else ""

func reset() -> void:
	_pending = false
	_acknowledged = false

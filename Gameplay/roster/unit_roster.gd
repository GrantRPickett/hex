class_name UnitRoster
extends Resource

@export var units: Array[PackedScene] = []

func get_unit_scene(index: int) -> PackedScene:
	if index >= 0 and index < units.size():
		return units[index]
	return null

func get_random_unit_scene() -> PackedScene:
	if units.is_empty():
		return null
	return units.pick_random()

func get_units() -> Array[Unit]:
	var result: Array[Unit] = []
	for scene in units:
		if scene:
			var unit: Node = scene.instantiate()
			if unit is Unit:
				result.append(unit)
			else:
				unit.free()
	return result

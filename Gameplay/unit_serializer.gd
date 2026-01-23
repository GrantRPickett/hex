class_name UnitSerializer
extends RefCounted

static func create_memento(unit: Unit) -> Dictionary:
	var items: Array = []
	var inv = unit.get_inventory()
	if inv:
		items = inv.get_items()

	return {
		"willpower": unit.willpower,
		"max_willpower": unit.max_willpower,
		"movement_points": unit.movement_points,
		"faction": unit.faction,
		"items": items
	}

static func restore_from_memento(unit: Unit, data: Dictionary) -> void:
	unit.max_willpower = data.get("max_willpower", unit.max_willpower)
	unit.willpower = data.get("willpower", unit.willpower)
	unit.movement_points = data.get("movement_points", unit.movement_points)
	unit.faction = data.get("faction", unit.faction)

	var items = data.get("items", [])
	if unit.is_node_ready():
		for item in items:
			unit.equip_item(item)
	else:
		unit.saved_items = items
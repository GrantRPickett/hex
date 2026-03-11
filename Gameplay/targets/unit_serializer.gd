class_name UnitSerializer
extends RefCounted

static func create_memento(unit: Unit) -> Dictionary:
	var items_data: Array = []
	var inv = null
	if unit.inv and unit.inv.has_method("get_inventory"):
		inv = unit.inv.get_inventory()
	if inv:
		for item in inv.get_items():
			items_data.append(item.to_dict())

	return {
		"willpower": unit.willpower,
		"max_willpower": unit.max_willpower,
		"movement_points": unit.movement_points,
		"faction": unit.faction,
		"items": items_data,
		"stress": unit.stress,
		"is_dead": unit.is_dead
	}

static func restore_from_memento(unit: Unit, data: Dictionary) -> void:
	# Avoid triggering unit setter side-effects (like death) during restore
	var new_max_willpower = data.get("max_willpower", unit.max_willpower)
	var new_willpower = data.get("willpower", unit.willpower)
	var new_movement_points = data.get("movement_points", unit.movement_points)

	if unit.res:
		unit.res.set_max_willpower(new_max_willpower)
		unit.res.set_willpower(new_willpower)
	
	unit.movement_points = new_movement_points
	unit.faction = data.get("faction", unit.faction)
	unit.stress = data.get("stress", 0)
	unit.is_dead = data.get("is_dead", false)

	var template = unit.action_points_template
	if template:
		if template.has_method("set_max_willpower"):
			template.set_max_willpower(new_max_willpower)
		if template.has_method("set_willpower"):
			template.set_willpower(new_willpower)
		if template.has_method("set_movement_points"):
			template.set_movement_points(new_movement_points)

	var items_data = data.get("items", [])
	if unit.is_node_ready():
		for item_data in items_data:
			var item = InventoryItem.from_dict(item_data)
			# Need to ensure that the equipped status is set correctly after loading
			if item.equipped:
				unit.inv.equip_item(item)
			else:
				unit.inv.add_item_to_inventory(item)
	else:
		unit.saved_items.clear()
		for item_data in items_data:
			var item = InventoryItem.from_dict(item_data)
			unit.saved_items.append(item)

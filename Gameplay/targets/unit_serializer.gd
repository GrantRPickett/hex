class_name UnitSerializer
extends RefCounted

static func create_memento(unit: Unit) -> Dictionary:
	var items_data: Array[Dictionary] = []
	var inv_ref = null
	if unit.inv and unit.inv.has_method("get_inventory"):
		inv_ref = unit.inv.get_inventory()
	
	if inv_ref:
		for item in inv_ref.get_items():
			if item:
				items_data.append(item.to_dict())
	elif not unit.saved_items.is_empty():
		# Fallback for units not yet initialized in the tree
		for item in unit.saved_items:
			if item:
				items_data.append(item.to_dict())

	print("[UnitSerializer] Created memento for %s with %d items" % [unit.unit_name, items_data.size()])
	
	return {
		"willpower": unit.willpower,
		"base_willpower": unit.base_willpower,
		"grit": unit.grit,
		"flow": unit.flow,
		"gusto": unit.gusto,
		"focus": unit.focus,
		"shine": unit.shine,
		"shade": unit.shade,
		"movement_points": unit.movement_points,
		"faction": unit.faction,
		"items": items_data,
		"stress": unit.stress,
		"is_dead": unit.is_dead
	}

static func restore_from_memento(unit: Unit, data: Dictionary) -> void:
	# Avoid triggering unit setter side-effects (like death) during restore
	var restored_base_wp = data.get("base_willpower", data.get("max_willpower", unit.base_willpower))
	var new_willpower = data.get("willpower", unit.willpower)
	var new_movement_points = data.get("movement_points", unit.movement_points)

	# 1. Restore Base Attributes first
	unit.base_willpower = restored_base_wp
	unit.grit = data.get("grit", unit.grit)
	unit.flow = data.get("flow", unit.flow)
	unit.gusto = data.get("gusto", unit.gusto)
	unit.focus = data.get("focus", unit.focus)
	unit.shine = data.get("shine", unit.shine)
	unit.shade = data.get("shade", unit.shade)

	if unit.res:
		unit.res.set_max_willpower(restored_base_wp) 
	
	unit.movement_points = new_movement_points
	unit.faction = data.get("faction", unit.faction)
	unit.stress = data.get("stress", 0)
	unit.is_dead = data.get("is_dead", false)

	var template = unit.action_points_template
	if template:
		if template.has_method("set_max_willpower"):
			template.set_max_willpower(restored_base_wp)
		if template.has_method("set_movement_points"):
			template.set_movement_points(new_movement_points)

	# 2. Restore Items (which will apply bonuses and update res.max_willpower via signals)
	var items_data: Array = data.get("items", [])
	if unit.inv != null:
		if unit.inv.has_method("clear_items"):
			unit.inv.clear_items()
		elif unit.inv.has_method("clear"):
			unit.inv.clear()
		
		var ready_msg = "[UnitSerializer] Restoring %d items to live unit %s" % [items_data.size(), unit.unit_name]
		print(ready_msg)
		push_warning(ready_msg)
		for item_data: Dictionary in items_data:
			var item = InventoryItem.from_dict(item_data)
			var template_id = item_data.get("template_id", "")
			if not template_id.is_empty():
				item.template = ItemRegistry.get_template(template_id)
			
			if item.equipped:
				unit.inv.equip_item(item)
			else:
				unit.inv.add_item_to_inventory(item)
	else:
		var non_ready_msg = "[UnitSerializer] Restoring %d items to non-initialized unit %s (using saved_items)" % [items_data.size(), unit.unit_name]
		print(non_ready_msg)
		push_warning(non_ready_msg)
		unit.saved_items.clear()
		for item_data: Dictionary in items_data:
			var item = InventoryItem.from_dict(item_data)
			var template_id = item_data.get("template_id", "")
			if not template_id.is_empty():
				item.template = ItemRegistry.get_template(template_id)
			unit.saved_items.append(item)

	# 3. Restore current willpower LAST, after max_willpower has been boosted by items
	if unit.res:
		unit.res.set_willpower(new_willpower)
	if template and template.has_method("set_willpower"):
		template.set_willpower(new_willpower)

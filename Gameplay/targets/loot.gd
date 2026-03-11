class_name Loot
extends Target


@export var inventory: Array[InventoryItem] = []
@export var is_trapped: bool = false

func disarm_trap() -> void:
	is_trapped = false

func can_be_looted_by(unit: Unit, interaction_range: float = 1.5) -> bool:
	var _LootDiscovery = preload("res://Gameplay/targets/discovery/loot_discovery.gd")
	return _LootDiscovery.can_be_looted_by(unit, self, interaction_range)

func add_items(items: Array) -> void:
	for item in items:
		if item is InventoryItem:
			inventory.append(item.duplicate_instance(true))
		elif item is Resource:
			inventory.append(item.duplicate(true))

func is_empty() -> bool:
	return inventory.is_empty()

func get_hover_info() -> String:
	var info_text = "Loot:"
	if inventory.is_empty():
		info_text += "\n(Empty)"
	else:
		for item in inventory:
			info_text += "\n- " + item.item_name
	return info_text

func take_all_items() -> Array[InventoryItem]:
	var taken: Array[InventoryItem] = []
	for item in inventory:
		if item:
			if item.has_method("duplicate_instance"):
				taken.append(item.duplicate_instance(false))
			else:
				var dup = item.duplicate(true)
				if dup:
					taken.append(dup)
	inventory.clear()
	return taken

class_name Loot
extends Target

@export var inventory: Array[InventoryItem] = []

func can_be_looted_by(unit: Unit, interaction_range: float = 0.5) -> bool:
	if not is_instance_valid(unit):
		return false
	# By default, loot can only be picked up if the unit is on the same tile.
	return unit.distance_to_target(self) <= interaction_range

func add_items(items: Array) -> void:
	for item in items:
		if item is InventoryItem:
			inventory.append(item)

func is_empty() -> bool:
	return inventory.is_empty()
class_name UnitInventory
extends Node

const DEFAULT_CAPACITY := 6

signal item_equipped(item)
signal item_unequipped(item)

var slot_capacity: int = DEFAULT_CAPACITY
var _items: Array[InventoryItem] = []

func add_item_to_inventory(item: InventoryItem) -> bool:
	if item == null:
		return false
	if _items.has(item):
		return false
	item.equipped = false
	_items.append(item)
	return true

func remove_item_from_inventory(item: InventoryItem) -> bool:
	if item == null:
		return false
	var idx = _items.find(item)
	if idx == -1:
		return false
	
	if item.equipped:
		unequip_item(item)
		
	_items.remove_at(idx)
	return true

func equip_item(item: InventoryItem) -> bool:
	if item == null:
		return false

	var newly_tracked = false
	if not _items.has(item):
		_items.append(item)
		newly_tracked = true

	if item.equipped and not newly_tracked:
		return true

	if get_equipped_items().size() >= slot_capacity and not item.equipped:
		return false

	item.equipped = true
	item_equipped.emit(item)
	return true

func unequip_item(item: InventoryItem) -> bool:
	if item == null or not _items.has(item) or not item.equipped:
		return false

	item.equipped = false
	item_unequipped.emit(item)
	return true

func clear() -> void:
	for item in get_equipped_items():
		unequip_item(item)
	_items.clear()

func get_items() -> Array[InventoryItem]:
	return _items

func get_equipped_items() -> Array[InventoryItem]:
	var equipped: Array[InventoryItem] = []
	for item in _items:
		if item.equipped:
			equipped.append(item)
	return equipped

func has_item_by_id(origin_id: String) -> bool:
	for item in _items:
		if item and item.origin_id == origin_id:
			return true
	return false

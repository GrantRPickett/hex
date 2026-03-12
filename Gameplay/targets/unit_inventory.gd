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
	
	# Prevent adding items with the same UUID (already in inventory)
	for existing in _items:
		if existing.uuid == item.uuid and not item.uuid.is_empty():
			return false

	# Quest items do not count towards capacity
	if not item.is_quest_item():
		if get_non_quest_items().size() >= slot_capacity:
			return false
		
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
		# Also check for same UUID before adding to track
		var found_by_uuid := false
		for existing in _items:
			if existing.uuid == item.uuid and not item.uuid.is_empty():
				found_by_uuid = true
				break
		if not found_by_uuid:
			if not add_item_to_inventory(item):
				return false
			newly_tracked = true
		else:
			# If already found by UUID, it might be already equipped
			for existing in _items:
				if existing.uuid == item.uuid:
					if not existing.equipped:
						existing.equipped = true
						item_equipped.emit(existing)
						if EventBus: EventBus.item_equipped.emit(get_parent(), existing)
					return true

	if item.equipped and not newly_tracked:
		return true

	# Quest items are always "equipped" in the sense they don't take slots,
	# but we only enforce capacity for non-quest items.
	if not item.is_quest_item():
		if get_equipped_non_quest_items().size() >= slot_capacity:
			return false

	item.equipped = true
	item_equipped.emit(item)
	if EventBus: EventBus.item_equipped.emit(get_parent(), item)
	return true

func unequip_item(item: InventoryItem) -> bool:
	if item == null or not _items.has(item) or not item.equipped:
		return false

	item.equipped = false
	item_unequipped.emit(item)
	if EventBus: EventBus.item_unequipped.emit(get_parent(), item)
	return true

func clear() -> void:
	for item in get_equipped_items():
		unequip_item(item)
	_items.clear()

func get_items() -> Array[InventoryItem]:
	return _items

func get_non_quest_items() -> Array[InventoryItem]:
	var result: Array[InventoryItem] = []
	for item in _items:
		if not item.is_quest_item():
			result.append(item)
	return result

func get_equipped_items() -> Array[InventoryItem]:
	var equipped: Array[InventoryItem] = []
	for item in _items:
		if item.equipped:
			equipped.append(item)
	return equipped

func get_equipped_non_quest_items() -> Array[InventoryItem]:
	var equipped: Array[InventoryItem] = []
	for item in _items:
		if item.equipped and not item.is_quest_item():
			equipped.append(item)
	return equipped

func has_item_by_id(item_id: String) -> bool:
	for item in _items:
		if item and item.template and item.template.item_id == item_id:
			return true
	return false

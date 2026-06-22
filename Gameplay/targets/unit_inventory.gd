class_name UnitInventory
extends Node

const DEFAULT_CAPACITY : int = 6

signal item_equipped(item)
signal item_unequipped(item)
signal item_added(item)
signal item_removed(item)

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

	if not item.is_quest_item():
		if SaveManager and SaveManager.get_difficulty() == GameConstants.Settings.DIFFICULTY_EASY:
			pass # Ignore capacity on Easy
		elif get_non_quest_items().size() >= slot_capacity:
			return false

	_items.append(item)
	item_added.emit(item)
	if EventBus: EventBus.item_added.emit(get_parent(), item)
	return true

func remove_item_from_inventory(item: InventoryItem) -> bool:
	if item == null:
		return false
	var idx: int = _items.find(item)
	if idx == -1:
		return false

	if item.equipped:
		unequip_item(item)

	_items.remove_at(idx)
	item_removed.emit(item)
	if EventBus: EventBus.item_removed.emit(get_parent(), item)
	return true

func equip_item(item: InventoryItem) -> bool:
	if item == null:
		return false

	var was_tracked := _items.has(item)

	if not _ensure_item_tracked(item):
		return false

	if item.equipped:
		# If item was already tracked and already equipped, nothing to do.
		# But if it was just added (e.g. restored from save with equipped=true),
		# we need to emit the signal so modifiers get applied.
		if not was_tracked:
			_perform_equip(item)
		return true

	if not _check_equip_capacity(item):
		return false

	_perform_equip(item)
	return true

func _ensure_item_tracked(item: InventoryItem) -> bool:
	if _items.has(item):
		return true

	# Check for same UUID before adding or treating as already tracked
	for existing in _items:
		if existing.uuid == item.uuid and not item.uuid.is_empty():
			if not existing.equipped:
				existing.equipped = true
				item_equipped.emit(existing)
				if EventBus: EventBus.item_equipped.emit(get_parent(), existing)
			return true # Considered "found and handled"

	return add_item_to_inventory(item)

func _check_equip_capacity(item: InventoryItem) -> bool:
	if item.is_quest_item():
		return true
	if SaveManager and SaveManager.get_difficulty() == GameConstants.Settings.DIFFICULTY_EASY:
		return true # Ignore capacity on Easy
	return get_equipped_non_quest_items().size() < slot_capacity

func _find_by_uuid(uuid: String) -> InventoryItem:
	if uuid.is_empty():
		return null
	for existing in _items:
		if existing.uuid == uuid:
			return existing
	return null

func _equip_existing_item(item: InventoryItem) -> bool:
	if not item.equipped:
		_perform_equip(item)
	return true

func _perform_equip(item: InventoryItem) -> void:
	item.equipped = true
	item_equipped.emit(item)
	if EventBus: EventBus.item_equipped.emit(get_parent(), item)


func unequip_item(item: InventoryItem) -> bool:
	if item == null or not _items.has(item) or not item.equipped:
		return false

	item.equipped = false
	item_unequipped.emit(item)
	if EventBus: EventBus.item_unequipped.emit(get_parent(), item)
	return true

func clear_items() -> void:
	# Unequip everything first to trigger signals/cleanup in components
	var to_unequip = get_equipped_items()
	for item in to_unequip:
		unequip_item(item)

	_items.clear()

func clear() -> void:
	clear_items()

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
		if item == null:
			continue
		if item.template and item.template.item_id == item_id:
			return true
		if item.origin_id == item_id:
			return true
	return false

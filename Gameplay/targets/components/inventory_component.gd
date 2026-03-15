class_name InventoryComponent
extends Resource

@export var inventory_path: NodePath

var _unit: Unit
var _inventory: UnitInventory
var _item_modifier_ids: Dictionary = {}
var _equipped_callable: Callable
var _unequipped_callable: Callable

func setup(unit: Unit) -> void:
	cleanup()
	_unit = unit
	
	_inventory = _find_or_create_inventory(unit)
	if _inventory:
		_equipped_callable = func(item: InventoryItem) -> void:
			if item == null: return
			var id := str(item.get_instance_id())
			_item_modifier_ids[item] = id
			if _unit.has_method("apply_attribute_modifier"):
				_unit.apply_attribute_modifier(id, item.get_modifiers())
		_inventory.item_equipped.connect(_equipped_callable)
		_unequipped_callable = func(item: InventoryItem) -> void:
			if item == null: return
			if not _item_modifier_ids.has(item): return
			var id: String = _item_modifier_ids[item]
			if _unit.has_method("remove_attribute_modifier"):
				_unit.remove_attribute_modifier(id)
			_item_modifier_ids.erase(item)
		_inventory.item_unequipped.connect(_unequipped_callable)

		# Apply modifiers for already-equipped items
		for item in _inventory.get_equipped_items():
			_equipped_callable.call(item)

func _find_or_create_inventory(unit: Unit) -> UnitInventory:
	if unit:
		var node: UnitInventory = null
		if not inventory_path.is_empty():
			node = unit.get_node_or_null(inventory_path) as UnitInventory
		if node == null:
			node = unit.get_node_or_null("UnitInventory") as UnitInventory
		if node:
			return node
		var created := UnitInventory.new()
		created.name = "UnitInventory"
		unit.add_child(created)
		return created
	return UnitInventory.new()

func cleanup() -> void:
	if _inventory:
		if _equipped_callable and _inventory.item_equipped.is_connected(_equipped_callable):
			_inventory.item_equipped.disconnect(_equipped_callable)
		if _unequipped_callable and _inventory.item_unequipped.is_connected(_unequipped_callable):
			_inventory.item_unequipped.disconnect(_unequipped_callable)
	_equipped_callable = Callable()
	_unequipped_callable = Callable()
	_item_modifier_ids.clear()
	_unit = null
	_inventory = null

func get_inventory() -> UnitInventory:
	return _inventory

func equip_item(item: InventoryItem) -> bool:
	if _inventory == null:
		return false
	return _inventory.equip_item(item)

func unequip_item(item: InventoryItem) -> bool:
	if _inventory == null:
		return false
	return _inventory.unequip_item(item)

func add_item_to_inventory(item: InventoryItem) -> bool:
	if _inventory == null:
		return false
	return _inventory.add_item_to_inventory(item)

func remove_item_from_inventory(item: InventoryItem) -> bool:
	if _inventory == null:
		return false
	return _inventory.remove_item_from_inventory(item)

func get_equipped_items() -> Array[InventoryItem]:
	if _inventory == null:
		return []
	return _inventory.get_equipped_items()

func has_item_by_id(origin_id: String) -> bool:
	if _inventory == null:
		return false
	return _inventory.has_item_by_id(origin_id)

func clear_items() -> void:
	if _inventory:
		_inventory.clear_items()

func clear() -> void:
	if _inventory:
		_inventory.clear()

class_name InventoryItem
extends Resource

## Instance-specific data for an item in the game world.
## Refereces an ItemTemplate for static data.

@export var template: ItemTemplate
@export var uuid: String = ""
@export var equipped: bool = false
@export var origin_id: String = ""

func _init() -> void:
	if uuid.is_empty():
		uuid = _generate_uuid()

## Returns the name from the template.
func get_item_name() -> String:
	return template.item_name if template else "Unknown Item"

## Returns modifiers from the template.
func get_modifiers() -> Dictionary:
	return template.attribute_modifiers if template else {}

## Returns true if the item is a quest item according to its template.
func is_quest_item() -> bool:
	return template.quest_item if template else false

func _generate_uuid() -> String:
	var chars: String = "0123456789abcdef"
	var uuid_str: String = ""
	for i in range(32):
		if i == 8 or i == 12 or i == 16 or i == 20:
			uuid_str += "-"
		uuid_str += chars[randi() % 16]
	return uuid_str

func to_dict() -> Dictionary:
	return {
		"template_id": template.item_id if template else "",
		"equipped": equipped,
		"uuid": uuid,
		"origin_id": origin_id,
	}

static func from_dict(data: Dictionary) -> InventoryItem:
	var item: InventoryItem = InventoryItem.new()
	
	# Note: Template restoration is handled by callers (e.g., UnitSerializer, ItemRegistry) 
	# since static methods cannot reliably access Autoloads in all contexts.
	
	item.equipped = data.get("equipped", false)
	item.uuid = data.get("uuid", item._generate_uuid())
	item.origin_id = data.get("origin_id", "")
	
	return item

func duplicate_instance(regenerate_uuid: bool = false) -> InventoryItem:
	var old_uuid = uuid
	var copy: InventoryItem = duplicate(true) as InventoryItem
	if regenerate_uuid:
		copy.uuid = _generate_uuid()
	else:
		copy.uuid = old_uuid
	return copy

class_name InventoryItem
extends Resource

@export var item_name: String = ""
@export var attribute_modifiers: Dictionary = {}
@export var equipped: bool = false
@export var uuid: String = ""
@export var origin_id: String = ""
@export var quest: bool = false # Quest items don't consume unit inventory; route to player stash

func _init() -> void:
	if uuid.is_empty():
		uuid = _generate_uuid()

func _generate_uuid() -> String:
	var chars = "0123456789abcdef"
	var uuid_str = ""
	for i in range(32):
		if i == 8 or i == 12 or i == 16 or i == 20:
			uuid_str += "-"
		uuid_str += chars[randi() % 16]
	return uuid_str

# New method to convert InventoryItem to Dictionary for serialization
func to_dict() -> Dictionary:
	return {
		"item_name": item_name,
		"attribute_modifiers": attribute_modifiers,
		"equipped": equipped,
		"uuid": uuid,
		"origin_id": origin_id,
		"quest": quest,
	}

# Static method to create InventoryItem from Dictionary for deserialization
static func from_dict(data: Dictionary) -> InventoryItem:
	var item = InventoryItem.new()
	item.item_name = data.get("item_name", "")
	item.attribute_modifiers = data.get("attribute_modifiers", {})
	item.equipped = data.get("equipped", false)
	item.uuid = data.get("uuid", "")
	item.origin_id = data.get("origin_id", "")
	item.quest = data.get("quest", false)
	return item

func duplicate_instance(regenerate_uuid: bool = false) -> InventoryItem:
	var copy: InventoryItem = duplicate(true) as InventoryItem
	if copy == null:
		copy = InventoryItem.new()
		copy.item_name = item_name
		copy.attribute_modifiers = attribute_modifiers.duplicate(true)
		copy.equipped = equipped
		copy.uuid = uuid
		copy.origin_id = origin_id
		copy.quest = quest
	if regenerate_uuid:
		copy.uuid = copy._generate_uuid()
	return copy

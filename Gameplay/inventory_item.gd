class_name InventoryItem
extends Resource

@export var item_name: String = ""
@export var attribute_modifiers: Dictionary = {}
@export var uuid: String = ""
@export var origin_id: String = ""

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

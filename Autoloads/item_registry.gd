extends Node

const ITEMS_DIR = "res://Resources/items/"

var _templates: Dictionary = {}

func _ready() -> void:
	_load_templates()

func _load_templates() -> void:
	var dir: DirAccess = DirAccess.open(ITEMS_DIR)
	if not dir:
		push_error("ItemRegistry: Could not open items directory: %s" % ITEMS_DIR)
		return
	
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res: Resource = load(ITEMS_DIR + file_name)
			if res is ItemTemplate:
				if res.item_id.is_empty():
					push_warning("ItemRegistry: Template at %s has empty item_id" % file_name)
					continue
				_templates[res.item_id] = res
		file_name = dir.get_next()
	
	print("ItemRegistry: Loaded %d templates" % _templates.size())

func get_template(item_id: String) -> ItemTemplate:
	if _templates.is_empty():
		_load_templates()
	return _templates.get(item_id)

func get_all_templates() -> Array[ItemTemplate]:
	if _templates.is_empty():
		_load_templates()
	var result: Array[ItemTemplate] = []
	result.assign(_templates.values())
	return result

func create_instance(item_id: String) -> InventoryItem:
	var template = get_template(item_id)
	if not template:
		push_error("ItemRegistry: Template not found: %s" % item_id)
		return null
	
	var instance: InventoryItem = InventoryItem.new()
	instance.template = template
	instance.uuid = instance.generate_uuid()
	# Auto-equip if not a quest item
	instance.equipped = not template.quest_item
	return instance



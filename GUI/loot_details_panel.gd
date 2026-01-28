class_name LootDetailsPanel
extends CustomResizablePanel

@onready var _vbox: VBoxContainer = %VBoxContainer
@onready var _name_label: Label = %NameLabel

func _init() -> void:
	name = "LootDetailsPanel"

func _ready() -> void:
	pass

func update_details(loot: Loot) -> void:
	if not is_node_ready():
		return

	if loot == null:
		visible = false
		return

	visible = true

	if _name_label:
		var item_list = []
		for item in loot.inventory:
			item_list.append("- " + item.item_name)

		if item_list.is_empty():
			_name_label.text = "Loot: (Empty)"
		else:
			_name_label.text = "Loot:\n" + "\n".join(item_list)

	force_fit_content()

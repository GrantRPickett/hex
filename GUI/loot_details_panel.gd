class_name LootDetailsPanel
extends CustomResizablePanel

@onready var _vbox: VBoxContainer = %VBoxContainer
@onready var _name_label: Label = %NameLabel

func _init() -> void:
	name = "LootDetailsPanel"

func _ready() -> void:
	pass

func update_details(loot: Loot) -> void:
	if loot == null:
		visible = false
		return

	visible = true

	if _name_label:
		_name_label.text = "Loot: " + str(loot.inventory.size()) + " items"

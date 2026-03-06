class_name LootDetailsPanel
extends CustomResizablePanel

const LocalizationStrings := preload(FilePaths.Resources.LOCALIZATION_STRINGS)

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
			_name_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_LOOT_EMPTY)
		else:
			_name_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_LOOT_LABEL) + "\n" + "\n".join(item_list)


	force_fit_content()

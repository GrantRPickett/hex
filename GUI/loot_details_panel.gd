class_name LootDetailsPanel
extends CustomResizablePanel

const LocalizationStrings := preload(FilePaths.Resources.LOCALIZATION_STRINGS)

@onready var _name_label: Label = %NameLabel


func _init() -> void:
	name = "LootDetailsPanel"

func _ready() -> void:
	hide()
	
	if DisplaySettings:
		DisplaySettings.display_settings_changed.connect(_on_display_settings_changed)
	
	_update_layout()

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
			item_list.append("- " + item.get_item_name())

		if item_list.is_empty():
			_name_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_LOOT_EMPTY)
		else:
			_name_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_LOOT_LABEL) + "\n" + "\n".join(item_list)


	force_fit_content()

func _on_display_settings_changed(_orientation: int, _resolution: Vector2i) -> void:
	_update_layout()

func _update_layout() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var is_portrait = viewport_size.y > viewport_size.x
	
	var font_size = 14 if is_portrait and viewport_size.x < 500 else 18
	
	if _name_label:
		_name_label.add_theme_font_size_override("font_size", font_size)

	force_fit_content()

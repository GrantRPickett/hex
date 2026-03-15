class_name LocationsListPanel
extends CustomResizablePanel

signal location_selected(location_data: Dictionary)

@onready var _vbox: VBoxContainer = %locationsVBox

var _location_display_item_scene: PackedScene = preload(FilePaths.Scenes.LOCATION_DISPLAY_ITEM)

func _init() -> void:
	name = "LocationsListPanel"

func _ready() -> void:
	super._ready()
	hide()
	
	if DisplaySettings:
		DisplaySettings.display_settings_changed.connect(_on_display_settings_changed)
	
	_update_layout()

func update_locations(locations_data: Array) -> void:
	if not is_node_ready():
		return
	for child in _vbox.get_children():
		child.queue_free()

	if locations_data.is_empty():
		hide()
		return

	show()
	for location_data in locations_data:
		var location_item_instance: Node = _location_display_item_scene.instantiate()
		_vbox.add_child(location_item_instance)
		location_item_instance.call_deferred("set_location_data", location_data)
		location_item_instance.selected.connect(func(data): location_selected.emit(data))

func _on_display_settings_changed(_orientation: int, _resolution: Vector2i) -> void:
	_update_layout()

func _update_layout() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var is_portrait = viewport_size.y > viewport_size.x
	
	# Compact spacing in portrait
	if _vbox:
		_vbox.add_theme_constant_override("separation", 2 if is_portrait else 5)
	
	force_fit_content()

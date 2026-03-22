class_name LocationsListPanel
extends CustomResizablePanel

signal location_selected(location_data: Dictionary)

@onready var _vbox: VBoxContainer = %locationsVBox
@onready var _show_more_button: Button = %ShowMoreButton

var _location_display_item_scene: PackedScene = preload(FilePaths.Scenes.LOCATION_DISPLAY_ITEM)
var _is_expanded: bool = false
var _full_locations_data: Array = []

func _init() -> void:
	name = "LocationsListPanel"

func _ready() -> void:
	super._ready()
	hide()
	
	if DisplaySettings:
		DisplaySettings.display_settings_changed.connect(_on_display_settings_changed)
	
	if _show_more_button:
		_show_more_button.pressed.connect(_on_show_more_pressed)
	
	_update_layout()

func update_locations(locations_data: Array) -> void:
	if not is_node_ready():
		return
	
	_full_locations_data = locations_data
	_update_display()

func _update_display() -> void:
	for child in _vbox.get_children():
		child.queue_free()

	if _full_locations_data.is_empty():
		hide()
		return

	show()
	
	var display_data = _full_locations_data
	var needs_show_more = _full_locations_data.size() > 3
	
	if needs_show_more and not _is_expanded:
		display_data = _full_locations_data.slice(0, 3)
	
	for location_data in display_data:
		var location_item_instance: Node = _location_display_item_scene.instantiate()
		_vbox.add_child(location_item_instance)
		location_item_instance.call_deferred("set_location_data", location_data)
		location_item_instance.selected.connect(func(data): location_selected.emit(data))
	
	if _show_more_button:
		_show_more_button.visible = needs_show_more
		_show_more_button.text = tr("hud.action_show_less") if _is_expanded else tr("hud.action_show_more").format({"count": _full_locations_data.size()})
	
	force_fit_content()

func _on_show_more_pressed() -> void:
	_is_expanded = !_is_expanded
	_update_display()

func _on_display_settings_changed(_orientation: int, _resolution: Vector2i) -> void:
	_update_layout()

func _update_layout() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var is_portrait = viewport_size.y > viewport_size.x
	
	# Compact spacing in portrait
	if _vbox:
		_vbox.add_theme_constant_override("separation", 2 if is_portrait else 5)
	
	force_fit_content()

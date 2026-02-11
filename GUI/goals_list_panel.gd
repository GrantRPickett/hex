class_name locationsListPanel
extends CustomResizablePanel

@onready var _vbox: VBoxContainer = %locationsVBox

var _location_display_item_scene: PackedScene = preload("res://GUI/location_display_item.tscn")

func _init() -> void:
	name = "locationsListPanel"

func update_locations(locations_data: Array) -> void:
	if not is_node_ready():
		return
	for child in _vbox.get_children():
		child.queue_free()

	if locations_data.is_empty():
		return

	for location_data in locations_data:
		var location_item_instance = _location_display_item_scene.instantiate()
		_vbox.add_child(location_item_instance)
		location_item_instance.call_deferred("set_location_data", location_data)

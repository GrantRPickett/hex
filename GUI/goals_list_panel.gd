class_name GoalsListPanel
extends CustomResizablePanel

@onready var _vbox: VBoxContainer = %GoalsVBox

var _goal_display_item_scene: PackedScene = preload("res://GUI/goal_display_item.tscn")

func _init() -> void:
	name = "GoalsListPanel"

func update_goals(goals_data: Array) -> void:
	if not is_node_ready():
		return
	for child in _vbox.get_children():
		child.queue_free()

	if goals_data.is_empty():
		return

	for goal_data in goals_data:
		var goal_item_instance = _goal_display_item_scene.instantiate()
		_vbox.add_child(goal_item_instance)
		goal_item_instance.call_deferred("set_goal_data", goal_data)

class_name GoalsListPanel
extends ResizablePanel

@onready var _title_label: Label = %TitleLabel
@onready var _vbox: VBoxContainer = %GoalsVBox

func _init() -> void:
	name = "GoalsListPanel"

func update_goals(goals_data: Array) -> void:
	for child in _vbox.get_children():
		child.queue_free()

	if goals_data.is_empty():
		return

	for goal_data in goals_data:
		var progress_text = "%s: %d/%d" % [goal_data.type, goal_data.player_progress, goal_data.max]
		var goal_label = Label.new()
		goal_label.text = progress_text
		_vbox.add_child(goal_label)
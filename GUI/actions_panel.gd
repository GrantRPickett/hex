class_name ActionsPanel
extends CustomResizablePanel

signal action_selected(action: Dictionary)

const LocalizationStrings := preload("res://Resources/Localization/localization_strings.gd")
const BUTTON_MIN_SIZE := Vector2(160, 30)
const HINT_TEXT_COLOR := Color(1, 1, 0.8)

@onready var actions_container: VBoxContainer = %ActionsContainer
@onready var hint_label: Label = %HintLabel

func _ready() -> void:
	hint_label.text = LocalizationStrings.get_text("hud.actions_hint")
	hint_label.visible = false
	hint_label.modulate = Color(1, 1, 1, 0)
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_label.add_theme_color_override("font_color", HINT_TEXT_COLOR)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_label.custom_minimum_size = Vector2(0, 18)


func update_actions(unit: Unit, terrain_map, unit_manager: UnitManager) -> void:
	if not is_instance_valid(actions_container):
		return

	for child in actions_container.get_children():
		if child == hint_label:
			continue
		child.queue_free()

	if not is_instance_valid(unit):
		visible = false
		if is_instance_valid(hint_label):
			hint_label.visible = false
		return

	var available_actions = UnitActionManager.get_available_actions(unit, terrain_map, unit_manager)

	if available_actions.is_empty():
		visible = false
		if is_instance_valid(hint_label):
			hint_label.visible = false
		return

	var was_hidden := not visible
	visible = true
	if was_hidden:
		var t := create_tween()
		t.tween_property(self, "modulate", Color(1, 1, 0.7, 1), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	_show_actions_hint()

	for action in available_actions:
		var btn := Button.new()
		btn.text = action.label
		btn.custom_minimum_size = BUTTON_MIN_SIZE
		btn.disabled = not action.available
		if action.has("hint"):
			btn.tooltip_text = str(action.hint)
		btn.pressed.connect(func(): action_selected.emit(action))
		actions_container.add_child(btn)

func _show_actions_hint() -> void:
	if not is_instance_valid(hint_label):
		return

	hint_label.visible = true
	hint_label.modulate = Color(1, 1, 1, 1)